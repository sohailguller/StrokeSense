//
//  Interview.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import Foundation

class Interview {
    var id: String
    var titile: String
    var description: String
    var transcript: String
    var interviewee: String
    var uploadDate: Date
    
    init(id: String, titile: String, description: String, transcript: String, interviewee: String, uploadDate: Date) {
        self.id = id
        self.titile = titile
        self.description = description
        self.transcript = transcript
        self.interviewee = interviewee
        self.uploadDate = uploadDate
    }
}
