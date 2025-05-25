import SwiftUI

struct SettingsSheetView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isSettingsPresented: Bool
    
    @State private var selectedLevel = "小学校"
    @State private var selectedModel = "低"
    @State private var selectedLanguage = ""
    
    @State private var isEditingLanguage = false
    @State private var language: String = "日本語"
    
    let models = ["低", "中", "高"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タイトルと閉じる
                HStack {
                    Spacer()
                    Label("設定", systemImage: "gearshape")
                        .font(.title2)
                        .labelStyle(TitleOnlyLabelStyle())
                        .padding()
                    Spacer()
                }
                .overlay(
                    HStack {
                        Button(action: {
                            isSettingsPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.body)
                        }
                        .padding(.leading)
                        Spacer()
                    }
                )
                
                Divider()
                
                // 設定項目
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack{
                                Text("アカウント情報")
                                    .font(.headline)
                                Spacer()
                                if let ＿ = authViewModel.user {
                                    Button(action:{
                                        authViewModel.signOut()
                                    }){
                                        Text("ログアウト")
                                            .padding(8)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                                
                            }
                            if let user = authViewModel.user {
                                HStack{
                                    if let photoURL = authViewModel.user?.photoURL {
                                        AsyncImage(url: photoURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .padding(.horizontal, 12)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 12)
                                    }
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(user.displayName ?? "表示名なし")
                                            
                                        }
                                        HStack {
                                            Text(user.email ?? "メールアドレスなし")
                                        }
                                    }
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    Text("ステータス")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("未ログイン")
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 1))
                        
                        SettingsBox(title: "モデルの切り替え") {
                            Picker("モデル", selection: $selectedModel) {
                                ForEach(["低", "中", "高"], id: \.self) {
                                    Text($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        SettingsBox(title: "使用言語") {
                            HStack {
                                if isEditingLanguage {
                                    TextField("使用言語を入力", text: $language)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Text(language.isEmpty ? "未設定" : language)
                                            .foregroundColor(language.isEmpty ? .gray : .primary)
                                            .padding(.leading, 8)
                                        Spacer()
                                    }
                                    .frame(height: 40)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        isEditingLanguage.toggle()
                                    }
                                }) {
                                    Image(systemName: isEditingLanguage ? "checkmark.circle.fill" : "pencil")
                                    
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.blue)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SettingsBox<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 1))
    }
}

#Preview {
    @Previewable @State var b = true
    SettingsSheetView(isSettingsPresented: $b)
        .environmentObject(AuthViewModel())
}
