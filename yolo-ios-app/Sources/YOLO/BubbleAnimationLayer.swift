import UIKit

class BubbleAnimationLayer: CALayer {
    
    // ビビッドカラーパレット (紫と青を除外し、彩度を調整)
    private let bubbleColors: [UIColor] = [
        UIColor(red: 1.00, green: 0.10, blue: 0.25, alpha: 1.0), // Vivid Red (彩度アップ)
        UIColor(red: 1.00, green: 0.45, blue: 0.00, alpha: 1.0), // Vivid Orange (彩度アップ)
        UIColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1.0), // Vivid Yellow (彩度アップ)
        UIColor(red: 0.10, green: 0.85, blue: 0.10, alpha: 1.0), // Vivid Green (彩度アップ)
        UIColor(red: 1.00, green: 0.00, blue: 0.50, alpha: 1.0)  // Vivid Pink (彩度アップ)
    ]
    
    private let layerSize: CGFloat = 100
    private let maxBubbleCount = 15 // 同時に表示する最大泡数を少し増やす
    private var bubbleLayers: [CAShapeLayer] = []
    private var animationTimer: Timer?
    
    override init() {
        super.init()
        setupLayer()
        startBubbleAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
        startBubbleAnimation()
    }
    
    private func setupLayer() {
        // レイヤーのサイズを設定
        self.frame = CGRect(x: 0, y: 0, width: layerSize, height: layerSize)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    private func startBubbleAnimation() {
        // タイマーを作成して泡を定期的に生成
        DispatchQueue.main.async {
            // タイマー間隔を少し短くして泡の発生頻度を上げることも検討 (例: 0.15)
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
                self?.createBubble()
            }
        }
        
        // 初期の泡をランダムな数だけ生成
        let initialBubbles = Int.random(in: 4...7)
        for _ in 0..<initialBubbles {
            createBubble()
        }
    }
    
    private func createBubble() {
        // 既存の泡の数が最大数を超えていたら古い泡を削除
        while bubbleLayers.count >= maxBubbleCount, let oldestBubble = bubbleLayers.first {
            oldestBubble.removeFromSuperlayer()
            bubbleLayers.remove(at: 0)
        }
        
        let bubble = CAShapeLayer()
        
        // 泡のランダムなサイズと位置を決定
        let initialSize = CGFloat.random(in: 8...20) // サイズ範囲をさらに調整
        let finalSize = initialSize * CGFloat.random(in: 2.8...5.0) // 拡大率をさらに調整
        
        // レイヤーの中心からランダムな距離と角度の位置
        let distance = CGFloat.random(in: 0...layerSize/3.5) // 中心付近に集まりやすくする
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let x = (layerSize/2) + cos(angle) * distance
        let y = (layerSize/2) + sin(angle) * distance
        
        // 泡の色をランダムに選択
        let randomColor = bubbleColors.randomElement() ?? bubbleColors[0]
        
        bubble.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: initialSize, height: initialSize)).cgPath
        bubble.position = CGPoint(x: x - initialSize/2, y: y - initialSize/2)
        bubble.fillColor = randomColor.withAlphaComponent(0.95).cgColor // 不透明度をほぼ最大に
        
        // 影をつけて立体感を出す
        bubble.shadowColor = UIColor.black.cgColor
        bubble.shadowOffset = CGSize(width: 0, height: 1.5) // 影のオフセットを少し大きく
        bubble.shadowOpacity = 0.3 // 影を濃くする
        bubble.shadowRadius = 2.0   // 影のぼかしを調整
        
        addSublayer(bubble)
        bubbleLayers.append(bubble)
        
        // 拡大と透明化のアニメーション
        let duration = Double.random(in: 1.0...1.8) // アニメーション時間を少し長く
        
        // スケールアニメーション
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = finalSize / initialSize
        scaleAnimation.duration = duration
        
        // 透明度アニメーション
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.95 // 開始時の不透明度
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = duration
        
        // 位置の微調整アニメーション（泡が浮き上がるような効果）
        let moveAnimation = CABasicAnimation(keyPath: "position")
        let moveDistance = CGFloat.random(in: 15...30) // 移動距離を調整
        let moveAngle = angle + CGFloat.random(in: -0.6...0.6)
        let newX = bubble.position.x + cos(moveAngle) * moveDistance
        let newY = bubble.position.y + sin(moveAngle) * moveDistance
        moveAnimation.fromValue = bubble.position
        moveAnimation.toValue = CGPoint(x: newX, y: newY)
        moveAnimation.duration = duration
        
        // アニメーショングループ
        let animGroup = CAAnimationGroup()
        animGroup.animations = [scaleAnimation, opacityAnimation, moveAnimation]
        animGroup.duration = duration
        animGroup.fillMode = .forwards
        animGroup.isRemovedOnCompletion = false
        
        // アニメーション終了後に泡を削除
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak bubble] in
            guard let bubble = bubble else { return }
            bubble.removeFromSuperlayer()
            self?.bubbleLayers.removeAll { $0 === bubble }
        }
        
        bubble.add(animGroup, forKey: "bubblingAnimation")
    }
    
    // このメソッドを追加して、レイヤーの全ての泡アニメーションを停止し、クリアする
    func stopAllBubblesAndRemove() {
        animationTimer?.invalidate()
        animationTimer = nil
        for bubble in bubbleLayers {
            bubble.removeAllAnimations()
            bubble.removeFromSuperlayer()
        }
        bubbleLayers.removeAll()
        self.removeFromSuperlayer() // レイヤー自身も削除
    }

    override func removeFromSuperlayer() {
        animationTimer?.invalidate() // タイマーが重複して無効化されるが問題ない
        animationTimer = nil
        // すでにstopAllBubblesAndRemoveで処理されていれば、ここでの追加処理は不要な場合もある
        // しかし、直接removeFromSuperlayerが呼ばれるケースも考慮して残す
        for bubble in bubbleLayers {
            bubble.removeAllAnimations()
            bubble.removeFromSuperlayer()
        }
        bubbleLayers.removeAll()
        super.removeFromSuperlayer()
    }
} 