//
//  StrokeSenseApp.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import SwiftUI
import OSLog
import FirebaseCore
import FirebaseAppCheck

extension Logger {
    /// App-wide log. Messages show in Xcode and Console.app, and stay out of release output.
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StrokeSense", category: "app")
}

/// Proves to Firebase that requests (e.g. to the Stroke Expert chat Worker) come from the real app.
class StrokeSenseAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    AppAttestProvider(app: app)
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    #if DEBUG
    // Simulators can't use App Attest. The debug token is printed to the Xcode console on
    // first launch and must be registered in Firebase Console > App Check > Manage debug tokens.
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #else
    AppCheck.setAppCheckProviderFactory(StrokeSenseAppCheckProviderFactory())
    #endif
    FirebaseApp.configure()

    return true
  }
}

@main
struct StrokeSenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var store = UserStore()
    @StateObject private var favoritesManager = FavoritesManager()
    /// Light unless the user picks Automatic or Dark in Profile.
    @AppStorage("appearance") private var appearance = AppAppearance.light

    var body: some Scene {
        WindowGroup {
            NavigationTabView {
                Task {
                    do {
                        try await store.save(user: store.user)
                    } catch {
                        Logger.app.error("Couldn't save profile: \(error.localizedDescription)")
                    }
                }
            }
            // One type family across the app: SF Pro Rounded (see DesignSystem/Theme.swift).
            .fontDesign(.rounded)
            .preferredColorScheme(appearance.colorScheme)
            .environmentObject(store)
            .environmentObject(favoritesManager)
            .task {
                do {
                    try await store.load()
                } catch {
                    Logger.app.error("Couldn't load profile: \(error.localizedDescription)")
                }
            }
        }
    }
}
