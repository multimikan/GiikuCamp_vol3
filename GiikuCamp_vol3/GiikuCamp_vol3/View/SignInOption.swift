//
//  SignUp.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct SignInOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // メインのUI（前面）
            VStack(spacing: 16) {
                Spacer()
                HStack{
                Text("Chamelearnを\nはじめましょう")
                    .font(.largeTitle)
                    .bold()
                }
                .padding(.top)
                
                Image("baby")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180)
                
                Spacer()
                
                SignInButton(
                    label: "Googleでサインイン",
                    systemImage: "googleLogo"
                ) {
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                }

                Button("ゲストとして続行する") {
                    dismiss()
                }
                .foregroundColor(Color(uiColor: .black))
                .padding(4)
            }
            .frame(maxWidth: 380)
            .padding()
            
            // ローディングインジケーター（最前面）
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
    var closure: () -> Void = {}
    let radius: CGFloat = 32

    var body: some View {
        Button(action: {
            closure()
        }) {
            HStack {
                Image(systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(.leading, 8)

                Spacer()

                Text(label)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Spacer()
            }
            .padding()
            .frame(height: 56)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .cornerRadius(radius)
        }
        .padding(.horizontal)
    }
}


#Preview {
        SignInOptionsView()
        .environmentObject(AuthViewModel())
    }

