import SwiftUI

struct HumburgerMenuSampleView: View {
    @AppStorage("hasLaunchedBeforeV1") var hasLaunchedBefore: Bool = false // 初回起動フラグ (キー名を変更して再表示テスト可能)
    @State private var showTutorialSheet: Bool = false

    @State private var isMenuOpen = false
    @State private var selectedScreen = "Home"
    @State private var isSettingsPresented = false

    
    // 学校区分のキー (CloudViewModelと一致させる)
    private let schoolKeys = ["小学校", "中学校", "高校"]
    private func schoolDisplayName(key: String) -> String { // 表示名用
        return key 
    }

    // DisclosureGroup の開閉状態管理 (学校キーをキーとする辞書で管理)
    @State private var isSchoolGroupExpanded: [String: Bool] = ["小学校": false, "中学校": false, "高校": false]
    @State private var isLearningExpanded = true // 「科目」全体のDisclosureGroup
    
    // 全選択トグル用のローカルState（onChangeのトリガー用）
    @State private var selectAllStates: [String: Bool] = ["小学校": false, "中学校": false, "高校": false]

    @StateObject private var cloudViewModel = CloudViewModel()
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var authViewModel = AuthViewModel()

    let imageSize:CGFloat = 4
    
    init() {
        let cvm = CloudViewModel()
        _cloudViewModel = StateObject(wrappedValue: cvm)
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(cloudViewModel: cvm))
        // ここで hasLaunchedBefore をチェックして showTutorialSheet の初期値を設定することも可能だが、
        // onAppear で行う方がビューライフサイクルと一致しやすい。
    }
    
    var body: some View {
        ZStack { // メインのZStack: Homeコンテンツとチュートリアルを重ねる
            // Homeコンテンツ (既存のZStackまたはNavigationStack)
            ZStack { 
                NavigationStack {
                    VStack {
                        CameraView()
                            .ignoresSafeArea()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                withAnimation {
                                    isMenuOpen.toggle()
                                }
                            } label: {
                                ZStack {
                                    // 背景
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(radius: 5)
                                        .frame(width: 56, height: 56)
                                        .opacity(0.8)
                                    
                                    // アイコン
                                    Image(systemName: "line.horizontal.3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
                .environmentObject(chatViewModel)
                .environmentObject(authViewModel) // AuthViewModelを環境に追加
                .fullScreenCover(isPresented: $isSettingsPresented, content: {
                    SettingsSheetView(isSettingsPresented: $isSettingsPresented)
                        .environmentObject(chatViewModel) 
                        .environmentObject(authViewModel) // SettingsSheetViewにもAuthViewModelを渡す
                })
                // サイドメニュー
                if isMenuOpen {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#FFFF00"), // 黄色
                            Color(hex: "#0066FF")  // 青
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }

//                    NavigationLink(destination: ChatView()){ // ChatViewにも必要なら渡す
//                        Label("履歴",systemImage: "clock")
//                    }
//                    .environmentObject(chatViewModel)
                    
                    HStack {
                        Spacer()
                        List {
                            DisclosureGroup("科目", isExpanded: $isLearningExpanded){
                                ForEach(schoolKeys, id: \.self) { schoolKey in
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { self.isSchoolGroupExpanded[schoolKey] ?? false },
                                            set: { self.isSchoolGroupExpanded[schoolKey] = $0 }
                                        )
                                    ) {
                                        // 科目トグルを動的に生成
                                        if let subjects = cloudViewModel.data.favorite[schoolKey]?.keys.sorted() {
                                            ForEach(subjects, id: \.self) { subjectKey in
                                                Toggle(subjectKey, isOn: subjectBinding(school: schoolKey, subject: subjectKey))
                                                    .toggleStyle(CheckBoxToggleStyle())
                                            }
                                        } else {
                                            Text("この学校区分の科目がありません。")
                                                .foregroundColor(.gray)
                                        }
                                    } label: {
                                        Toggle(isOn: selectAllSchoolBinding(for: schoolKey)) {
                                            Label(schoolDisplayName(key: schoolKey), systemImage: "graduationcap")
                                        }.toggleStyle(CheckBoxToggleStyle())
                                        .onChange(of: selectAllStates[schoolKey] ?? false) { newValue in
                                             // このonChangeはselectAllStatesの変更をトリガーにCloudVMを更新
                                             updateAllSubjectsInCloud(for: schoolKey, selectAll: newValue)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            
                            //履歴
                            NavigationLink(destination:
                                            HistoryView()
                                .navigationTitle("履歴")
                                .navigationBarTitleDisplayMode(.large)
                            ){
                                Label("履歴",systemImage: "clock")
                                    .padding(.vertical, 20)
                            }
                        
                            //お気に入り
                            NavigationLink(destination: ChatView().environmentObject(chatViewModel).environmentObject(authViewModel)){
                                Label("お気に入り", systemImage: "star")
                                    .padding(.vertical, 20)
                            }
                            
                           
                          
                            Button {
                                withAnimation {
                                    isMenuOpen = false
                                }
                                isSettingsPresented = true
                            } label: {
                                Label("設定",systemImage: "gearshape")
                                    .padding(.vertical, 20)
                            }
                        }
                        .listStyle(.inset)
                        .frame(maxHeight: .infinity)
                        .frame(width: 250)
                        .background(Color.white)
                        .foregroundColor(.black)
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            // ここまでHomeコンテンツ

            // チュートリアルビューを条件付きで上に重ねる
            if showTutorialSheet {
                TutrialView(isPresented: $showTutorialSheet)
                    .transition(.opacity.animation(.easeInOut)) // オプション: 表示/非表示にアニメーション
            }
        }
        .onAppear {
            Task {
                await cloudViewModel.fetchCloud()
                // loadFavoriteStates() は不要になるか、selectAllStates の初期化に変わる
                initializeLocalStatesFromCloud()
                
                // 初回起動判定
                if !hasLaunchedBefore {
                    showTutorialSheet = true
                }
            }
        }
        .onChange(of: showTutorialSheet) { newValue in // showTutorialSheet の変更を監視
            if !newValue { // チュートリアルが閉じられた (showTutorialSheet が false になった)
                hasLaunchedBefore = true // 次回起動時は表示しないようにフラグを更新
            }
        }
    }
    
    // 特定の科目に対するBindingを生成
    private func subjectBinding(school: String, subject: String) -> Binding<Bool> {
        Binding(
            get: { cloudViewModel.data.favorite[school]?[subject] ?? false },
            set: { newValue in
                if cloudViewModel.data.favorite[school] == nil {
                    cloudViewModel.data.favorite[school] = [:]
                }
                cloudViewModel.data.favorite[school]?[subject] = newValue
                // 全選択トグルの状態も更新 (表示用Bindingのgetが再評価されるように)
                cloudViewModel.objectWillChange.send() // cloudViewModelインスタンス経由で呼び出す
                Task { await cloudViewModel.saveData() }
            }
        )
    }

    // 特定の学校区分の「全選択」トグル用Binding (表示と操作の分離)
    private func selectAllSchoolBinding(for school: String) -> Binding<Bool> {
        Binding(
            get: {
                guard let subjects = cloudViewModel.data.favorite[school],
                      !subjects.isEmpty else { return false }
                return subjects.allSatisfy { $0.value } // 全てtrueならオン
            },
            set: { newValue in
                // このセッターはローカルのselectAllStatesを変更し、onChangeをトリガーする
                selectAllStates[school] = newValue
            }
        )
    }
    
    // CloudViewModelのデータを更新し保存 (全選択トグル操作時)
    private func updateAllSubjectsInCloud(for school: String, selectAll: Bool) {
        guard cloudViewModel.data.favorite[school] != nil else { return }
        var updatedSubjects: [String: Bool] = [:]
        for subjectKey in cloudViewModel.data.favorite[school]!.keys {
            updatedSubjects[subjectKey] = selectAll
        }
        cloudViewModel.data.favorite[school] = updatedSubjects
        Task { await cloudViewModel.saveData() }
        // 表示を即時反映させるために ViewModel の objectWillChange をトリガー
        cloudViewModel.objectWillChange.send()
    }

    // onAppear時やデータ更新時にローカルのStateをCloudから初期化/同期
    private func initializeLocalStatesFromCloud() {
        for schoolKey in schoolKeys {
            // 全選択トグルのローカルStateの初期化 (表示には直接使わないが、onChangeのトリガーのため)
            // selectAllSchoolBindingのgetで表示は決まるので、ここは実質不要かもしれない
            // ただし、ユーザーが全選択トグルを押したときの「意図」を保持するなら意味がある
            if let subjects = cloudViewModel.data.favorite[schoolKey], !subjects.isEmpty {
                selectAllStates[schoolKey] = subjects.allSatisfy { $0.value }
            } else {
                selectAllStates[schoolKey] = false
            }
            // DisclosureGroupの開閉状態は維持、または初期値を設定
            if isSchoolGroupExpanded[schoolKey] == nil { isSchoolGroupExpanded[schoolKey] = false }
        }
        // 必要に応じて全体の科目リストの開閉状態も
        // isLearningExpanded = true (これは現在のまま)
    }
}

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


#Preview {
    HumburgerMenuSampleView()
}
