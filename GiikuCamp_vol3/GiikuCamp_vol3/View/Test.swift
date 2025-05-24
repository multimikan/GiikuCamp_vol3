//
//  Test.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/24.
//

import SwiftUI

// TODO: このViewがテスト用か実用か確認。実用ならファイル名変更と適切な配置を検討。
struct GradientIconView: View {
    // TODO: systemName や size を外部から指定できるように引数を追加検討
    let systemName: String = "books.vertical"
    let iconSize: CGFloat = 100
    // グラデーションの色も外部から指定可能にするとより汎用的
    let startColor: Color = Color(hex: "#0066ff")
    let midColor: Color = Color(hex: "#0066ff")
    let endColor: Color = Color(hex: "#ffff00")
    let midColorLocation: CGFloat = 0.4 // 0.0 から 1.0 の間

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: startColor, location: 0.0),
                .init(color: midColor, location: midColorLocation),
                .init(color: endColor, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
        .frame(width: iconSize, height: iconSize)
    }
}

#Preview {
    GradientIconView()
}
