//
//  ArticleSummary.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import Foundation

struct ArticleSummary: Identifiable, Codable {
    var id: UUID = UUID()
    var headline: String
    var summary: String
    // var newsSource: String
    var url: String
    var image: String

    enum CodingKeys: String, CodingKey {
        case headline = "Headline"
        case summary = "Summary"
        // case newsSource = "News Source"
        case url = "URL"
        case image = "Image"
    }
}
