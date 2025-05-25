import SwiftUI

struct ExplanatoryView: View {
    // ChatViewModelから渡されるデータ。最初の辞書要素を想定。
    var data: [String: String]? 

    // dataから取得した値を保持するプロパティ（デフォルト値も設定）
    private var subject: String { data?["subject"] ?? "情報なし" }
    private var level: String { data?["object"] ?? "情報なし" } // YOLOの物体名をレベルとして表示（変更可能）
    private var unit: String { data?["curriculum"] ?? "情報なし" }
    private var descriptionText: String { data?["description"] ?? "情報なし" } // descriptionキーを使用
    // private var deepDescriptionText: String { data?["deep_description"] ?? "情報なし" } // 必要であれば詳細説明も
    
    @State private var isFavorite = false
    @State private var animateHeart = false
    @State private var isSaved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(level) // ここは "object" を表示する例
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // お気に入り
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        isFavorite.toggle()
                        animateHeart = true
                    }

                    // アニメーション終了後に元に戻す
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateHeart = false
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(isFavorite ? .red : .gray)
                        .scaleEffect(animateHeart ? 1.4 : 1.0)
                }
            }
            
            // 単元名
            Text("「\(unit)」")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 説明文
            Text(descriptionText) // descriptionキーの内容を表示
                .font(.body)
                .lineSpacing(4)
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .cornerRadius(12)
                
                Image(systemName: "book")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 「後で見る」ボタン
            HStack{
                Spacer()
            Button(action: {
                isSaved.toggle()
            }) {
                HStack {
                    Spacer()
                    Label("AIに詳しく聞いてみる", systemImage: "wand.and.sparkles")
                    Spacer()
                }
                //.frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 5)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#0066FF"),
                            Color(hex: "#ffff00")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            Spacer()
        }
        }
        .padding(32)
    }
}

struct ExplanatoryTextView: View {
    @State private var isShowingModal = false
    // テスト用のサンプルデータ
    let sampleData: [String: String] = [
        "subject": "物理学",
        "object": "リンゴ",
        "curriculum": "万有引力",
        "description": "リンゴが木から落ちるのを見て、ニュートンは万有引力の法則を発見しました。",
        "deep_description": "すべての物体は互いに引き合う力を持っており、その力は物体の質量に比例し、距離の二乗に反比例します。"
    ]

    var body: some View {
        Button("説明を表示") {
            isShowingModal = true
        }
        .sheet(isPresented: $isShowingModal) {
            // サンプルデータを渡して表示
            ExplanatoryView(data: sampleData)
        }
    }
}



#Preview {
    // PreviewWrapperをExplanatoryTextViewに置き換えて、サンプルデータでプレビュー
    ExplanatoryTextView()
}

// PreviewWrapperは不要になるのでコメントアウトまたは削除
//private struct PreviewWrapper: View {
//    @State var isShowingModal: Bool = false
//    
//    var body: some View {
//        VStack{
//        VStack{
//            Button("画像"){
//                isShowingModal = true
//            }
//        }
//    }
//        .halfModal(isShow: $isShowingModal) {
//            ExplanatoryView(data: nil) // dataプロパティを追加したのでnilを渡すか、サンプルデータを渡す
//        } onEnd: {
//        }
//    }
//}
