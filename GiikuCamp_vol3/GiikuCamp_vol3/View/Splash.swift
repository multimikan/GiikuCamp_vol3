//
//  Splash.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/21.
//

import SwiftUI

struct SplashView: View {
    // このView自体に画面遷移ロジックは持たせない想定。
    // ContentViewなどが表示状態を管理し、一定時間後や初期化完了後にメインコンテンツに切り替える。

    var body: some View {
        VStack(spacing: 16) {
            // TODO: "AppLogo" を実際のロゴ画像アセット名に置き換えてください
            Image("AppLogoPlaceholder") // 仮のプレースホルダー名
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            // TODO: "アプリ名" を実際のアプリ名に置き換えてください
            Text("実際のアプリ名")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // 背景色。AppColors があればそちらを使用検討
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}

