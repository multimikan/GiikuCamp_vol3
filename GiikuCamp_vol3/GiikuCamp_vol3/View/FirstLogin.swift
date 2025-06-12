//
//  Start.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/06/12.
//

import SwiftUI

struct FirstLogin: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TermsAgreementView {
                withAnimation {
                    selectedTab = 1
                }
            }
            .tag(0)

            SignInOptionsView()
                .environmentObject(AuthViewModel())
                .tag(1)
        }
        .edgesIgnoringSafeArea(.all)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // めくりアニメーションにする
        .gesture(DragGesture()) // ← これでスワイプ無効
    }
}


#Preview {
    FirstLogin()
}
