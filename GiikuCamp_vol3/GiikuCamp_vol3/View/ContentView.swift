//
//  ContentView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/16.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ChatView()
                
                // ナビゲーションバーにプロフィールボタンを追加
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: ProfileView(authViewModel: authViewModel)) {
                            if let photoURL = authViewModel.user?.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                }
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("GiikuCamp")
        }
        .onAppear {
            // 既存のユーザー情報を取得
            if let currentUser = authViewModel.getCurrentUser() {
                authViewModel.user = currentUser
                authViewModel.isAuthenticated = true
            }
        }
    }
}

#Preview {
    ContentView()
}
