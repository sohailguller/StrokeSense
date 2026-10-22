//
//  VideoView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//
import SwiftUI

struct VideoView: View {
    @EnvironmentObject var store: UserStore
    let videoName: String
    let videoID: String
    
    var body: some View {
        VStack(alignment: .leading) {
            YouTubeView(videoID: videoID)
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .padding()
            
            HStack {
                Text(videoName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                Spacer()
            }
            .frame(width: 350)
            
        }
    }
}

#Preview {
    VideoView(videoName: "What is a Stroke? (HealthSketch)", videoID: "dQw4w9WgXcQ")
        .environmentObject(UserStore())
}
