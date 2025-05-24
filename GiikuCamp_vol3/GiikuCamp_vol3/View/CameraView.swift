//
//  CameraView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/20.
//

import SwiftUI
import YOLO

struct CameraView: View {
    var body: some View {
        YOLOCamera(
            modelPathOrName: "yolo11n",
            task: .detect,
            cameraPosition: .back
        )
        // TODO: カメラパーミッションの確認とハンドリングを追加検討
        // TODO: YOLOCamera の初期化エラーハンドリングを追加検討
    }
}

// Preview は YOLOCamera がシミュレータで動作しない場合、適切に設定するか #if DEBUG で囲むなど考慮
// #Preview {
//     CameraView()
// }
