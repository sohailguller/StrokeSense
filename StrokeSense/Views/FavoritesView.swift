//
//  FavoritesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/1/24.
//

import SwiftUI

/// The Saved tab.
struct FavoritesView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var playingVideo: Video?

    var body: some View {
        List {
            ForEach(favoritesManager.savedVideos) { video in
                Button {
                    playingVideo = video
                } label: {
                    SavedVideoRow(video: video)
                }
                .buttonStyle(.plain)
                .contextMenu { VideoContextActions(video: video) }
                .swipeActions {
                    Button("Remove", systemImage: "heart.slash", role: .destructive) {
                        withAnimation { favoritesManager.removeFavorite(videoID: video.videoID) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.surface)
        .overlay {
            if favoritesManager.favorites.isEmpty {
                ContentUnavailableView(
                    "No saved episodes",
                    systemImage: "heart",
                    description: Text("Tap the heart on any episode to keep it here.")
                )
            }
        }
        .localizedNavigationTitle("Saved")
        .sheet(item: $playingVideo) { VideoPlayerSheet(video: $0) }
    }
}

private struct SavedVideoRow: View {
    let video: Video
    @ScaledMetric(relativeTo: .body) private var thumbWidth: CGFloat = 112

    var body: some View {
        HStack(spacing: Spacing.m) {
            VideoThumbnail(videoID: video.videoID, radius: Radius.control, showsPlayGlyph: false)
                .frame(width: thumbWidth)
            Text(video.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.ink)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Plays the episode")
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environmentObject(FavoritesManager())
}
