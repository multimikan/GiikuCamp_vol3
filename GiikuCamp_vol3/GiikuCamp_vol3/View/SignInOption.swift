//
//  SignInOption.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct SignInOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FFFF00").opacity(0.2),
                    Color(hex: "#0066FF").opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea() // 全画面に拡張
            
            VStack(spacing: 14) {
                Text("サインイン方法を選択")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                
                SignInButton(label: "Appleでサインイン", systemImage: "applelogo", backgroundColor: .black, closure: {
                    // Task { await viewModel.signInWithApple() }
                })
                SignInButton(label: "Googleでサインイン", systemImage: "globe", backgroundColor: .red, closure:{
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                })
                SignInButton(label: "Yahoo! JAPAN IDでサインイン", systemImage: "person.circle", backgroundColor: .purple, closure: {
                    // Task { await viewModel.signInWithYahoo() }
                })
                
                Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .padding(.top, 40)
            }
            .padding()
            
            // ローディングインジケーター
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
}

struct SignInButton: View {
    var label: String
    var systemImage: String
    var backgroundColor: Color
    var closure:() -> Void = {}

    var body: some View {
        Button(action: {
            closure()
        }) {
            HStack {
                Image(systemName: systemImage)
                Text(label)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

#Preview {
    SignInOptionsView()
        .environmentObject(AuthViewModel())
}

