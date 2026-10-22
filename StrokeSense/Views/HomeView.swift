//
//  HomeView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 10/20/24.
//

import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @EnvironmentObject var store: UserStore
    @State private var currentScreen = "HomeView"
    @State private var scrollOffset: CGFloat = 0
    private let threshold: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                GeometryReader { geo in
                                   Color.clear
                                       .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                               }
                               .frame(height: 0)
                WhatToKnowView()
                    .padding(.top)
                    .padding(.bottom, -10)
                FeaturedView()
                    .padding(.top, -10)
                Spacer()
                ResourcesPanelView()
                Spacer()
                NewsPanelView()
                Spacer()
            }
            .padding(.top)
            
            
            Rectangle()
                .fill(.white)
                .frame(height: 100)
                .ignoresSafeArea(edges: .top)
        }
        
    }
}

#Preview {
    HomeView()
        .environmentObject(UserStore())
        .environmentObject(FavoritesManager())
}
