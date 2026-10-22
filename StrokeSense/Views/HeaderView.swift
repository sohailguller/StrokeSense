//
//  HeaderView.swift
//  TrivIndia
//
//  Created by Sohail Guller on 7/20/24.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var store: UserStore
    
    var body: some View {
        HStack {
            if store.user.profilePicture == UIImage(systemName: "person.crop.circle.fill") {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing)
                    .foregroundStyle(.gray)
            } else {
                Image(uiImage: store.user.profilePicture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing)
            }
            
            Text("Hello, \(store.user.username)👋")
                .fontWeight(.semibold)
                .font(.title)
            Spacer()
           
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
}


#Preview {
    HeaderView()
        .environmentObject(UserStore())
}
