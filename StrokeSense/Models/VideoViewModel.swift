//
//  VideoViewModel.swift
//  StrokeSense
//
//  Created by Sohail Guller on 6/10/25.
//
import SwiftUI
import FirebaseFirestore

struct Video: Codable, Hashable, Identifiable {
    let name: String
    let videoID: String

    var id: String { videoID }
}

class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    private var hasLoaded = false
    
    private var db = Firestore.firestore()
    
    /// Loads once; pass `force` to reload (pull to refresh).
    func fetchVideos(force: Bool = false) {
        guard force || !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        db.collection("videos").getDocuments { querySnapshot, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let error = error {
                print("Error getting videos: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else { return }
            
            // Replace rather than append so revisiting the screen doesn't duplicate videos.
            let fetched = documents.compactMap { document -> Video? in
                do {
                    return try document.data(as: Video.self)
                } catch {
                    print("Error decoding video \(document.documentID): \(error)")
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                self.videos = fetched
            }
        }
    }
}
