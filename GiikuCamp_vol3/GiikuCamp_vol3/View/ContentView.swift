//
//  ContentView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/16.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var cloudViewModel = CloudViewModel()
    
    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                NavigationView {
                    if !cloudViewModel.data.isAgree {
                        TermsAgreementView(onAgree: { cloudViewModel.data.isAgree = true })
                    } else {
                        SignInOptionsView()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            Home()
        }
        .onChange(of: authViewModel.isAuthenticated) { newValue in
            print("[ContentView] authViewModel.isAuthenticated changed to: \(newValue)")
        }
        .onAppear {
            // 既存の有効なユーザーがいるか厳密に確認
            print("[ContentView] Checking authentication state...")
            
            // 一旦すべての認証状態をリセット（テスト用）
            authViewModel.isAuthenticated = false
            
            // AuthViewModelのメソッドを使って確認
            if let appUser = authViewModel.getCurrentUser() {
                print("[ContentView] Found existing user: \(appUser.uid)")
                
                // 追加検証：Firebaseに再確認（オプション）
                Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true) { tokenResult, error in
                    if let error = error {
                        print("[ContentView] Token verification failed: \(error.localizedDescription)")
                        // トークン検証に失敗したらログイン状態はfalseのまま
                    } else if let tokenResult = tokenResult {
                        print("[ContentView] Token verified, expiration: \(tokenResult.expirationDate)")
                        // トークンが有効なら認証済みとする
                        DispatchQueue.main.async {
                            authViewModel.user = appUser
                            authViewModel.isAuthenticated = true
                        }
                    }
                }
            } else {
                print("[ContentView] No existing user found")
            }
        }
    }
}

#Preview {
    ContentView()
}
