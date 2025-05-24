import SwiftUI

struct BubbleAnimationView: View {
    @State private var isAnimating = false
    @State private var rotationDegrees: Double = 0
    let color: Color // この色はオブジェクト特有の色として使用（現在は使用せず）
    
    // Googleカラー
    private let googleColors: [Color] = [
        Color.blue,
        Color.red,
        Color(red: 0.996, green: 0.792, blue: 0.247), // Google黄
        Color(red: 0.298, green: 0.686, blue: 0.314)  // Google緑
    ]
    
    private let centerCircleSize: CGFloat = 70
    private let smallCircleSize: CGFloat = 12
    private let smallCircleCount: Int = 4
    private let animationDuration: Double = 3.0
    private let pulseRange: CGFloat = 0.25 // 拡大・縮小の範囲
    
    var body: some View {
        ZStack {
            // 中心の大きな円
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: centerCircleSize, height: centerCircleSize)
                .scaleEffect(isAnimating ? 1.0 + pulseRange : 1.0 - pulseRange)
                .animation(
                    Animation.easeInOut(duration: animationDuration / 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 中心の小さな円（アクセント）
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: centerCircleSize * 0.4, height: centerCircleSize * 0.4)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: animationDuration / 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                
            // 周りを回る小さな円
            ZStack {
                ForEach(0..<smallCircleCount, id: \.self) { index in
                    let angle = Double(index) * (360.0 / Double(smallCircleCount))
                    let googleColor = googleColors[index % googleColors.count]
                    
                    Circle()
                        .fill(googleColor.opacity(0.85))
                        .frame(width: smallCircleSize, height: smallCircleSize)
                        .offset(
                            x: CGFloat(cos(deg2rad(angle + rotationDegrees))) * (centerCircleSize * 0.9),
                            y: CGFloat(sin(deg2rad(angle + rotationDegrees))) * (centerCircleSize * 0.9)
                        )
                        .scaleEffect(isAnimating ? CGFloat.random(in: 0.8...1.2) : 1.0)
                }
            }
            .rotationEffect(.degrees(rotationDegrees))
            .onAppear {
                withAnimation(Animation.linear(duration: animationDuration * 2)
                                .repeatForever(autoreverses: false)) {
                    rotationDegrees = 360
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // 度からラジアンへの変換
    private func deg2rad(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
}

// プレビュー用
struct BubbleAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()
            BubbleAnimationView(color: .blue)
                .frame(width: 200, height: 200)
        }
    }
} 