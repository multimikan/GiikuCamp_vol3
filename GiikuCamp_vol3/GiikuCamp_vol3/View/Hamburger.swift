import SwiftUI

struct HamburgerMenuSampleView: View {
    @StateObject private var viewModel = HamburgerMenuViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                // メインコンテンツ (現在はCameraView)
                CameraView()
                    .ignoresSafeArea(.all)
            }
            // ハンバーガーボタンをオーバーレイとして配置
            .overlay(alignment: .topTrailing) {
                Button {
                    viewModel.toggleMenu()
                } label: {
                    Image(systemName: "line.horizontal.3")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24) // サイズ調整
                        .padding(12) // タップ領域確保と見た目の調整
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle()) // 丸い背景
                        .shadow(radius: 3)
                }
                .padding(.trailing, 16) // 画面端からのマージン
                .padding(.top, SafeAreaInsetsKey.defaultValue.top + 10) // SafeArea上部からのマージン
            }
            .fullScreenCover(isPresented: $viewModel.isSettingsPresented) {
                // TODO: SettingsSheetViewの実装とViewModel連携
                Text("設定画面 (仮)").onTapGesture { viewModel.isSettingsPresented = false }
            }
            
            // サイドメニュー表示
            if viewModel.isMenuOpen {
                // メニュー背景の暗転オーバーレイ
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.toggleMenu() // 背景タップでメニューを閉じる
                    }
                SideMenuView(viewModel: viewModel)
                    .transition(.move(edge: .trailing)) // アニメーション
            }
        }
    }
}

struct SideMenuView: View {
    @ObservedObject var viewModel: HamburgerMenuViewModel

    var body: some View {
        HStack {
            Spacer() // メニューを右側に寄せる
            VStack(alignment: .leading, spacing: 0) {
                // TODO: プロフィールヘッダーなどを追加する場合はここに
                // Spacer().frame(height: 50)
                
                List {
                    Section {
                        DisclosureGroup(
                            isExpanded: $viewModel.isLearningExpanded // ViewModelのプロパティに直接バインド
                        ) {
                            ForEach($viewModel.subjectCategories) { $category in // Bindingを使ってForEach
                                SubjectCategoryView(category: $category, viewModel: viewModel)
                            }
                        } label: {
                            MenuLabel(title: "科目", systemImage: "book.closed")
                        }
                    }

                    Section {
                        NavigationLink(destination: ChatView().environmentObject(viewModel)) { // ChatViewにViewModelを渡す例
                            MenuLabel(title: "履歴", systemImage: "clock")
                        }
                        NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel())) { // FavoritesView呼び出し例
                            MenuLabel(title: "お気に入り", systemImage: "star")
                        }
                    }
                    
                    Section {
                        Button(action: {
                            viewModel.openSettings()
                        }) {
                            MenuLabel(title: "設定", systemImage: "gearshape")
                        }
                    }
                }
                .listStyle(.grouped) // Listのスタイル変更
                .frame(width: UIScreen.main.bounds.width * 0.75, alignment: .leading) // 画面幅の75%
                .background(Color(UIColor.systemBackground)) // システム標準の背景色
                .edgesIgnoringSafeArea(.bottom) // 下部のSafeAreaを無視
            }
        }
    }
}

// メニュー項目用の共通ラベルView
struct MenuLabel: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        Label(title, systemImage: systemImage)
            .foregroundColor(Color(UIColor.label)) // システム標準の文字色
            .padding(.vertical, 8) // パディング調整
    }
}


struct SubjectCategoryView: View {
    @Binding var category: HamburgerMenuViewModel.SubjectCategory // Bindingで受け取る
    @ObservedObject var viewModel: HamburgerMenuViewModel // ViewModelも引き続き使用

    var body: some View {
        DisclosureGroup(isExpanded: $category.isExpanded) {
            ForEach($category.subjects) { $subject in // Bindingを使ってForEach
                SubjectView(subject: $subject, categoryId: category.id, viewModel: viewModel)
            }
        } label: {
            Toggle(isOn: $category.isAllSelected) {
                Label(category.name, systemImage: category.systemImage)
            }
            .toggleStyle(CheckBoxToggleStyle())
            // onChangeはViewModelのメソッド呼び出しではなく、Binding経由の変更をViewModelが検知する形、
            // または、トグルアクション時にViewModelのメソッドを直接呼ぶ形に変更するのが望ましい。
            // ここではonChange(of: category.isAllSelected) のままとし、ViewModel側の対応を期待。
        }
        .onChange(of: category.isAllSelected) { newValue in
            // このonChangeはViewModelのtoggleSelectAllを呼び出すべきだが、インデックスが必要
            // カテゴリIDなどを使ってViewModel側で対象を特定できるようにする
            if let categoryIndex = viewModel.subjectCategories.firstIndex(where: { $0.id == category.id }) {
                viewModel.toggleSelectAll(forCategoryIndex: categoryIndex, newValue: newValue)
            }
        }
    }
}

struct SubjectView: View {
    @Binding var subject: HamburgerMenuViewModel.Subject // Bindingで受け取る
    let categoryId: UUID // 親カテゴリのID
    @ObservedObject var viewModel: HamburgerMenuViewModel

    var body: some View {
        Toggle(subject.name, isOn: $subject.isSelected)
            .toggleStyle(CheckBoxToggleStyle())
            .onChange(of: subject.isSelected) { _ in
                if let categoryIndex = viewModel.subjectCategories.firstIndex(where: { $0.id == categoryId }) {
                    viewModel.updateAllSelectedState(forCategoryIndex: categoryIndex)
                }
            }
    }
}

// CheckBoxToggleStyle は変更なし
struct CheckBoxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn
                      ? "checkmark.circle.fill"
                      : "circle")
            }
        }
    }
}

// SafeAreaInsetsを取得するためのキー
private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return EdgeInsets()
        }
        let uiInsets = window.safeAreaInsets
        return EdgeInsets(top: uiInsets.top, leading: uiInsets.left, bottom: uiInsets.bottom, trailing: uiInsets.right)
    }
}

#Preview {
    HamburgerMenuSampleView()
        .environmentObject(CloudViewModel()) // Preview用にダミーViewModel供給
        .environmentObject(AuthViewModel())
        .environmentObject(ChatViewModel())
} 
