//
//  FavoritesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/1/24.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if favoritesManager.favorites.isEmpty {
                    Text("Liked podcasts will show up here")
                        .padding()
                } else {
                    ForEach(favoritesManager.favorites.keys.sorted(), id: \.self) { videoID in
                        if let name = favoritesManager.favorites[videoID] {
                            VStack(alignment: .leading, spacing: 12) {
                                YouTubeView(videoID: videoID)
                                    .aspectRatio(16 / 9, contentMode: .fit)
                                    .cornerRadius(12)
                                    .padding(.top)
                                
                                HStack(alignment: .top) {
                                    Text(name)
                                        .font(.headline)
                                        .frame(maxWidth: 300, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        favoritesManager.removeFavorite(sound: videoID)
                                    }) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Favorites")
        
        Text("All podcasts are created by the developer(s) of this app. They contain info and recommendations based on online research. There can be mistakes. Check important info. Seek a doctor's advice in addition to using this app and before making any medical decisions.")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding()
            .multilineTextAlignment(.center)
    }
}


#Preview {
    FavoritesView()
        .environmentObject(FavoritesManager())
}
