import SwiftUI

struct HamburgerMenuSampleView: View {
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

    
    let imageSize:CGFloat = 4
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    Text("\(selectedScreen)画面")
                        .font(.largeTitle)
                        .padding()
                }
                .navigationTitle(selectedScreen)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation {
                                isMenuOpen.toggle()
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isSettingsPresented, content: {
                SettingsSheetView(isSettingsPresented: $isSettingsPresented)
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

//                NavigationLink(destination: ChatView()){
//                    Label("履歴",systemImage: "clock")
//                }
                
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
                        NavigationLink(destination: ChatView()){
                            Label("履歴",systemImage: "clock")
                                .padding(.vertical, 20)
                        }
                    
                        //お気に入り
                        NavigationLink(destination: ChatView()){
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
    HamburgerMenuSampleView()
}
