//
//  ResourcesViewModel.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/22/25.
//
/*
import SwiftUI
import SwiftSoup


// Original code. Use with internet access.
class ResourcesViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []

    func fetchArticles() {
        let urls = [
            "https://apnews.com/article/stroke-risk-death-nutrition-exercise-ozempic-mounjaro-5fee3375b627377b6a39565ce2a647c5",
            "https://www.nhlbi.nih.gov/health/stroke/causes",
            "https://www.hopkinsmedicine.org/health/conditions-and-diseases/stroke",
            "https://www.health.harvard.edu/womens-health/8-things-you-can-do-to-prevent-a-stroke",
            "https://costroke.org/stroke-prevention/",
            "https://en.wikipedia.org/wiki/Stroke",
            "https://www.health.com/strokes-rising-young-adults-cdc-8659643"
        ]

        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }

            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }

                if let html = String(data: data, encoding: .utf8) {
                    do {
                        let document = try SwiftSoup.parse(html)

                        let title = try document.title()
                        let description = try document.select("meta[name=description]").first()?.attr("content").truncate(to: 100) ?? "No description available"
                        let imageURL = try document.select("meta[property=og:image]").first()?.attr("content") ?? ""

                        let article = NewsArticle(
                            title: title,
                            description: description,
                            url: urlString,
                            imageURL: imageURL
                        )

                        DispatchQueue.main.async {
                            self.articles.append(article)
                        }
                    } catch {
                        print("Failed to parse HTML: \(error)")
                    }
                }
            }.resume()
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
*/
/*
 //Designed for offline use
class ResourcesViewModel: ObservableObject {
    @Published var articles: [ArticleSummary] = []

    init() {
        let articles: [ArticleSummary] = load("StaticArticles")
        self.articles = articles
    }
}
*/
