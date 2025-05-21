//
//  SignUp.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct SignInOptionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 14) {
            Text("サインイン方法を選択")
                .font(.title2)
                .padding()

            SignInButton(label: "Appleでサインイン", systemImage: "applelogo", backgroundColor: .black)
            SignInButton(label: "Googleでサインイン", systemImage: "globe", backgroundColor: .red)
            SignInButton(label: "Yahoo! JAPAN IDでサインイン", systemImage: "person.circle", backgroundColor: .purple)

            Button("キャンセル") {
                dismiss()
            }
            .foregroundColor(.gray)
            .padding(.top, 40)
        }
        .padding()
    }
}

struct SignInButton: View {
    var label: String
    var systemImage: String
    var backgroundColor: Color

    var body: some View {
        Button(action: {
            // サインイン処理をここに記述
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
    }

