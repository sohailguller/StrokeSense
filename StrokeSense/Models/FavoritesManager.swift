//
//  FavoritesManager.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/23/25.
//
import Foundation

/// Saved videos, keyed by YouTube video ID with the video title as the value.
class FavoritesManager: ObservableObject {
    @Published var favorites: [String: String] = [:]

    init() {
        loadFavorites()
    }

    /// Saved videos, sorted by title.
    var savedVideos: [Video] {
        favorites
            .map { Video(name: $0.value, videoID: $0.key) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func isFavorite(_ videoID: String) -> Bool {
        favorites[videoID] != nil
    }

    func toggle(videoID: String, title: String) {
        if isFavorite(videoID) {
            removeFavorite(videoID: videoID)
        } else {
            addFavorite(videoID: videoID, title: title)
        }
    }

    func addFavorite(videoID: String, title: String) {
        favorites[videoID] = title
        saveFavorites()
    }

    func removeFavorite(videoID: String) {
        favorites.removeValue(forKey: videoID)
        saveFavorites()
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.data(forKey: "favorites"),
           let decodedFavorites = try? JSONDecoder().decode([String: String].self, from: savedFavorites) {
            favorites = decodedFavorites
        }
    }
}
