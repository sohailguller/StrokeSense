//
//  NavigationTabView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/15/24.
//

import SwiftUI

struct NavigationTabView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.scenePhase) private var scenePhase
    let saveAction: ()->Void
    var body: some View {
        TabView {
            Tab("", systemImage: "house") {
                HomeView()
                    .environmentObject(store)

            }
            
            Tab("", systemImage: "heart") {
                FavoritesView()
                    .navigationTitle("Favorites")
                    .environmentObject(favoritesManager)
                
            }
            
            Tab("", systemImage: "brain.head.profile") {
                ChatView()
                    .environmentObject(store)

            }
            
            Tab("", systemImage: "person.crop.circle") {
                ProfileView()
                    .environmentObject(store)

            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: scenePhase) { phase, _ in
            if phase == .inactive { saveAction() }
        }
    }
}


#Preview {
    NavigationStack {
        NavigationTabView(saveAction: {})
            .environmentObject(UserStore())
            .environmentObject(FavoritesManager())
    }
}
