//
//  WhaToKnowView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 3/22/25.
//

import SwiftUI

struct WhatToKnowView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    let questions = [
        "What is a stroke?",
        "What are the symptoms of stroke?",
        "How can I prevent a stroke?"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: -10) {
            Text("What you need to know")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: 10) {
                    ForEach(questions, id: \.self) { question in
                        NavigationLink(destination:
                            ChatView()
                                .environmentObject(store)
                                .environmentObject(favoritesManager)
                                .navigationBarBackButtonHidden()
                                       
                        ) {
                            Text(question)
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    NavigationStack {
        WhatToKnowView()
            .environmentObject(UserStore())
            .environmentObject(FavoritesManager())
    }
    
}
