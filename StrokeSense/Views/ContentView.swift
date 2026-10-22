//
//  ContentView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var user: User
    @State private var searchText = ""
    var body: some View {
        VStack(alignment: .leading) {
            HeaderView()
                .padding(.bottom)
            
            /*
            ZStack {
                TextField("Search", text: $searchText)
                    .padding()
                    .frame(width: 350, height: 50)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")

                }
                .padding()
            }
            */
        }
        .padding()
    }
}

#Preview {
    ContentView(user: .constant(User.default))
        .environmentObject(UserStore())
}
