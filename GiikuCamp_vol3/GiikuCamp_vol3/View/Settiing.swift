//
//  Untitled.swift
//  GiikuCamp_vol3
//
//  Created by SLJ-156 on 2025/05/20.
//

import SwiftUI

struct SettingsSheetView: View {
    @Binding var isSettingsPresented: Bool
    var body: some View {
        NavigationStack {
            VStack{
                Text("設定")
                    .font(.title)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading){
                    Button("閉じる") {
                        isSettingsPresented = false
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var b = true
    SettingsSheetView(isSettingsPresented: $b)
}
