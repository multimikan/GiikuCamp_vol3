import SwiftUI
import Combine

class HamburgerMenuViewModel: ObservableObject {
    // MARK: - Menu State
    @Published var isMenuOpen = false
    @Published var selectedScreen = "Home" // 現在選択されている画面（未使用の可能性あり）
    @Published var isSettingsPresented = false

    // MARK: - Learning Section Expansion State
    @Published var isLearningExpanded = true

    // MARK: - Subject Categories
    struct SubjectCategory: Identifiable {
        let id = UUID()
        var name: String
        var systemImage: String
        var isExpanded: Bool
        var subjects: [Subject]
        var isAllSelected: Bool
    }

    struct Subject: Identifiable {
        let id = UUID()
        var name: String
        var isSelected: Bool
    }

    @Published var subjectCategories: [SubjectCategory] = [
        SubjectCategory(
            name: "小学校", systemImage: "graduationcap", isExpanded: false,
            subjects: [
                Subject(name: "算数", isSelected: false), // 「数学」から「算数」へ変更
                Subject(name: "理科", isSelected: false), // 「物理」「化学」「生物」を「理科」へ統合（仮）
                Subject(name: "社会", isSelected: false)
            ],
            isAllSelected: false
        ),
        SubjectCategory(
            name: "中学校", systemImage: "graduationcap", isExpanded: false,
            subjects: [
                Subject(name: "数学", isSelected: false),
                Subject(name: "理科", isSelected: false), // 「物理」「化学」「生物」を「理科」へ統合（仮）
                Subject(name: "社会", isSelected: false),
                Subject(name: "英語", isSelected: false) // 中学校に英語を追加（仮）
            ],
            isAllSelected: false
        ),
        SubjectCategory(
            name: "高校", systemImage: "graduationcap", isExpanded: false,
            subjects: [
                Subject(name: "数学", isSelected: false),
                Subject(name: "物理", isSelected: false),
                Subject(name: "化学", isSelected: false),
                Subject(name: "生物", isSelected: false),
                Subject(name: "地学", isSelected: false), // 高校理科に地学を追加（仮）
                Subject(name: "歴史総合", isSelected: false), // 高校社会を細分化（仮）
                Subject(name: "地理総合", isSelected: false),
                Subject(name: "公共", isSelected: false),
                Subject(name: "英語", isSelected: false) // 高校に英語を追加（仮）
            ],
            isAllSelected: false
        )
    ]
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 各カテゴリの全選択状態と個別科目の選択状態を同期する処理
        // SubjectCategoryのsubjectsやisAllSelectedの変更を監視し、双方向バインディングを実現
        // この初期化ロジックは複雑になるため、段階的に実装するか、よりシンプルな構造を検討します。
        // 現状では、View側でonChangeを使ってViewModelのメソッドを呼び出す形を維持する方がシンプルかもしれません。
    }

    // MARK: - Menu Actions
    func toggleMenu() {
        withAnimation {
            isMenuOpen.toggle()
        }
    }

    func openSettings() {
        if isMenuOpen { // メニューが開いていたら閉じる
            withAnimation {
                isMenuOpen = false
            }
        }
        isSettingsPresented = true
    }

    // MARK: - Subject Selection Logic
    func toggleSelectAll(forCategoryIndex categoryIndex: Int, newValue: Bool) {
        guard subjectCategories.indices.contains(categoryIndex) else { return }
        subjectCategories[categoryIndex].isAllSelected = newValue
        for subjectIndex in subjectCategories[categoryIndex].subjects.indices {
            subjectCategories[categoryIndex].subjects[subjectIndex].isSelected = newValue
        }
    }

    func updateAllSelectedState(forCategoryIndex categoryIndex: Int) {
        guard subjectCategories.indices.contains(categoryIndex) else { return }
        let category = subjectCategories[categoryIndex]
        let allSubjectsSelected = category.subjects.allSatisfy { $0.isSelected }
        if subjectCategories[categoryIndex].isAllSelected != allSubjectsSelected {
             subjectCategories[categoryIndex].isAllSelected = allSubjectsSelected
        }
    }
    
    func toggleSubjectSelection(categoryIndex: Int, subjectIndex: Int) {
        guard subjectCategories.indices.contains(categoryIndex),
              subjectCategories[categoryIndex].subjects.indices.contains(subjectIndex) else { return }
        
        subjectCategories[categoryIndex].subjects[subjectIndex].isSelected.toggle()
        updateAllSelectedState(forCategoryIndex: categoryIndex)
    }
    
    // カテゴリの展開状態をトグルするメソッドを追加
    func toggleCategoryExpansion(forCategoryIndex categoryIndex: Int) {
        guard subjectCategories.indices.contains(categoryIndex) else { return }
        subjectCategories[categoryIndex].isExpanded.toggle()
    }
} 