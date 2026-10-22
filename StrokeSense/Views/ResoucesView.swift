//
//  ResoucesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/22/25.
//

import SwiftUI

struct ResoucesView: View {
    @StateObject var viewModel = NewsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.staticArticles) { article in
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

#Preview {
    ResoucesView()
        .environmentObject(UserStore())
}
