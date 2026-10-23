//
//  NavigationTabView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 9/15/24.
//

import SwiftUI

enum AppTab: Hashable {
    case home, learn, ask, saved
}

/// Lets any screen switch tabs, e.g. a suggestion chip on Today opening Ask.
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    /// Set to open Ask with the keyboard up.
    @Published var focusChatInput = false
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
            Tab("Home", systemImage: "house", value: .home) {
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
        .sheet(isPresented: Binding(
            get: { chatSession.pendingQuestion != nil },
            set: { if !$0 { chatSession.declineConsent() } }
        )) {
            AIConsentSheet()
                .environmentObject(chatSession)
        }
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
