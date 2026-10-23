//
//  NewsViewModel.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/27/24.
//
import SwiftUI
import OSLog
import SwiftSoup

class NewsViewModel: ObservableObject {
    @Published var newsArticles: [NewsArticle] = []
    @Published var staticArticles: [NewsArticle] = []
    
    private var hasLoaded = false

    /// Recent stroke news from credible research-news feeds, gathered and cached by the
    /// StrokeSense Worker (worker/src/news.js). It refreshes on its own, so no list to maintain.
    private static let newsURL = URL(string: "https://strokesense-chat.ims03g.workers.dev/news")!
    
    private let staticURLs = [
        "https://apnews.com/article/stroke-risk-death-nutrition-exercise-ozempic-mounjaro-5fee3375b627377b6a39565ce2a647c5",
        "https://www.nhlbi.nih.gov/health/stroke/causes",
        "https://www.hopkinsmedicine.org/health/conditions-and-diseases/stroke",
        "https://www.health.harvard.edu/womens-health/8-things-you-can-do-to-prevent-a-stroke",
        "https://en.wikipedia.org/wiki/Stroke",
        "https://www.health.com/strokes-rising-young-adults-cdc-8659643"
    ]
    
    /// Loads once; pass `force` to reload (pull to refresh).
    func fetchArticles(force: Bool = false) {
        guard force || !hasLoaded else { return }
        hasLoaded = true
        fetchStaticArticles()
        fetchNewsArticles()
    }
    
    private func fetchStaticArticles() {
        loadArticles(from: staticURLs) { self.staticArticles = $0 }
    }
    
    private func fetchNewsArticles() {
        Task { @MainActor in
            do {
                let (data, _) = try await URLSession.shared.data(from: Self.newsURL)
                let feed = try JSONDecoder().decode(NewsFeed.self, from: data)
                newsArticles = feed.articles.map {
                    NewsArticle(title: $0.title, description: $0.description, url: $0.url, imageURL: $0.imageURL, source: $0.source)
                }
            } catch {
                Logger.app.error("Couldn't load news: \(error.localizedDescription)")
            }
        }
    }

    private struct NewsFeed: Decodable {
        struct Item: Decodable {
            let title: String
            let url: String
            let source: String
            let description: String
            let imageURL: String
        }
        let articles: [Item]
    }
    
    /// "Stroke | Johns Hopkins Medicine" -> "Stroke". The source is shown separately.
    private static func cleanTitle(_ title: String) -> String {
        var parts = title.components(separatedBy: " | ")
        if parts.count > 1 { parts.removeLast() }
        return parts.joined(separator: " | ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Fetches page metadata for each URL and delivers the articles in the original URL order.
    private func loadArticles(from urls: [String], completion: @escaping ([NewsArticle]) -> Void) {
        var results: [Int: NewsArticle] = [:]
        let group = DispatchGroup()
        let lock = NSLock()
        
        for (index, urlString) in urls.enumerated() {
            guard let url = URL(string: urlString) else { continue }
            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, error in
                defer { group.leave() }
                guard let data = data, error == nil, let html = String(data: data, encoding: .utf8) else { return }
                do {
                    let document = try SwiftSoup.parse(html)
                    let title = Self.cleanTitle(try document.title())
                    guard !title.isEmpty, !title.localizedCaseInsensitiveContains("not found") else { return }
                    let description = try document.select("meta[name=description]").first()?.attr("content").truncate(to: 100) ?? ""
                    let imageURL = try document.select("meta[property=og:image]").first()?.attr("content") ?? ""
                    let article = NewsArticle(title: title, description: description, url: urlString, imageURL: imageURL)
                    lock.lock()
                    results[index] = article
                    lock.unlock()
                } catch {
                    Logger.app.error("Couldn't read article page: \(error.localizedDescription)")
                }
            }.resume()
        }
        
        group.notify(queue: .main) {
            completion(results.keys.sorted().compactMap { results[$0] })
        }
    }
}

extension String {
    func truncate(to length: Int, addEllipsis: Bool = true) -> String {
        if self.count > length {
            let truncated = self.prefix(length)
            return addEllipsis ? "\(truncated)..." : String(truncated)
        } else {
            return self
        }
    }
}
