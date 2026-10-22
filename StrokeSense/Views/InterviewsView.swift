//
//  InterviewsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//
import SwiftUI

struct InterviewsView: View {
    @StateObject var videoVM = VideoViewModel()
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(videoVM.videos, id: \.videoID) { video in
                    VStack(alignment: .leading, spacing: 12) {
                        YouTubeView(videoID: video.videoID)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .cornerRadius(12)
                            .padding(.top)
                        
                        HStack(alignment: .top) {
                            Text(video.name)
                                .font(.headline)
                                .frame(maxWidth: 300, alignment: .leading)
                            
                            Spacer()
                            
                            Button(action: {
                                if favoritesManager.favorites[video.videoID] != nil {
                                    favoritesManager.removeFavorite(sound: video.videoID)
                                } else {
                                    favoritesManager.addFavorite(sound: video.videoID, episode: video.name)
                                }
                            }) {
                                Image(systemName: favoritesManager.favorites[video.videoID] != nil ? "heart.fill" : "heart")
                                    .foregroundColor(favoritesManager.favorites[video.videoID] != nil ? .red : .gray)
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
            .padding(.vertical)
        }
        .onAppear {
            print("View appeared")
            videoVM.fetchVideos()
        }
    }
}

#Preview {
    InterviewsView()
        .environmentObject(FavoritesManager())
        .environmentObject(UserStore())
}
