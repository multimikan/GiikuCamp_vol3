//
//  Terms.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/21.
//

import SwiftUI

struct TermsAgreementView: View {
    var onAgree: () -> Void  // 同意ボタンを押したときの処理

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer().frame(height: 220)

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
        }
        .background(Color(uiColor: .white))
        .ignoresSafeArea()
    }
}

#Preview {
    TermsAgreementView(onAgree: { print("Agreed from Preview") })
}
