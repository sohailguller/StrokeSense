//
//  NewsViewModel.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/27/24.
//
import SwiftUI
import SwiftSoup
import FirebaseFirestore

class NewsViewModel: ObservableObject {
    @Published var newsArticles: [NewsArticle] = []
    @Published var staticArticles: [NewsArticle] = []
    
    private var db = Firestore.firestore()
    private var hasLoaded = false
    
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
        db.collection("urls").getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            let urls = querySnapshot?.documents.compactMap { $0.data()["url"] as? String } ?? []
            self.loadArticles(from: urls) { self.newsArticles = $0 }
        }
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
                    print("Failed to parse HTML: \(error)")
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

/*
 // Hardcoded for offline use
 import Foundation
 
 class NewsViewModel: ObservableObject {
 @Published var articles: [ArticleSummary] = []
 
 init() {
 let articles: [ArticleSummary] = load("NewsSummaries")
 self.articles = articles
 }
 }
 */
