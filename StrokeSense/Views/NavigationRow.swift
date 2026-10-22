//
//  NavigationRow.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//

import SwiftUI

struct NavigationRow<Destination: View>: View {
    var destination: Destination
    var category: String
    var imageName: String
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 350, height: 125)
                    .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 0.247))
                
                HStack {
                    Text(category)
                        .font(.title)
                        .foregroundStyle(.black)
                        .bold()
                    Spacer()
                    Image(systemName: imageName)
                        .font(.title)
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    NavigationRow(destination: HomeView(), category: "Home", imageName: "house")
}
