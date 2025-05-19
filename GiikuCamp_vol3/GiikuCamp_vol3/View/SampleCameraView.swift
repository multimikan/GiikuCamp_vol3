//
//  SampleCameraView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/20.
//

import SwiftUI
import YOLO

struct SampleCameraView: View {
    var body: some View {
        YOLOCamera(
            modelPathOrName: "yolo11m-seg",
            task: .segment,
            cameraPosition: .back
        )
        .ignoresSafeArea()
    }
}
