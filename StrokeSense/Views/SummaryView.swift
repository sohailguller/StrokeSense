//
//  SummaryView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/22/25.
//
import SwiftUI

struct SummaryView: View {
    let article: ArticleSummary

    var body: some View {
        VStack(alignment: .leading) {
            Text(article.headline)
                .font(.title2)
                .bold()
                .padding()
                .padding(.bottom, -20)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            ScrollView {
                Text(article.summary)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }

    }
}

#Preview {
    SummaryView(article: ArticleSummary(
        headline: "Sample Headline",
        summary: "Sample summary of the article.",
        url: "https://example.com",
        image: "sample_image"
    ))
}

