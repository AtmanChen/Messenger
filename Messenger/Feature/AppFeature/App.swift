//
//  MessengerApp.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import SwiftUI
import ComposableArchitecture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    @Dependency(\.firebaseAuth) var firebaseAuth
    func windowScene(
      _ windowScene: UIWindowScene,
      performActionFor shortcutItem: UIApplicationShortcutItem,
      completionHandler: @escaping (Bool) -> Void
    ) {
      AppDelegate.shared.store.send(.sceneDelegate(.shortcutItem(shortcutItem)))
      completionHandler(true)
    }

    func scene(
      _ scene: UIScene,
      openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
      for context in URLContexts {
        let url = context.url
        _ = firebaseAuth.canHandle(url)
      }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    static let shared = AppDelegate()
    private override init() {}
    let store = Store(
        initialState: AppLogic.State(),
        reducer: {
            AppLogic()
                ._printChanges()
        }
    )
    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      store.send(.appDelegate(.didFinishLaunching))
      return true
    }
}

@main
struct MessengerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            AppView(store: appDelegate.store)
        }
    }
}
