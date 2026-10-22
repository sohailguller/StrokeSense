//
//  NewsPanelView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/8/24.
//
import SwiftUI

struct NewsPanelView: View {
    @StateObject private var viewModel = NewsViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                Text("News")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)

                Spacer()

                NavigationLink("See more", destination: NewsView()
                    .navigationTitle("News")
                    .navigationBarTitleDisplayMode(.large))
                    .font(.callout)
                    .foregroundColor(.blue)
                    .padding(.trailing)
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.newsArticles.prefix(3), id: \.id) { article in
                        NewsArticleGridItem(article: article)
                           // .frame(width: 200, height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.fetchArticles()
        }
    }
}

#Preview {
    NavigationStack {
        NewsPanelView()
            .environmentObject(NewsViewModel())
    }
}
