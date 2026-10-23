//
//  InterviewsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//
import SwiftUI

/// All videos, opened from "See All" on Today or from Learn.
struct InterviewsView: View {
    @ObservedObject var viewModel: VideoViewModel
    @State private var playingVideo: Video?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xl) {
                ForEach(viewModel.videos) { video in
                    VideoCard(video: video) { playingVideo = video }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .overlay {
            if viewModel.videos.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView("No episodes yet", systemImage: "headphones", description: Text("Pull down to check again."))
                }
            }
        }
        .background(.surface)
        .navigationTitle("Podcast Episodes")
        .refreshable { viewModel.fetchVideos(force: true) }
        .onAppear { viewModel.fetchVideos() }
        .sheet(item: $playingVideo) { VideoPlayerSheet(video: $0) }
    }
}

#Preview {
    NavigationStack {
        InterviewsView(viewModel: VideoViewModel())
    }
    .environmentObject(FavoritesManager())
}
