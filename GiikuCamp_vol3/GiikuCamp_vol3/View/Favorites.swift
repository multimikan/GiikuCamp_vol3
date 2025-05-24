import SwiftUI

// MARK: - Model
struct FavoriteItem: Identifiable, Equatable {
    let id = UUID()
    let subject: String // 教科
    let grade: String   // 学年（例: "中1", "高2"）
    let unit: String    // 単元名
    let description: String // 説明文
    var color: Color    // 表示用の色（科目ごとに設定するなど）
}

// MARK: - ViewModel
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteItem] = [
        FavoriteItem(subject: "数学", grade: "中1", unit: "文字と式", description: "変数・文字式の考え方など", color: .yellow),
        FavoriteItem(subject: "物理", grade: "高2", unit: "力のつり合い", description: "ニュートンの法則など", color: .blue),
        FavoriteItem(subject: "化学", grade: "中3", unit: "化学変化", description: "物質の変化の基本", color: .green)
    ]
    
    @Published var filterSubject: String? = nil

    var filteredFavorites: [FavoriteItem] {
        if let filter = filterSubject,
           !filter.isEmpty { 
            return favorites.filter { $0.subject == filter }
        } else {
            return favorites
        }
    }

    var availableSubjects: [String] {
        guard !favorites.isEmpty else { return [] }
        return Array(Set(favorites.map { $0.subject })).sorted()
    }

    // TODO: お気に入り状態の永続化処理を実装する (UserDefaults, CoreData, Cloud Firestoreなど)

    func removeFavorite(item: FavoriteItem) {
        if let index = favorites.firstIndex(of: item) {
            favorites.remove(at: index)
            // TODO: 永続化ストレージからも削除する処理を追加
            print("Removed favorite: \(item.unit)")
        } else {
            print("Attempted to remove a non-existent favorite: \(item.unit)")
        }
    }
}

// MARK: - View
struct FavoritesView: View {
    @StateObject var viewModel: FavoritesViewModel 

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                FavoriteFilterView(filterSubject: $viewModel.filterSubject, 
                                   availableSubjects: viewModel.availableSubjects)
                .padding(.horizontal)
                .padding(.top)

                ScrollView {
                    if viewModel.filteredFavorites.isEmpty {
                        if let subject = viewModel.filterSubject {
                            Text("「\(subject)」のお気に入りはありません。")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Text("お気に入り登録された項目はありません。")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredFavorites) { item in
                                FavoriteRow(item: item, onRemove: {
                                    viewModel.removeFavorite(item: item)
                                })
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("お気に入り")
        }
    }
}

struct FavoriteFilterView: View {
    @Binding var filterSubject: String?
    let availableSubjects: [String]

    var body: some View {
        HStack {
            Text("フィルター：")
                .font(.subheadline)
            Picker("フィルター", selection: $filterSubject) {
                Text("すべて").tag(nil as String?)
                ForEach(availableSubjects, id: \.self) { subject in
                    Text(subject).tag(Optional(subject))
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct FavoriteRow: View {
    let item: FavoriteItem
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(item.subject)（\(item.grade)）")
                    .font(.headline)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            Text(item.unit)
                .font(.subheadline)
                .bold()
            Text(item.description)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(item.color.opacity(0.15))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FavoritesView(viewModel: FavoritesViewModel())
}
