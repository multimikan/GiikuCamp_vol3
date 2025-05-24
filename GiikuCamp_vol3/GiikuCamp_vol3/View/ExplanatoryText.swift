import SwiftUI

struct ExplanatoryView: View {
    var subject: String = "物理"
    var level: String = "高校"
    var unit: String = "慣性の法則"
    var description: String = "慣性の法則は、物体が外から力を受けない限り、その運動状態を保ち続けるという法則です。"
    
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
                    Text(level)
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
            Text(description)
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
                    Label("AIに詳しく聞いてみる", systemImage: "wand.and.sparkles")
                        .padding(.horizontal,48)
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

    var body: some View {
        Button("説明を表示") {
            isShowingModal = true
        }
        .sheet(isPresented: $isShowingModal) {
            ExplanatoryView()
        }
    }
}



#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State var isShowingModal: Bool = false
    
    var body: some View {
        VStack{
        VStack{
            Button("画像"){
                isShowingModal = true
            }
        }
    }
        .halfModal(isShow: $isShowingModal) {
            ExplanatoryView()
        } onEnd: {
        }
    }
}
