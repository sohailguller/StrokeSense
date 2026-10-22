//
//  NewsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//

import SwiftUI
import SwiftSoup

 // For use with interent connection
struct NewsView: View {
    @StateObject var viewModel = NewsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.newsArticles) { article in
                Button(action: {
                    if let url = URL(string: article.url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text(article.title)
                            .font(.headline)
                        Text(article.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                viewModel.fetchArticles()
            }
        }
    }
}


// For use without internet connection
/*
struct NewsView: View {
    @StateObject var viewModel = NewsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.articles) { article in
                NavigationLink(destination: SummaryView(article: article)
                    .navigationTitle("Summary")
                    .navigationBarTitleDisplayMode(.large)
                ) {
                    VStack(alignment: .leading) {
                        Text(article.headline)
                            .font(.headline)
                        Text(article.summary)
                            .lineLimit(3)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

*/


#Preview {
    NewsView()
}
