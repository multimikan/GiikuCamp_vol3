//
//  SampleCameraView.swift
//  GiikuCamp_vol3
//
//  Created by tknooa on 2025/05/20.
//

import SwiftUI
import YOLO

struct CameraView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @State private var showExplanatorySheet = false
    @State private var explanatoryDataList: [[String: String]]? = nil
    @State private var isLoadingExplanation = false
    @State private var currentDetectedObject: String? = nil

    var body: some View {
        ZStack {
            YOLOCamera(
                modelPathOrName: "yolo11n",
                task: .detect,
                cameraPosition: .back,
                onObjectTapped: { objectInfoDict in
                    if let detectedObjectName = objectInfoDict["Name"] {
                        print("Object tapped: \(detectedObjectName) (from dict: \(objectInfoDict))")
                        handleObjectDetection(name: detectedObjectName)
                    } else {
                        print("Tapped object info does not contain 'Name' or it's not a String: \(objectInfoDict)")
                    }
                }
            )
            .ignoresSafeArea()

            if isLoadingExplanation {
                VStack {
                    ProgressView("説明を生成中...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showExplanatorySheet) {
            if let dataList = explanatoryDataList, !dataList.isEmpty {
                if let firstItem = dataList.first, firstItem["error"] != nil {
                    VStack {
                        Text(firstItem["error"] ?? "不明なエラーが発生しました。")
                            .padding()
                        Button("閉じる") {
                            showExplanatorySheet = false
                        }
                        .padding()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(dataList.indices, id: \.self) { index in
                                ExplanatoryView(data: dataList[index])
                                if index < dataList.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                Text("説明を読み込めませんでした。")
            }
        }
    }

    private func prepareExplanatoryData(from result: [[String: String]]?, objectName: String) -> [[String: String]]? {
        guard let result = result, !result.isEmpty else {
            print("Failed to get explanation for \(objectName) or result is empty")
            return [["error": "説明の取得に失敗しました。"]]
        }

        if result.allSatisfy({ $0["error"] != nil }) {
            print("All results are errors for \(objectName)")
            return result.first.map { [$0] } ?? [["error": "不明なエラーで説明を取得できませんでした"]]
        }
        
        let validExplanations = result.filter { $0["error"] == nil }
        
        if validExplanations.isEmpty {
            print("No valid (non-error) explanation found for \(objectName)")
            return result.first(where: {$0["error"] != nil}).map { [$0] } ?? [["error": "有効な説明が見つかりませんでした。"]]
        }
        
        return validExplanations
    }

    private func handleObjectDetection(name: String) {
        guard !name.isEmpty else { return }
        guard currentDetectedObject != name || explanatoryDataList == nil else {
            if explanatoryDataList != nil {
                showExplanatorySheet = true
            }
            return
        }
        
        currentDetectedObject = name
        isLoadingExplanation = true
        explanatoryDataList = nil
        
        Task {
            let result = await chatViewModel.processObjectName(name)
            
            await MainActor.run {
                self.explanatoryDataList = prepareExplanatoryData(from: result, objectName: name)
                self.isLoadingExplanation = false
                if let list = self.explanatoryDataList, !list.isEmpty {
                    self.showExplanatorySheet = true
                }
            }
        }
    }
}
