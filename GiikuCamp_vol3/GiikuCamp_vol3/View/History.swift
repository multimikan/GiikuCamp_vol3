import SwiftUI

// モデル
struct FavoriteItem: Identifiable, Equatable {
    let id = UUID()
    let subject: String
    let grade: String
    let unit: String
    let description: String
    var color: Color
}

// ビューモデル
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteItem] = [
        FavoriteItem(subject: "数学", grade: "中1", unit: "文字と式", description: "変数・文字式の考え方など", color: .yellow),
        FavoriteItem(subject: "物理", grade: "高2", unit: "力のつり合い", description: "ニュートンの法則など", color: .blue),
        FavoriteItem(subject: "化学", grade: "中3", unit: "化学変化", description: "物質の変化の基本", color: .green)
    ]
    
    @Published var filterSubject: String? = nil

    var filteredFavorites: [FavoriteItem] {
        if let filter = filterSubject {
            return favorites.filter { $0.subject == filter }
        } else {
            return favorites
        }
    }

    var availableSubjects: [String] {
        Array(Set(favorites.map { $0.subject })).sorted()
    }

    func toggleFavorite(item: FavoriteItem) {
        if let index = favorites.firstIndex(of: item) {
            favorites.remove(at: index)
        }
    }
}

// ビュー
struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("フィルター：")
                        .font(.subheadline)
                    Picker("フィルター", selection: $viewModel.filterSubject) {
                        Text("すべて").tag(nil as String?)
                        ForEach(viewModel.availableSubjects, id: \.self) { subject in
                            Text(subject).tag(Optional(subject))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.top)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredFavorites) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(item.subject)（\(item.grade)）")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        viewModel.toggleFavorite(item: item)
                                    }) {
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
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("お気に入り")
        }
    }
}

#Preview {
    FavoritesView(viewModel: FavoritesViewModel())
}
