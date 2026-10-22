//
//  NavigationTabView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/15/24.
//

import SwiftUI

enum AppTab: Hashable {
    case today, learn, ask, saved
}

/// Lets any screen switch tabs, e.g. a suggestion chip on Today opening Ask.
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .today
}

struct NavigationTabView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router = AppRouter()
    @StateObject private var chatSession = ChatSession()
    let saveAction: () -> Void

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab("Today", systemImage: "sun.horizon", value: .today) {
                NavigationStack { HomeView() }
            }

            Tab("Learn", systemImage: "book.pages", value: .learn) {
                NavigationStack { EducationView() }
            }

            Tab("Ask", systemImage: "bubble.left.and.text.bubble.right", value: .ask) {
                NavigationStack { ChatView() }
            }

            Tab("Saved", systemImage: "heart", value: .saved) {
                NavigationStack { FavoritesView() }
            }
        }
        .modifier(TabBarMinimizeOnScroll())
        .environmentObject(router)
        .environmentObject(chatSession)
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive { saveAction() }
        }
    }
}

private struct TabBarMinimizeOnScroll: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    NavigationTabView(saveAction: {})
        .environmentObject(UserStore())
        .environmentObject(FavoritesManager())
}
