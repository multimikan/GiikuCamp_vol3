import SwiftUI

struct HistoryDetailView: View {
    let item: HistoryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // タイトルセクション
                VStack(alignment: .leading) {
                    Text(item.subject)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(" \(item.object)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)

                Divider()
                Text(item.curriculum)
                        Text(item.deep_description)
                            .font(.body)
                            .padding(.top, 4)
                            .lineSpacing(5)
                Spacer()
            }
            .padding(32)
        }
        .navigationTitle("履歴詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper View for consistent row display
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
        }
    }
}

// Preview
struct HistoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryDetailView(item: HistoryItem(
                docID: "sampleDocID123",
                subject: "物理学",
                object: "リンゴ",
                curriculum: "万有引力",
                description: "リンゴが木から落ちるのを見て、ニュートンは万有引力の法則を発見しました。これは物体同士が引き合う普遍的な力です。",
                deep_description: "万有引力の大きさは、二つの物体の質量の積に比例し、物体間の距離の二乗に反比例します。F = G * (m1*m2)/r^2 という式で表され、Gは万有引力定数です。この法則は、惑星の運動や潮の満ち引きなど、宇宙規模の現象から日常的な現象まで説明することができます。",
                image_url: "https://example.com/sample_image.jpg", // サンプルURL
                color: .blue
            ))
        }
    }
} 
