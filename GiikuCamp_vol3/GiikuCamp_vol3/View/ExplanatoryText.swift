import SwiftUI

struct ExplanatoryView: View {
    @ObservedObject var viewModel: ExplanatoryViewModel
    
    @State private var animateHeart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // タイトル
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.subject)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(viewModel.level)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    viewModel.toggleFavorite()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        animateHeart = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animateHeart = false
                    }
                }) {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(viewModel.isFavorite ? .red : .gray)
                        .scaleEffect(animateHeart ? 1.4 : 1.0)
                }
            }
            
            Text("「\(viewModel.unit)」")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.description)
                .font(.body)
                .lineSpacing(4)
            
            if let imageName = viewModel.imageName, !imageName.isEmpty {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
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
            }
            
            Spacer()
            
            HStack{
                Spacer()
                Button(action: {
                    viewModel.detailedExplanationRequested()
                }) {
                    HStack {
                        Label("AIに詳しく聞いてみる", systemImage: "wand.and.sparkles")
                            .padding(.horizontal,48)
                    }
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
    let exampleViewModel = ExplanatoryViewModel(
        subject: "物理", 
        level: "高校", 
        unit: "慣性の法則", 
        description: "慣性の法則は、物体が外から力を受けない限り、その運動状態を保ち続けるという法則です。",
        isInitialFavorite: true
    )

    var body: some View {
        Button("説明を表示") {
            isShowingModal = true
        }
        .sheet(isPresented: $isShowingModal) {
            ExplanatoryView(viewModel: exampleViewModel)
        }
    }
}

#Preview {
    ExplanatoryView(viewModel: ExplanatoryViewModel(
        subject: "化学", 
        level: "高校", 
        unit: "酸化還元反応", 
        description: "酸化還元反応は、物質間で電子の授受が行われる化学反応です。酸化される物質は電子を失い、還元される物質は電子を得ます。",
        imageName: "testImage",
        isInitialFavorite: false
    ))
}
