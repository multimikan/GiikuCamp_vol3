//
//  ContentView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/16.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cloudViewModel = CloudViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var shouldShowTutorialOnNextHomeLoad = false

    var body: some View {
        Group {
            if !cloudViewModel.data.isAgree {
                TermsAgreementView {
                    cloudViewModel.data.isAgree = true
                    Task {
                        await cloudViewModel.saveData()
                    }
                    shouldShowTutorialOnNextHomeLoad = true
                }
            } else if !authViewModel.isAuthenticated {
                SignInOptionsView()
                    .environmentObject(authViewModel)
                    .environmentObject(cloudViewModel)
            } else {
                Home()
                    .environmentObject(authViewModel)
                    .environmentObject(cloudViewModel)
                    .environmentObject(chatViewModel)
                    .overlay {
                        if shouldShowTutorialOnNextHomeLoad {
                            TutorialView {
                                shouldShowTutorialOnNextHomeLoad = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            Task {
                await cloudViewModel.fetchCloud()
            }
        }
    }
}

#Preview {
    ContentView()
}
