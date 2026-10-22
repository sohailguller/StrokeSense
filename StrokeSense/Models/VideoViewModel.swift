//
//  VideoViewModel.swift
//  StrokeSense
//
//  Created by Sohail Guller on 6/10/25.
//
import SwiftUI
import FirebaseFirestore

struct Video: Codable {
    let name: String
    let videoID: String
}

class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    
    private var db = Firestore.firestore()
    
    func fetchVideos() {
        db.collection("videos").getDocuments { querySnapshot, error in
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
