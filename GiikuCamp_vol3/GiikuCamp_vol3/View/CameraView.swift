//
//  SampleCameraView.swift
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
        .ignoresSafeArea()
    }
}
