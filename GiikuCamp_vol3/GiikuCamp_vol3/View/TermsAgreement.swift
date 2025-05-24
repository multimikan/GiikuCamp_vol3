//
//  Terms.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/21.
//

import SwiftUI

struct TermsAgreementView: View {
    var onAgree: () -> Void  // 続けるボタンを押したときの処理を外部に渡せるように
    @State private var showBottomContent = false // 下部コンテンツの表示状態を管理

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer().frame(height: 220)

                // ロゴと説明など中央に配置
                VStack(spacing:10) {
                    Spacer().frame(height: 1)
                    
                    VStack(spacing: 0){
                        Image("Me")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)

                        
                        Text("君がみてる景色が、\n教科書だ。")
                            .font(.title)
                            .multilineTextAlignment(.center)

                    }
                }

                Spacer()
            }

            // 👇 続けるボタンを下部に固定
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("「続ける」をタップすると、当アプリの利用規約に同意され、\nプライバシーポリシーを読まれたものとみなします。")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Link("利用規約", destination: URL(string: "https://your-terms-url.com")!)
                            .underline()
                        
                        Link("プライバシーポリシー", destination: URL(string: "https://your-privacy-url.com")!)
                            .underline()
                    }
                    .font(.footnote)
                }
                
                Spacer().frame(height: 27)
                
                Button(action: {
                    onAgree()
                }) {
                    Text("続ける")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .frame(width: 340)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#0066FF"),
                                    Color(hex: "#FFFF00")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    
                }
            }
            .opacity(showBottomContent ? 1 : 0) // 表示状態に応じて透明度を変更
            .offset(y: showBottomContent ? 0 : 20) // 表示状態に応じて位置を調整
            .animation(.easeInOut(duration: 0.5), value: showBottomContent) // アニメーション設定
        }
        .background(Color(uiColor: .white))
        .ignoresSafeArea()       // ← 全画面に適用する場合
        .onAppear {
            // 0.5秒後に下部コンテンツを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showBottomContent = true
            }
        }
    }
}

#Preview {
    TermsAgreementView(onAgree: {})
}



extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
