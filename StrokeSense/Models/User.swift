//
//  User.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//
import UIKit

class User: ObservableObject, Codable {
    var id: String = UUID().uuidString
    var profilePicture: UIImage
    var username: String = ""
    var favorites: [Video] = []
    
    static let `default` = User(id: "0000", profilePicture: UIImage(systemName: "person.crop.circle.fill") ?? UIImage(), username: "", favorites: [])
    
    init(id: String, profilePicture: UIImage, username: String, favorites: [Video]) {
        self.id = id
        self.profilePicture = profilePicture
        self.username = username
        self.favorites = favorites
    }
    
    enum CodingKeys: String, CodingKey {
        case id, profilePicture, username, favorites
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        favorites = try container.decode([Video].self, forKey: .favorites)

        // Earlier builds saved the placeholder symbol as a small image and "user" as the name.
        if username == "user" { username = "" }
        if let imageData = try? container.decode(Data.self, forKey: .profilePicture),
           let image = UIImage(data: imageData), image.size.width * image.scale >= 100 {
            profilePicture = image
        } else {
            profilePicture = UIImage(systemName: "person.crop.circle.fill") ?? UIImage()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(favorites, forKey: .favorites)

        // The default placeholder is an SF Symbol; only real photos are stored.
        if !profilePicture.isSymbolImage, let imageData = profilePicture.jpegData(compressionQuality: 0.85) {
            try container.encode(imageData, forKey: .profilePicture)
        }
    }
}
