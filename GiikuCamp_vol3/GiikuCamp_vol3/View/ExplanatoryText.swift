import SwiftUI

struct ExplanatoryView: View {
    // ChatViewModelから渡されるデータ。最初の辞書要素を想定。
    var data: [String: String]? 

    // dataから取得した値を保持するプロパティ（デフォルト値も設定）
    private var subject: String { data?["subject"] ?? "情報なし" }
    private var level: String { data?["object"] ?? "情報なし" } // YOLOの物体名をレベルとして表示（変更可能）
    private var unit: String { data?["curriculum"] ?? "情報なし" }
    private var descriptionText: String { data?["description"] ?? "情報なし" } // descriptionキーを使用
    private var imageUrlString: String? { data?["image_url"] } // 画像URLを取得
    private var deepDescriptionText: String { data?["deep_description"] ?? "詳細説明はありません。" } // 有効化し、デフォルト値も設定
    
    @State private var isFavorite = false
    @State private var animateHeart = false
    @State private var showingDeepDescriptionView = false // 詳細説明表示用の状態変数

    // URLSessionでの画像ロード試行用の状態
    @State private var manuallyLoadedImage: Image? = nil
    @State private var manualLoadError: String? = nil
    @State private var isLoadingManually = false

    var body: some View {
        // --- Debug Logs Start ---
        let _ = Self._printChanges()
        let _ = print("ExplanatoryView - Received data: \(String(describing: data))")
        let _ = print("ExplanatoryView - Extracted imageUrlString: \(String(describing: imageUrlString))")
        // --- Debug Logs End ---
        
        // showingDeepDescriptionView の状態に応じて表示を切り替える
        if showingDeepDescriptionView {
            deepDescriptionDetailView
        } else {
            normalExplanatoryView
        }
    }
    
    // 通常の説明表示ビュー
    private var normalExplanatoryView: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
                        
            Spacer()
            
            actionButton // 「AIに詳しく聞いてみる」ボタンを抽出
        }
        .padding(32)
    }
    
    // 詳細説明表示ビュー
    private var deepDescriptionDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(subject)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    showingDeepDescriptionView = false // 通常表示に戻る
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            Text("オブジェクト: \(level)") // level は object の内容
                .font(.title3)
                .foregroundColor(.secondary)
            Text("学習単元: 「\(unit)」")
                .font(.title3)
                .fontWeight(.semibold)
            
            Divider()
            
            ScrollView {
                Text(deepDescriptionText)
                    .font(.body)
                    .lineSpacing(5)
            }
            
            Spacer()
        }
        .padding(32)
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))) // アニメーション（オプション）
    }
    
    // 「AIに詳しく聞いてみる」ボタン部分
    private var actionButton: some View {
        HStack{
            Spacer()
            Button(action: {
                withAnimation { // アニメーションを追加
                    showingDeepDescriptionView = true
                }
            }) {
                HStack {
                    Spacer()
                    Label("AIに詳しく聞いてみる", systemImage: "wand.and.sparkles")
                    Spacer()
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
    
    // 共通のプレースホルダー
    private var imageLoadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).frame(height: 150)
            ProgressView()
        }
    }
    private var defaultImagePlaceholder: some View {
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 150).cornerRadius(12)
            Image(systemName: "photo.on.rectangle.angled").resizable().scaledToFit().frame(height: 80).foregroundColor(.gray.opacity(0.7))
        }
    }
    private func errorPlaceholder(errorMessage: String) -> some View {
        ZStack {
            Rectangle().fill(Color.red.opacity(0.1)).frame(height: 150).cornerRadius(12)
            VStack {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.largeTitle)
                Text("画像表示不可") .font(.caption).foregroundColor(.red.opacity(0.8))
                // Text(errorMessage).font(.caption2).foregroundColor(.red.opacity(0.7)).padding(.horizontal)
            }
        }
    }

    // URLSessionで画像を非同期にロードするメソッド
    private func loadImageManually(urlString: String?) {
        guard let urlStr = urlString, !urlStr.isEmpty, let url = URL(string: urlStr) else {
            manualLoadError = "無効なURLです。"
            return
        }

        isLoadingManually = true
        manualLoadError = nil
        manuallyLoadedImage = nil

        print("Attempting manual load for: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingManually = false
                if let error = error {
                    print("Manual load URLSession error: \(error.localizedDescription)")
                    manualLoadError = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Manual load error: Not an HTTP response.")
                    manualLoadError = "サーバーからの応答が不正です。"
                    return
                }
                
                print("Manual load HTTP Status Code: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    manualLoadError = "サーバーエラー (コード: \(httpResponse.statusCode))"
                    return
                }

                guard let data = data, let uiImage = UIImage(data: data) else {
                    print("Manual load error: Data could not be converted to UIImage. Content-Type: \(httpResponse.mimeType ?? "N/A")")
                    manualLoadError = "画像データ形式が非対応です (MIME: \(httpResponse.mimeType ?? "N/A"))。SVG形式の可能性があります。"
                    return
                }
                
                print("Manual load success for: \(url.absoluteString)")
                manuallyLoadedImage = Image(uiImage: uiImage)
            }
        }.resume()
    }
}

struct ExplanatoryTextView: View {
    @State private var isShowingModal = false
    // テスト用のサンプルデータ（画像URLあり）
    let sampleDataWithImage: [String: String] = [
        "subject": "物理学",
        "object": "光",
        "curriculum": "光の屈折",
        "description": "光が異なる物質の境界面を通過するとき、進行方向が変わる現象です。",
        "deep_description": "これは、光の速さが物質によって異なるために起こります。スネルの法則によって定量的に記述できます。光ファイバーやレンズなど、多くの光学機器で利用されています。虹が見えるのも、空気中の水滴による光の屈折と分散が原因です。",
        "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Snells_law2.svg/300px-Snells_law2.svg.png"
    ]
    // テスト用のサンプルデータ（画像URLなし、または空文字列）
    let sampleDataWithoutImage: [String: String] = [
        "subject": "数学",
        "object": "円",
        "curriculum": "円周率",
        "description": "円の周の長さと直径の比のことです。",
        "deep_description": "π（パイ）という記号で表され、約3.14159...と無限に続く無理数です。超越数の一つでもあり、日常生活から高度な科学技術まで幅広く利用されています。例えば、円形のものの面積や体積を計算するのに使われます。",
        "image_url": "" // 空文字列のケース
    ]
    let sampleDataInvalidUrl: [String: String] = [
        "subject": "地理",
        "object": "山脈",
        "curriculum": "造山運動",
        "description": "地球のプレートテクトニクスによって形成される大規模な山々の連なり。",
        "deep_description": "衝突型、沈み込み型など、プレートの相互作用によって様々なタイプの山脈が形成されます。ヒマラヤ山脈やアンデス山脈などが有名です。",
        "image_url": "これはURLではありません"
    ]

    @State private var dataForSheet: [String: String]? = nil

    var body: some View {
        VStack(spacing: 20) {
            Button("説明を表示 (画像あり)") {
                dataForSheet = sampleDataWithImage
                isShowingModal = true
            }
            Button("説明を表示 (画像なし)") {
                dataForSheet = sampleDataWithoutImage
                isShowingModal = true
            }
            Button("説明を表示 (URL無効)") {
                dataForSheet = sampleDataInvalidUrl
                isShowingModal = true
            }
        }
        .sheet(isPresented: $isShowingModal) {
            if let data = dataForSheet {
                ExplanatoryView(data: data)
            }
        }
    }
}

#Preview {
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
