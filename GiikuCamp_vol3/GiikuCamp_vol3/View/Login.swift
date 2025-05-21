//
//  Login.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct LoginSelectionView: View {
    @State private var showSignInOptions = false

    var body: some View {
        VStack(spacing: 30) {
            Text("アプリ名")
                .font(.largeTitle)
                .bold()

            Button(action: {
                showSignInOptions = true
            }) {
                Text("ログイン")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .fullScreenCover(isPresented: $showSignInOptions) {
            SignInOptionsView()
        }
    }
}

#Preview {
    LoginSelectionView()
}
