//
//  NewsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//

import SwiftUI

struct NewsView: View {
    @ObservedObject var viewModel: NewsViewModel

    var body: some View {
        ArticleListView(title: "News", articles: viewModel.newsArticles) {
            viewModel.fetchArticles(force: true)
        }
        .onAppear { viewModel.fetchArticles() }
    }
}

struct ResourcesView: View {
    @ObservedObject var viewModel: NewsViewModel

    var body: some View {
        ArticleListView(title: "Resources", articles: viewModel.staticArticles) {
            viewModel.fetchArticles(force: true)
        }
        .onAppear { viewModel.fetchArticles() }
    }
}

/// Article list that opens each link in an in-app Safari sheet.
private struct ArticleListView: View {
    /// Translation key.
    let title: String
    let articles: [NewsArticle]
    let onRefresh: () -> Void
    @State private var openArticle: URL?

    var body: some View {
        List(articles) { article in
            Button {
                openArticle = URL(string: article.url)
            } label: {
                ArticleRow(article: article)
                    .padding(.vertical, Spacing.xxs)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.surface)
        .overlay {
            if articles.isEmpty {
                ProgressView()
            }
        }
        .localizedNavigationTitle(title)
        .refreshable { onRefresh() }
        .safariSheet(url: $openArticle)
    }
}

#Preview {
    NavigationStack {
        NewsView(viewModel: NewsViewModel())
    }
}
