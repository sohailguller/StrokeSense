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
    /// Publication name, e.g. "ScienceDaily". When nil, the web address is shown instead.
    var source: String? = nil
}


