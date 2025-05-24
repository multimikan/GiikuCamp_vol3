//
//  Untitled.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/24.
//

import SwiftUI

struct GradientIconView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#0066ff"), location: 0.0),
                .init(color: Color(hex: "#0066ff"), location: 0.4), // 青を70%まで
                .init(color: Color(hex: "#ffff00"), location: 1.0)  // 残りが黄
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Image(systemName: "books.vertical")
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
        .frame(width: 100, height: 100)
    }
}




#Preview {
    GradientIconView()
}
