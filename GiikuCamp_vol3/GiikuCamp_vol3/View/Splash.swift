//
//  Start.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/21.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            // ロゴ画像（Assetsに "AppLogo" という名前で画像を追加しておいてください）
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            // アプリ名
            Text("教景（きょうけい）")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // 背景色
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}

