//
//  FeatureGridItem.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/8/24.
//

import SwiftUI

struct FeatureGridItem: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    var featuredNavigationItem: FeaturedNavigation
    
    var body: some View {
        NavigationLink {
            featuredNavigationItem.destination
                .environmentObject(store)
                .environmentObject(favoritesManager)
                .navigationTitle(featuredNavigationItem.title != "Quiz" && featuredNavigationItem.title != "AI Stroke Expert" ? featuredNavigationItem.title : "")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarBackButtonHidden(featuredNavigationItem.title == "Quiz" || featuredNavigationItem.title == "AI Stroke Expert" ? true : false)
        } label: {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottom) {
                    switch featuredNavigationItem.title {
                        case "Education":
                            Image(systemName: "info.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(.bottom, 25)
                        case "Podcasts":
                            Image(systemName: "microphone")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(.bottom, 25)
                        case "AI Stroke Expert":
                            Image(systemName: "cpu")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(.bottom, 25)
                        case "Quiz":
                            Image(systemName: "gamecontroller")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(.bottom, 25)
                                
                        default:
                            Image(systemName: "info.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                                .padding(.bottom, 25)
                    }
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 175 , height: 125)
                        .foregroundStyle(Color(hue: 0.569, saturation: 0.703, brightness: 1.0, opacity: 0.673))
                        .opacity(0.4)
                }
                    Text(featuredNavigationItem.title)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.black)
                        .font(.headline)
                        .padding()
                   
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeatureGridItem(featuredNavigationItem: FeaturedNavigation(destination: AnyView(EducationView()), title: "Learn from professionals"))
            .environmentObject(UserStore())
            .environmentObject(FavoritesManager())
    }
}
