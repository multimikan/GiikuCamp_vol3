import SwiftUI

struct HumburgerMenuSampleView: View {
    @State private var isMenuOpen = false
    @State private var selectedScreen = "Home"
    @State private var isSettingsPresented = false
    
    // 教科の選択状態
    @State private var isMathSelected = false
    @State private var isPhysicsSelected = false
    @State private var isChemistrySelected = false
    @State private var isBiologySelected = false
    @State private var isSocialSelected = false
    
    // DisclosureGroup の開閉状態管理
    @State private var isLearningExpanded = true
    @State private var isElementaryExpanded = false
    @State private var isJuniorExpanded = false
    @State private var isHighExpanded = false
    
    // 全選択トグル
    @State private var isElementaryAllSelected = false
    @State private var isJuniorAllSelected = false
    @State private var isHighAllSelected = false

    // 小学校・中学・高校の科目チェック状態
    @State private var isElementaryMathSelected = false
    @State private var isElementaryPhysicsSelected = false
    @State private var isElementaryChemistrySelected = false
    @State private var isElementaryBiologySelected = false
    @State private var isElementarySocialSelected = false

    @State private var isJuniorMathSelected = false
    @State private var isJuniorPhysicsSelected = false
    @State private var isJuniorChemistrySelected = false
    @State private var isJuniorBiologySelected = false
    @State private var isJuniorSocialSelected = false

    @State private var isHighMathSelected = false
    @State private var isHighPhysicsSelected = false
    @State private var isHighChemistrySelected = false
    @State private var isHighBiologySelected = false
    @State private var isHighSocialSelected = false

    // ChatViewModel を @StateObject として保持
    // CloudViewModelの初期化は適切に行う必要があります。
    // ここでは仮にデフォルトイニシャライザを呼び出していますが、
    // 実際のCloudViewModelの定義に合わせてください。
    @StateObject private var cloudViewModel = CloudViewModel() // 仮の初期化
    @StateObject private var chatViewModel: ChatViewModel

    let imageSize:CGFloat = 4
    
    // ChatViewModelの初期化をinitで行う
    init() {
        let cvm = CloudViewModel() // CloudViewModelを初期化
        _cloudViewModel = StateObject(wrappedValue: cvm) // cloudViewModelをStateObjectとして初期化
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(cloudViewModel: cvm))
    }
    
    var body: some View {
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
                                    .frame(width: 64, height: 64)
                                
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
            .environmentObject(chatViewModel) // chatViewModel を環境に設定
            .fullScreenCover(isPresented: $isSettingsPresented, content: {
                SettingsSheetView(isSettingsPresented: $isSettingsPresented)
                    .environmentObject(chatViewModel) // SettingsSheetViewにも渡す
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

//                NavigationLink(destination: ChatView()){ // ChatViewにも必要なら渡す
//                    Label("履歴",systemImage: "clock")
//                }
//                .environmentObject(chatViewModel)
                
                HStack {
                    Spacer()
                    List {
                        DisclosureGroup(
                            isExpanded: $isLearningExpanded){
                            // 小学校
                            DisclosureGroup(isExpanded: $isElementaryExpanded){
                                Toggle("数学", isOn: $isElementaryMathSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("物理", isOn: $isElementaryPhysicsSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("化学", isOn: $isElementaryChemistrySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("生物", isOn: $isElementaryBiologySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("社会", isOn: $isElementarySocialSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                            } label: {
                                Toggle(isOn: $isElementaryAllSelected) {
                                    Label("小学校", systemImage: "graduationcap")
                                }.toggleStyle(CheckBoxToggleStyle())
                            }
                            .onChange(of: isElementaryAllSelected) { newValue in
                                isElementaryMathSelected = newValue
                                isElementaryPhysicsSelected = newValue
                                isElementaryChemistrySelected = newValue
                                isElementaryBiologySelected = newValue
                                isElementarySocialSelected = newValue
                            }
                            .onChange(of: [
                                isElementaryMathSelected,
                                isElementaryPhysicsSelected,
                                isElementaryChemistrySelected,
                                isElementaryBiologySelected,
                                isElementarySocialSelected
                            ]) { _ in
                                isElementaryAllSelected =
                                    isElementaryMathSelected &&
                                    isElementaryPhysicsSelected &&
                                    isElementaryChemistrySelected &&
                                    isElementaryBiologySelected &&
                                    isElementarySocialSelected
                            }
                            
                            //  中学校
                            DisclosureGroup(isExpanded: $isJuniorExpanded){
                                Toggle("数学", isOn: $isJuniorMathSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("物理", isOn: $isJuniorPhysicsSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("化学", isOn: $isJuniorChemistrySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("生物", isOn: $isJuniorBiologySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("社会", isOn: $isJuniorSocialSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                            } label: {
                                Toggle(isOn: $isJuniorAllSelected) {
                                    Label("中学校", systemImage: "graduationcap")
                                }.toggleStyle(CheckBoxToggleStyle())
                            }
                            .onChange(of: isJuniorAllSelected) { newValue in
                                isJuniorMathSelected = newValue
                                isJuniorPhysicsSelected = newValue
                                isJuniorChemistrySelected = newValue
                                isJuniorBiologySelected = newValue
                                isJuniorSocialSelected = newValue
                            }
                            .onChange(of: [
                                isJuniorMathSelected,
                                isJuniorPhysicsSelected,
                                isJuniorChemistrySelected,
                                isJuniorBiologySelected,
                                isJuniorSocialSelected
                            ]) { _ in
                                isJuniorAllSelected =
                                    isJuniorMathSelected &&
                                    isJuniorPhysicsSelected &&
                                    isJuniorChemistrySelected &&
                                    isJuniorBiologySelected &&
                                    isJuniorSocialSelected
                            }
                            
                            // 高校
                            DisclosureGroup(isExpanded: $isHighExpanded){
                                Toggle("数学", isOn: $isHighMathSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("物理", isOn: $isHighPhysicsSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("化学", isOn: $isHighChemistrySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("生物", isOn: $isHighBiologySelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                                Toggle("社会", isOn: $isHighSocialSelected)
                                    .toggleStyle(CheckBoxToggleStyle())
                            } label: {
                                Toggle(isOn: $isHighAllSelected) {
                                    Label("高校", systemImage: "graduationcap")
                                }.toggleStyle(CheckBoxToggleStyle())
                            }
                            .onChange(of: isHighAllSelected) { newValue in
                                isHighMathSelected = newValue
                                isHighPhysicsSelected = newValue
                                isHighChemistrySelected = newValue
                                isHighBiologySelected = newValue
                                isHighSocialSelected = newValue
                            }
                            .onChange(of: [
                                isHighMathSelected,
                                isHighPhysicsSelected,
                                isHighChemistrySelected,
                                isHighBiologySelected,
                                isHighSocialSelected
                            ]) { _ in
                                isHighAllSelected =
                                    isHighMathSelected &&
                                    isHighPhysicsSelected &&
                                    isHighChemistrySelected &&
                                    isHighBiologySelected &&
                                    isHighSocialSelected
                            }
    


                            }label:{
                                Label("科目",systemImage: "clock")
                                .padding(.vertical, 20)}
                        
                        //履歴
                        NavigationLink(destination: ChatView().environmentObject(chatViewModel)){ // ChatViewに渡す
                            Label("履歴",systemImage: "clock")
                                .padding(.vertical, 20)
                        }
                    
                        //お気に入り
                        NavigationLink(destination: ChatView().environmentObject(chatViewModel)){ // ChatViewに渡す
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
        
        
        //    func menuLabel(_ text: String, systemImage: String)->some View{
        //        return HStack{
        //            Image(systemName: systemName).frame(width: imageSize)
        //                .padding(.horizontal)
        //            Text(text).font(.headline)        }
        //    }
        //}
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
