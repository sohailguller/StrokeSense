//
//  FeaturedView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 8/11/24.
//

import SwiftUI

struct FeaturedView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var featured: [FeaturedNavigation] {
        [
            FeaturedNavigation(destination: AnyView(EducationView()), title: "Infographics"),
            FeaturedNavigation(destination: AnyView(ChatView()), title: "AI Stroke Expert"),
            FeaturedNavigation(destination: AnyView(InterviewsView()), title: "Podcasts"),
            FeaturedNavigation(destination: AnyView(GameView()), title: "Quiz")
        ]
    }
    
    let columnLayout = Array(repeating: GridItem(), count: 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: -10) {
            Text("Explore")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            LazyVGrid(columns: columnLayout, content: {
                ForEach(featured, id: \.id) { feature in
                    FeatureGridItem(featuredNavigationItem: feature)
                        .environmentObject(store)
                        .environmentObject(favoritesManager)
                }
            })
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeaturedView()
        .environmentObject(UserStore())
        .environmentObject(FavoritesManager())
}
