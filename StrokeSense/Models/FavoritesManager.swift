//
//  FavoritesManager.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/23/25.
//
import Foundation

class FavoritesManager: ObservableObject {
    @Published var favorites: [String: String] = [:]

    init() {
        loadFavorites()
    }

    func addFavorite(sound: String, episode: String) {
        favorites[sound] = episode
        saveFavorites()
    }

    func removeFavorite(sound: String) {
        favorites.removeValue(forKey: sound)
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
