//
//  Infographic.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import Foundation

class Infographic {
    var url: String
    var source: String
    var uploadDate: Date
    
    init(url: String, source: String, uploadDate: Date) {
        self.url = url
        self.source = source
        self.uploadDate = uploadDate
    }
}
