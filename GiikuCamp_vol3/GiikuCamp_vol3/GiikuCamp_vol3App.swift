//
//  FirebaseCloudMessagingPracticeApp.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/17.
//


import SwiftUI
import FirebaseCore

@main
struct FirebaseCloudMessagingPracticeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

