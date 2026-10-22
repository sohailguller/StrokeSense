//
//  NewsArticle.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/27/24.
//

import Foundation

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let url: String
    let imageURL: String
}


