import SwiftUI


//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        let scanner = Scanner(string: hex)
//        _ = scanner.scanString("#")
//
//        var rgb: UInt64 = 0
//        scanner.scanHexInt64(&rgb)
//
//        let r = Double((rgb >> 16) & 0xFF) / 255
//        let g = Double((rgb >> 8) & 0xFF) / 255
//        let b = Double(rgb & 0xFF) / 255
//
//        self.init(red: r, green: g, blue: b)
//    }
//}

struct PlantPromptView: View {
    var body: some View {
        ZStack {
            // 背景画像（暗くする）
            Image("yourBackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.5)) // 半透明オーバーレイ

            VStack(spacing: 20) {
                Spacer()

                // カメラアイコン
                Image(systemName: "camera")
                    .resizable()
                    .frame(width: 50, height: 40)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                // タイトル
                Text("カメラで周りを見渡してみましょう")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // 説明
                Text("カメラで物体を認識して\nコレナニの使い方を理解しましょう。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 30)

                // 「試す」ボタン（グラデーション & 丸み）
                Button(action: {
                    // アクション
                }) {
                    Text("試す")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(hex: "#0066ff"), Color(hex:"#FFFF00")]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .cornerRadius(25)
                }
                .padding(.top, 10)

                // 下部リンク
                Button(action: {
                    // 他の画面へ
                }) {
                    Text("キャンセル")
                        .foregroundColor(.blue)
                        .underline()
                }

                Spacer()
            }
        }
    }
}

#Preview {
    PlantPromptView()
}



