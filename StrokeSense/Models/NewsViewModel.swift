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

    func fetchArticles() {
        fetchStaticArticles()
        fetchNewsArticles()
    }

    private func fetchStaticArticles() {
        let staticURLS = [
            "https://apnews.com/article/stroke-risk-death-nutrition-exercise-ozempic-mounjaro-5fee3375b627377b6a39565ce2a647c5",
            "https://www.nhlbi.nih.gov/health/stroke/causes",
            "https://www.hopkinsmedicine.org/health/conditions-and-diseases/stroke",
            "https://www.health.harvard.edu/womens-health/8-things-you-can-do-to-prevent-a-stroke",
            "https://en.wikipedia.org/wiki/Stroke",
            "https://www.health.com/strokes-rising-young-adults-cdc-8659643"
        ]

        for urlString in staticURLS {
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
                            self.staticArticles.append(article)
                        }
                    } catch {
                        print("Failed to parse HTML: \(error)")
                    }
                }
            }.resume()
        }
    }

    private func fetchNewsArticles() {
        db.collection("urls").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }

            for document in querySnapshot!.documents {
                if let urlString = document.data()["url"] as? String, let url = URL(string: urlString) {
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
                                    self.newsArticles.append(article)
                                }
                            } catch {
                                print("Failed to parse HTML: \(error)")
                            }
                        }
                    }.resume()
                }
            }
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
