import SwiftUI

// 各泡の状態を管理する構造体
// Bubble構造体はpublicにする必要はない（BubbleAnimationViewの内部実装のため）
struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var initialSize: CGFloat
    var finalSizeRatio: CGFloat // 初期サイズに対する最終サイズの比率
    var color: Color
    var opacity: Double = 0.95 // 初期不透明度を BubbleAnimationLayer に合わせる
    var creationTime: Date = Date() // 生成時刻（アニメーション進行度の計算用）
    var animationDuration: Double
    var moveAngle: CGFloat // 移動方向の角度
    var moveDistance: CGFloat // 実際の移動距離
}

public struct BubbleAnimationView: View { // public に変更
    // color プロパティは元のシグネチャに合わせて残すが、ここでは未使用
    // public let color: Color // もし外部から色を指定できるようにするならpublicにする

    @State private var bubbles: [Bubble] = []
    private let layerSize: CGFloat = 100 // アニメーションが発生するエリアのサイズ
    private let maxBubbleCount = 12 // 少し減らしてみる
    private let bubbleGenerationInterval: TimeInterval = 0.2 // 間隔を少し長く

    private let bubbleColors: [Color] = [
        Color(red: 1.00, green: 0.10, blue: 0.25), // Vivid Red
        Color(red: 1.00, green: 0.45, blue: 0.00), // Vivid Orange
        Color(red: 1.00, green: 0.80, blue: 0.00), // Vivid Yellow
        Color(red: 0.10, green: 0.85, blue: 0.10), // Vivid Green
        Color(red: 1.00, green: 0.00, blue: 0.50)  // Vivid Pink
    ]
    
    public init() {} // publicなイニシャライザを追加

    public var body: some View { // bodyもpublicである必要がある (Viewプロトコルにより暗黙的にpublic)
        TimelineView(.periodic(from: .now, by: bubbleGenerationInterval)) { timelineContext in
            Canvas { context, size in
                let currentTime = timelineContext.date
                
                // bubbles 配列のコピーに対して操作を行う（同時変更を避けるため）
                // ただし、Canvasの描画はメインスレッドで行われるので、
                // bubblesの更新もメインスレッドなら大きな問題にはなりにくい
                for bubble in bubbles {
                    let elapsedTime = max(0, currentTime.timeIntervalSince(bubble.creationTime))
                    let progress = min(1, elapsedTime / bubble.animationDuration)

                    if progress < 1.0 {
                        let currentScale = 1.0 + (bubble.finalSizeRatio - 1.0) * CGFloat(progress)
                        let baseOpacity = bubble.opacity // BubbleAnimationLayerの初期不透明度
                        let currentOpacity = baseOpacity * (1.0 - progress) // 線形に減少
                        
                        if currentOpacity < 0.01 { continue } // ほぼ透明なら描画スキップ

                        let moveX = cos(bubble.moveAngle) * bubble.moveDistance * CGFloat(progress)
                        let moveY = sin(bubble.moveAngle) * bubble.moveDistance * CGFloat(progress)
                        
                        let currentBubbleSize = bubble.initialSize * currentScale
                        // 泡の中心が (bubble.position.x + moveX, bubble.position.y + moveY) になるようにrectを計算
                        let bubbleRect = CGRect(
                            x: bubble.position.x + moveX - currentBubbleSize / 2,
                            y: bubble.position.y + moveY - currentBubbleSize / 2,
                            width: currentBubbleSize,
                            height: currentBubbleSize
                        )
                        
                        // 影の描画 (CALayerの影とは異なる単純なもの)
                        let shadowOffset = CGSize(width: 0, height: 1.5)
                        let shadowRect = bubbleRect.offsetBy(dx: shadowOffset.width, dy: shadowOffset.height)
                        context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.3 * currentOpacity)))

                        // 泡本体の描画
                        context.fill(Path(ellipseIn: bubbleRect), with: .color(bubble.color.opacity(currentOpacity)))
                    }
                }
            }
            .frame(width: layerSize, height: layerSize)
            // .drawingGroup() // Canvasには通常不要だが、非常に複雑な場合は試す価値あり
            .onAppear {
                if bubbles.isEmpty { // 初回のみ、または必要に応じて初期化
                    for _ in 0..<Int.random(in: 3...5) { // 初期数を減らす
                        generateBubble(currentTime: .now)
                    }
                }
            }
            .onChange(of: timelineContext.date) { newDate in
                // 新しい泡を生成 (メインスレッドで bubbles を変更)
                if bubbles.count < maxBubbleCount {
                     generateBubble(currentTime: newDate)
                }
                // 古い泡を削除 (メインスレッドで bubbles を変更)
                bubbles.removeAll { bubble in
                    let elapsedTime = newDate.timeIntervalSince(bubble.creationTime)
                    return elapsedTime > bubble.animationDuration
                }
            }
        }
    }

    private func generateBubble(currentTime: Date) {
        let initialSize = CGFloat.random(in: 8...20)
        let finalSizeRatio = CGFloat.random(in: 2.8...5.0)
        
        let distanceFromCenter = CGFloat.random(in: 0...layerSize/3.5)
        let angleFromCenter = CGFloat.random(in: 0...(2 * .pi))
        // 初期位置 (アンカーポイントが中心になるように計算)
        let initialX = (layerSize/2) + cos(angleFromCenter) * distanceFromCenter
        let initialY = (layerSize/2) + sin(angleFromCenter) * distanceFromCenter
        
        let randomColor = bubbleColors.randomElement() ?? bubbleColors[0]
        let duration = Double.random(in: 1.0...1.8)
        
        // 移動アニメーション用
        let moveDistance = CGFloat.random(in: 15...30)
        let moveAngle = angleFromCenter + CGFloat.random(in: -0.6...0.6) // 元の角度からの変動

        let newBubble = Bubble(
            position: CGPoint(x: initialX, y: initialY),
            initialSize: initialSize,
            finalSizeRatio: finalSizeRatio,
            color: randomColor,
            opacity: 0.95, // 初期不透明度
            creationTime: currentTime,
            animationDuration: duration,
            moveAngle: moveAngle,
            moveDistance: moveDistance
        )
        
        var tempBubbles = bubbles // bubblesを直接変更する代わりに一時配列を使用
        tempBubbles.append(newBubble)

        while tempBubbles.count > maxBubbleCount {
            tempBubbles.removeFirst()
        }
        bubbles = tempBubbles // 最後にまとめて更新
    }
}

struct BubbleAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.5)
                .ignoresSafeArea()
            BubbleAnimationView() // color引数は不要になった
        }
    }
} 
