import SwiftUI
import YOLO


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

struct TutrialView: View {
    @Binding var isPresented: Bool // 自身を閉じるためのBinding
    @State var state: Int = 0
    
    var body: some View {
        ZStack {
            switch state {
            case 0:
                t0(isPresented: $isPresented, state: $state)
            case 1:
                t1(state: $state, isPresented: $isPresented)
            default:
                Home()
            }
            
        }
    }
    
    struct t0: View {
        @Binding var isPresented: Bool
        @Binding var state: Int
        
        var body: some View {
            // 背景を半透明の黒にする (下のビューがうっすら見えるように)
            Color.black.opacity(0.7) // 例: 70%の黒
                .ignoresSafeArea()
                .onTapGesture { // 背景タップでも閉じられるようにする（オプション）
                    // isPresented = false
                }
            
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
                Text("カメラで物体を認識して\nChameLearnの使い方を理解しましょう。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 30)
                
                // 「試す」ボタン（グラデーション & 丸み）
                Button(action: {
                    state += 1
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
                    isPresented = false
                }) {
                    Text("キャンセル")                        .foregroundColor(Color(uiColor: .yellow ))
                        .underline()
                }
                .padding(.top)
                
                Spacer()
            }
        }
    }
    
    struct t1: View {
        @Binding var state: Int
        @Binding var isPresented: Bool
        
        var body: some View {
            Color.black.opacity(0.7) // 例: 70%の黒
                .ignoresSafeArea()
                .onTapGesture { // 背景タップでも閉じられるようにする（オプション）
                    // isPresented = false
                }
            
            ZStack {
                BubbleAnimationView()
                
                VStack{
                    Spacer()
                    Text("アニメーションを探しましょう")
                        .foregroundStyle(.white)
                        .font(.title2)
                        .bold()
                        .padding(.vertical, 30)
                    
                    
                    // 説明
                    Text("タップすると説明を開始します。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.bottom, 300)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("やってみる")
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
                .padding(.top, 400)
            }
            
        }
    }
    
    struct t2: View {
        var body: some View {
            Text("Hello, World!")
        }
    }
}

#Preview {
    // プレビュー用に@State変数をダミーで作成して渡す
    struct PreviewWrapper: View {
        @State var showTutorial = true
        var body: some View {
            TutrialView(isPresented: $showTutorial)
        }
    }
    return PreviewWrapper()
}



