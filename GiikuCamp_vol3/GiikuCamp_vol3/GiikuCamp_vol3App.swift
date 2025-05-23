//
//  GiikuCamp_vol3App.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/17.
//


import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

@main
struct GiikuCamp_vol3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SampleCameraView()
                .onOpenURL { url in
                    // Google Sign-Inのリダイレクト処理
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Google Sign-In用のURLスキーム処理
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

