//
//  NewsArticleGridItem.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/8/24.
//
import SwiftUI

struct NewsArticleGridItem: View {
    let article: NewsArticle

    var body: some View {
        Button {
            if let url = URL(string: article.url) {
                UIApplication.shared.open(url)
            }
        } label: {
            // 1. Image fills a fixed-size frame
            AsyncImage(url: URL(string: article.imageURL)) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                default:
                    Color.gray
                }
            }
            .frame(width: 200, height: 120)
            .clipped()
            
            // 2. Gradient overlay pinned to bottom
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.7),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 60)
            }
            
            // 3. Text overlay pinned bottom-leading
            .overlay(alignment: .bottomLeading) {
                Text(article.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            
            // 4. Round and shadow
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 5)
        }
    }
}


#Preview {
    NewsArticleGridItem(article: NewsArticle(title: "The Rest of the Group", description: "Hi", url: "www.youtube.com", imageURL: "www.youtube.com"))
    .environmentObject(UserStore())
}
