import SwiftUI
import Combine

// お気に入りの状態などを永続化する場合、ここにStoreの処理などを追加

class ExplanatoryViewModel: ObservableObject {
    // MARK: - Display Data (外部から設定される想定)
    @Published var subject: String
    @Published var level: String
    @Published var unit: String
    @Published var description: String
    @Published var imageName: String? // 表示する画像名（オプショナル）

    // MARK: - State
    @Published var isFavorite: Bool = false // 永続化する場合は初期値をストアから読み込む
    @Published var isSavedForLater: Bool = false // 「後で見る」の状態
    
    // MARK: - Animation State (View側で管理しても良い)
    // @Published var animateHeart: Bool = false 

    // MARK: - Services (Optional - e.g., for API calls or data persistence)
    // private var favoriteService: FavoriteManaging?
    // private var analyticsService: AnalyticsLogging?

    init(subject: String, level: String, unit: String, description: String, imageName: String? = nil, isInitialFavorite: Bool = false) {
        self.subject = subject
        self.level = level
        self.unit = unit
        self.description = description
        self.imageName = imageName
        self.isFavorite = isInitialFavorite // 初期のお気に入り状態を外部から設定可能に
        
        // TODO: 永続化されたお気に入り状態を読み込む処理 (例: UserDefaults, CoreData, APIなど)
        // self.isFavorite = favoriteService.isFavorite(itemID: unit) // itemIDは一意な識別子を想定
    }

    // MARK: - Intents (User Actions)
    func toggleFavorite() {
        isFavorite.toggle()
        // TODO: お気に入り状態の変更を永続化する処理
        // favoriteService.setFavorite(itemID: unit, isFavorite: self.isFavorite)
        // analyticsService.logEvent(name: "toggled_favorite", params: ["item_id": unit, "is_favorite": isFavorite])
    }

    func toggleSaveForLater() {
        isSavedForLater.toggle()
        // TODO: 「後で見る」の状態を永続化したり、関連する処理を実行
    }
    
    func detailedExplanationRequested() {
        // 「AIに詳しく聞いてみる」がタップされたときの処理
        // 例: API呼び出し、ChatViewへの遷移とコンテキスト渡しなど
        print("AIに詳しく聞いてみる requested for: \(unit)")
        // analyticsService.logEvent(name: "ai_explanation_requested", params: ["item_id": unit])
    }
} 