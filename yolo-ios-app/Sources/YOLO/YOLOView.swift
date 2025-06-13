// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

//  This file is part of the Ultralytics YOLO Package, providing the core UI component for real-time object detection.
//  Licensed under AGPL-3.0. For commercial use, refer to Ultralytics licensing: https://ultralytics.com/license
//  Access the source code: https://github.com/ultralytics/yolo-ios-app
//
//  The YOLOView class is the primary UI component for displaying real-time YOLO model results.
//  It handles camera setup, model loading, video frame processing, rendering of detection results,
//  and user interactions such as pinch-to-zoom. The view can display bounding boxes, masks for segmentation,
//  pose estimation keypoints, and oriented bounding boxes depending on the active task. It includes
//  UI elements for controlling inference settings such as confidence threshold and IoU threshold,
//  and provides functionality for capturing photos with detection results overlaid.

import AVFoundation
import UIKit
import Vision
// import SwiftUI // SwiftUIは必要ないのでコメントアウトまたは削除

/// YOLOView Delegate Protocol - Provides performance metrics and YOLO results for each frame
public protocol YOLOViewDelegate: AnyObject {
  /// Called when performance metrics (FPS and inference time) are updated
  func yoloView(_ view: YOLOView, didUpdatePerformance fps: Double, inferenceTime: Double)

  /// Called when detection results are available
  func yoloView(_ view: YOLOView, didReceiveResult result: YOLOResult)

}

/// A UIView component that provides real-time object detection, segmentation, and pose estimation capabilities.
@MainActor
public class YOLOView: UIView, VideoCaptureDelegate {

  /// Delegate object - Receives performance metrics and YOLO detection results
  public weak var delegate: YOLOViewDelegate?

  // SwiftUIベースのコードをコメントアウトまたは削除
  // private var bubbleAnimationViewControllers: [String: UIHostingController<BubbleAnimationView>] = [:]
  
  // CALayerベースのアニメーションレイヤー管理用
  private var bubbleAnimationLayers: [String: BubbleAnimationLayer] = [:]
  private var activeObjectIDs: Set<String> = [] // 現在表示中のオブジェクトIDを管理
  private var lastAnimationTimes: [String: TimeInterval] = [:] // 各オブジェクトの最後のアニメーション生成時間
  private var lastGlobalAnimationTime: TimeInterval = 0 // 全体での最後のアニメーション生成時間

  // アニメーション制限設定
  private let minAnimationInterval: TimeInterval = 0.5 // 同一オブジェクトの連続アニメーション最小間隔（秒）
  private let minGlobalAnimationInterval: TimeInterval = 0.1 // 全体での連続アニメーション最小間隔（秒）
  private let maxConcurrentAnimations: Int = 5 // 同時に表示する最大アニメーション数

  // アニメーションを持続させる時間（秒）
  private let animationPersistenceDuration: TimeInterval = 0.8 // 1.5秒から0.8秒に短縮
  // 最後に検出された時刻を保持する辞書
  private var lastSeenTimes: [String: TimeInterval] = [:]

  // 最新の検出結果を保持
  private var lastYOLOResult: YOLOResult?
  private var lastTapHandledTime: TimeInterval = 0 // タップ処理の最終実行時刻
  private let minTapInterval: TimeInterval = 0.5 // タップ処理の最小間隔（秒）

  /// Callback for when an object is tapped. Provides a dictionary with object information.
  public var onObjectTapped: (([String: String]) -> Void)?

  func onInferenceTime(speed: Double, fps: Double) {
    DispatchQueue.main.async {
      // self.labelFPS.text = String(format: "%.1f FPS - %.1f ms", fps, speed)  // t2 seconds to ms
      // Notify delegate of performance metrics

      self.delegate?.yoloView(self, didUpdatePerformance: fps, inferenceTime: speed)
    }
  }

  func onPredict(result: YOLOResult) {
    self.lastYOLOResult = result // 最新の検出結果を保存
    // Notify delegate of detection results
    delegate?.yoloView(self, didReceiveResult: result)

    showBoxes(predictions: result)
    onDetection?(result)

    if task == .segment {
      DispatchQueue.main.async {
        if let maskImage = result.masks?.combinedMask {

          guard let maskLayer = self.maskLayer else { return }

          maskLayer.isHidden = false
          maskLayer.frame = self.overlayLayer.bounds
          maskLayer.contents = maskImage

          self.videoCapture.predictor.isUpdating = false
        } else {
          self.videoCapture.predictor.isUpdating = false
        }
      }
    } else if task == .classify {
      self.overlayYOLOClassificationsCALayer(on: self, result: result)
    } else if task == .pose {
      self.removeAllSubLayers(parentLayer: poseLayer)
      var keypointList = [[(x: Float, y: Float)]]()
      var confsList = [[Float]]()

      for keypoint in result.keypointsList {
        keypointList.append(keypoint.xyn)
        confsList.append(keypoint.conf)
      }
      guard let poseLayer = poseLayer else { return }
      drawKeypoints(
        keypointsList: keypointList, confsList: confsList, boundingBoxes: result.boxes,
        on: poseLayer, imageViewSize: overlayLayer.frame.size, originalImageSize: result.orig_shape)
    } else if task == .obb {
      //            self.setupObbLayerIfNeeded()
      guard let obbLayer = self.obbLayer else { return }
      let obbDetections = result.obb
      self.obbRenderer.drawObbDetectionsWithReuse(
        obbDetections: obbDetections,
        on: obbLayer,
        imageViewSize: self.overlayLayer.frame.size,
        originalImageSize: result.orig_shape,  // 例
        lineWidth: 3
      )
    }
  }

  var onDetection: ((YOLOResult) -> Void)?
  private var videoCapture: VideoCapture
  private var busy = false
  private var currentBuffer: CVPixelBuffer?
  var framesDone = 0
  var t0 = 0.0  // inference start
  var t1 = 0.0  // inference dt
  var t2 = 0.0  // inference dt smoothed
  var t3 = CACurrentMediaTime()  // FPS start
  var t4 = 0.0  // FPS dt smoothed
  var task = YOLOTask.detect
  var colors: [String: UIColor] = [:]
  var modelName: String = ""
  var classes: [String] = []
  let maxBoundingBoxViews = 100
  var boundingBoxViews = [BoundingBoxView]()
  public var activityIndicator = UIActivityIndicatorView()
  let selection = UISelectionFeedbackGenerator()
  private var overlayLayer = CALayer()
  private var maskLayer: CALayer?
  private var poseLayer: CALayer?
  private var obbLayer: CALayer?

  let obbRenderer = OBBRenderer()

  private let minimumZoom: CGFloat = 1.0
  private let maximumZoom: CGFloat = 10.0
  private var lastZoomFactor: CGFloat = 1.0

  public var capturedImage: UIImage?
  private var photoCaptureCompletion: ((UIImage?) -> Void)?

  public init(
    frame: CGRect,
    modelPathOrName: String,
    task: YOLOTask
  ) {
    self.videoCapture = VideoCapture()
    super.init(frame: frame)
    setModel(modelPathOrName: modelPathOrName, task: task)
    setUpOrientationChangeNotification()
    self.setUpBoundingBoxViews()
    self.setupUI()
    self.videoCapture.delegate = self
    start(position: .back)
    setupOverlayLayer()
    addTapGestureRecognizer()
  }

  required init?(coder: NSCoder) {
    self.videoCapture = VideoCapture()
    super.init(coder: coder)
  }

  public override func awakeFromNib() {
    super.awakeFromNib()
    Task { @MainActor in
      setUpOrientationChangeNotification()
      setUpBoundingBoxViews()
      setupUI()
      videoCapture.delegate = self
      start(position: .back)
      setupOverlayLayer()
      addTapGestureRecognizer()
    }
  }

  public func setModel(
    modelPathOrName: String,
    task: YOLOTask,
    completion: ((Result<Void, Error>) -> Void)? = nil
  ) {
    activityIndicator.startAnimating()
    boundingBoxViews.forEach { box in
      box.hide()
    }
    removeClassificationLayers()

    self.task = task
    setupSublayers()

    var modelURL: URL?
    let lowercasedPath = modelPathOrName.lowercased()
    let fileManager = FileManager.default

    // Determine model URL
    if lowercasedPath.hasSuffix(".mlmodel") || lowercasedPath.hasSuffix(".mlpackage")
      || lowercasedPath.hasSuffix(".mlmodelc")
    {
      let possibleURL = URL(fileURLWithPath: modelPathOrName)
      if fileManager.fileExists(atPath: possibleURL.path) {
        modelURL = possibleURL
      }
    } else {
      if let compiledURL = Bundle.main.url(forResource: modelPathOrName, withExtension: "mlmodelc")
      {
        modelURL = compiledURL
      } else if let packageURL = Bundle.main.url(
        forResource: modelPathOrName, withExtension: "mlpackage")
      {
        modelURL = packageURL
      }
    }

    guard let unwrappedModelURL = modelURL else {
      let error = PredictorError.modelFileNotFound
      fatalError(error.localizedDescription)
    }

    modelName = unwrappedModelURL.deletingPathExtension().lastPathComponent

    // Common success handling for all tasks
    func handleSuccess(predictor: Predictor) {
      self.videoCapture.predictor = predictor
      self.activityIndicator.stopAnimating()

      // 固定値を設定
      if let objectDetector = predictor as? ObjectDetector {
        objectDetector.setConfidenceThreshold(confidence: 0.8)
        objectDetector.setIouThreshold(iou: 1.0)
      }
      completion?(.success(()))
    }

    // Common failure handling for all tasks
    func handleFailure(_ error: Error) {
      print("Failed to load model with error: \(error)")
      self.activityIndicator.stopAnimating()
      completion?(.failure(error))
    }

    switch task {
    case .classify:
      Classifier.create(unwrappedModelURL: unwrappedModelURL, isRealTime: true) {
        [weak self] result in
        switch result {
        case .success(let predictor):
          handleSuccess(predictor: predictor)
        case .failure(let error):
          handleFailure(error)
        }
      }

    case .segment:
      Segmenter.create(unwrappedModelURL: unwrappedModelURL, isRealTime: true) {
        [weak self] result in
        switch result {
        case .success(let predictor):
          handleSuccess(predictor: predictor)
        case .failure(let error):
          handleFailure(error)
        }
      }

    case .pose:
      PoseEstimater.create(unwrappedModelURL: unwrappedModelURL, isRealTime: true) {
        [weak self] result in
        switch result {
        case .success(let predictor):
          handleSuccess(predictor: predictor)
        case .failure(let error):
          handleFailure(error)
        }
      }

    case .obb:
      ObbDetector.create(unwrappedModelURL: unwrappedModelURL, isRealTime: true) {
        [weak self] result in
        switch result {
        case .success(let predictor):
          self?.obbLayer?.isHidden = false

          handleSuccess(predictor: predictor)
        case .failure(let error):
          handleFailure(error)
        }
      }

    default:
      ObjectDetector.create(unwrappedModelURL: unwrappedModelURL, isRealTime: true) {
        [weak self] result in
        switch result {
        case .success(let predictor):
          handleSuccess(predictor: predictor)
        case .failure(let error):
          handleFailure(error)
        }
      }
    }
  }

  private func start(position: AVCaptureDevice.Position) {
    if !busy {
      busy = true
      let orientation = UIDevice.current.orientation
      videoCapture.setUp(sessionPreset: .photo, position: position, orientation: orientation) {
        success in
        // .hd4K3840x2160 or .photo (4032x3024)  Warning: 4k may not work on all devices i.e. 2019 iPod
        if success {
          // Add the video preview into the UI.
          if let previewLayer = self.videoCapture.previewLayer {
            self.layer.insertSublayer(previewLayer, at: 0)
            self.videoCapture.previewLayer?.frame = self.bounds  // resize preview layer
            for box in self.boundingBoxViews {
              box.addToLayer(previewLayer)
            }
          }
          self.videoCapture.previewLayer?.addSublayer(self.overlayLayer)
          // Once everything is set up, we can start capturing live video.
          self.videoCapture.start()

          self.busy = false
        }
      }
    }
  }

  public func stop() {
    videoCapture.stop()
  }

  public func resume() {
    videoCapture.start()
  }

  func setUpBoundingBoxViews() {
    // Ensure all bounding box views are initialized up to the maximum allowed.
    while boundingBoxViews.count < maxBoundingBoxViews {
      boundingBoxViews.append(BoundingBoxView())
    }

  }

  func setupOverlayLayer() {
    let width = self.bounds.width
    let height = self.bounds.height

    var ratio: CGFloat = 1.0
    if videoCapture.captureSession.sessionPreset == .photo {
      ratio = (4.0 / 3.0)
    } else {
      ratio = (16.0 / 9.0)
    }
    var offSet = CGFloat.zero
    var margin = CGFloat.zero
    if self.bounds.width < self.bounds.height {
      offSet = height / ratio
      margin = (offSet - self.bounds.width) / 2
      self.overlayLayer.frame = CGRect(
        x: -margin, y: 0, width: offSet, height: self.bounds.height)
    } else {
      offSet = width / ratio
      margin = (offSet - self.bounds.height) / 2
      self.overlayLayer.frame = CGRect(
        x: 0, y: -margin, width: self.bounds.width, height: offSet)
    }
  }

  func setupMaskLayerIfNeeded() {
    if maskLayer == nil {
      let layer = CALayer()
      layer.frame = self.overlayLayer.bounds
      layer.opacity = 0.5
      layer.name = "maskLayer"
      // Specify contentsGravity or backgroundColor as needed
      // layer.contentsGravity = .resizeAspectFill
      // layer.backgroundColor = UIColor.clear.cgColor

      self.overlayLayer.addSublayer(layer)
      self.maskLayer = layer
    }
  }

  func setupPoseLayerIfNeeded() {
    if poseLayer == nil {
      let layer = CALayer()
      layer.frame = self.overlayLayer.bounds
      layer.opacity = 0.5
      self.overlayLayer.addSublayer(layer)
      self.poseLayer = layer
    }
  }

  func setupObbLayerIfNeeded() {
    if obbLayer == nil {
      let layer = CALayer()
      layer.frame = self.overlayLayer.bounds
      layer.opacity = 0.5
      self.overlayLayer.addSublayer(layer)
      self.obbLayer = layer
    }
  }

  public func resetLayers() {
    removeAllSubLayers(parentLayer: maskLayer)
    removeAllSubLayers(parentLayer: poseLayer)
    removeAllSubLayers(parentLayer: overlayLayer)

    maskLayer = nil
    poseLayer = nil
    obbLayer?.isHidden = true
  }

  func setupSublayers() {
    resetLayers()

    switch task {
    case .segment:
      setupMaskLayerIfNeeded()
    case .pose:
      setupPoseLayerIfNeeded()
    case .obb:
      setupObbLayerIfNeeded()
      overlayLayer.addSublayer(obbLayer!)
      obbLayer?.isHidden = false
    default: break
    }
  }

  func removeAllSubLayers(parentLayer: CALayer?) {
    guard let parentLayer = parentLayer else { return }
    parentLayer.sublayers?.forEach { layer in
      layer.removeFromSuperlayer()
    }
    parentLayer.sublayers = nil
    parentLayer.contents = nil
  }

  func addMaskSubLayers() {
    guard let maskLayer = maskLayer else { return }
    self.overlayLayer.addSublayer(maskLayer)
  }

  func showBoxes(predictions: YOLOResult) {
    let currentTime = CACurrentMediaTime()

    // 現在のフレームで検出されたオブジェクトIDのセット
    let detectedObjectIDsThisFrame: Set<String> = Set(predictions.boxes.map { "\($0.cls)_\($0.index)" })

    // 1. 検出されなくなった（かつアニメーションが表示されている）レイヤーの処理
    let disappearedObjectIDs = activeObjectIDs.subtracting(detectedObjectIDsThisFrame)
    for id in disappearedObjectIDs {
        if let lastSeen = lastSeenTimes[id] {
            if currentTime - lastSeen > animationPersistenceDuration {
                if let layer = bubbleAnimationLayers.removeValue(forKey: id) {
                    // layer.removeFromSuperlayer() // BubbleAnimationLayerの自己削除に任せるか、明示的に呼ぶ
                    layer.stopAllBubblesAndRemove() // 新しいメソッドを呼ぶ
                }
                lastSeenTimes.removeValue(forKey: id)
                activeObjectIDs.remove(id) // activeからも削除
                lastAnimationTimes.removeValue(forKey: id)
            } else {
                // まだ持続時間内の場合は何もしない（表示し続ける）
            }
        } else {
            // lastSeenTimeがない場合（通常発生しないはずだが念のため）
            if let layer = bubbleAnimationLayers.removeValue(forKey: id) {
                layer.stopAllBubblesAndRemove()
            }
            activeObjectIDs.remove(id)
            lastAnimationTimes.removeValue(forKey: id)
        }
    }
    
    // 2. 検出されたオブジェクトの処理 (新規または既存)
    let sortedBoxes = predictions.boxes.sorted { $0.conf > $1.conf }
    var processedCount = 0
    
    for box in sortedBoxes {
        if processedCount >= maxConcurrentAnimations && !bubbleAnimationLayers.keys.contains("\(box.cls)_\(box.index)") {
            continue // 上限を超えていて、かつ既存のアニメーションでもない場合はスキップ
        }
        processObject(box: box, currentTime: currentTime)
        if bubbleAnimationLayers.keys.contains("\(box.cls)_\(box.index)") {
             processedCount += 1
        }
    }
    
    // 3. activeObjectIDsを現在のフレームのIDで更新 (重要: processObjectの後)
    // activeObjectIDs は「現在アニメーション処理の対象となっているID」を指すようにする
    // ただし、持続表示されているものも含むため、単純な上書きではない。
    // processObjectで新規追加されたものと、まだ持続しているものを合わせる。
    // この部分は少し複雑になるので、まずはprocessObjectでactiveObjectIDsを更新する形にする。
    // activeObjectIDs = detectedObjectIDsThisFrame // これは単純すぎる

    // 全ての既存のboundingBoxViewを非表示にする (これは元の処理)
    for i in 0..<boundingBoxViews.count {
        boundingBoxViews[i].hide()
    }
  }

  private func processObject(box: Box, currentTime: TimeInterval) {
    let objectID = "\(box.cls)_\(box.index)"

    lastSeenTimes[objectID] = currentTime // 最後に検出された時刻を更新
    activeObjectIDs.insert(objectID) //アクティブIDセットに追加 (または更新)

    let normalizedCenterX = box.xywhn.origin.x + box.xywhn.size.width / 2
    let normalizedCenterY = box.xywhn.origin.y + box.xywhn.size.height / 2

    let normalizedRectForConversion = CGRect(x: normalizedCenterX - 0.01, y: normalizedCenterY - 0.01, width: 0.02, height: 0.02)
    let viewRect = VNImageRectForNormalizedRect(normalizedRectForConversion, Int(overlayLayer.bounds.width), Int(overlayLayer.bounds.height))
    let viewCenterX = viewRect.midX
    let viewCenterY = viewRect.midY
    
    if let existingLayer = bubbleAnimationLayers[objectID] {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        existingLayer.position = CGPoint(x: viewCenterX, y: viewCenterY)
        CATransaction.commit()
    } else {
        if bubbleAnimationLayers.count >= maxConcurrentAnimations {
            return // 新規作成は上限数を超えていたら行わない
        }
        
        let lastTimeForThisObject = lastAnimationTimes[objectID] ?? 0
        if currentTime - lastTimeForThisObject < minAnimationInterval {
            return
        }
        
        if currentTime - lastGlobalAnimationTime < minGlobalAnimationInterval && bubbleAnimationLayers.count > 0 {
             // 既にいくつかアニメーションがある場合はグローバル間隔も考慮
            return
        }
        
        let animationLayer = BubbleAnimationLayer()
        animationLayer.position = CGPoint(x: viewCenterX, y: viewCenterY)
        animationLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.overlayLayer.addSublayer(animationLayer)
        bubbleAnimationLayers[objectID] = animationLayer
        
        lastAnimationTimes[objectID] = currentTime
        if bubbleAnimationLayers.count > 0 { // 実際にアニメーションが追加されたらグローバルタイムを更新
            lastGlobalAnimationTime = currentTime
        }
    }
  }

  func removeClassificationLayers() {
    if let sublayers = self.layer.sublayers {
      for layer in sublayers where layer.name == "YOLOOverlayLayer" {
        layer.removeFromSuperlayer()
      }
    }
  }

  func overlayYOLOClassificationsCALayer(on view: UIView, result: YOLOResult) {

    removeClassificationLayers()

    let overlayLayer = CALayer()
    overlayLayer.frame = view.bounds
    overlayLayer.name = "YOLOOverlayLayer"

    guard let top1 = result.probs?.top1,
      let top1Conf = result.probs?.top1Conf
    else {
      return
    }

    var colorIndex = 0
    if let index = result.names.firstIndex(of: top1) {
      colorIndex = index % ultralyticsColors.count
    }
    let color = ultralyticsColors[colorIndex]

    let confidencePercent = round(top1Conf * 1000) / 10
    let labelText = " \(top1) \(confidencePercent)% "

    let textLayer = CATextLayer()
    textLayer.contentsScale = UIScreen.main.scale  // Retina対応
    textLayer.alignmentMode = .left
    let fontSize = self.bounds.height * 0.02
    textLayer.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    textLayer.fontSize = fontSize
    textLayer.foregroundColor = UIColor.white.cgColor
    textLayer.backgroundColor = color.cgColor
    textLayer.cornerRadius = 4
    textLayer.masksToBounds = true

    textLayer.string = labelText
    let textAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    ]
    let textSize = (labelText as NSString).size(withAttributes: textAttributes)
    let width: CGFloat = textSize.width + 10
    let x: CGFloat = self.center.x - (width / 2)
    let y: CGFloat = self.center.y - textSize.height
    let height: CGFloat = textSize.height + 4

    textLayer.frame = CGRect(x: x, y: y, width: width, height: height)

    overlayLayer.addSublayer(textLayer)

    view.layer.addSublayer(overlayLayer)
  }

  private func setupUI() {
    // labelName.text = processString(modelName)
    // labelName.textAlignment = .center
    // labelName.font = UIFont.systemFont(ofSize: 24, weight: .medium)
    // labelName.textColor = .white
    // labelName.font = UIFont.preferredFont(forTextStyle: .title1)
    // self.addSubview(labelName)

    // labelFPS.text = String(format: "%.1f FPS - %.1f ms", 0.0, 0.0)
    // labelFPS.textAlignment = .center
    // labelFPS.textColor = .white
    // labelFPS.font = UIFont.preferredFont(forTextStyle: .body)
    // self.addSubview(labelFPS)

    // labelSliderNumItems.text = "0 items (max 30)"
    // labelSliderNumItems.textAlignment = .left
    // labelSliderNumItems.textColor = .white
    // labelSliderNumItems.font = UIFont.preferredFont(forTextStyle: .subheadline)
    // self.addSubview(labelSliderNumItems)

    // sliderNumItems.minimumValue = 0
    // sliderNumItems.maximumValue = 100
    // sliderNumItems.value = 30
    // sliderNumItems.minimumTrackTintColor = .white
    // sliderNumItems.maximumTrackTintColor = .systemGray.withAlphaComponent(0.7)
    // sliderNumItems.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    // self.addSubview(sliderNumItems)

    // labelSliderConf.text = "0.25 Confidence Threshold"
    // labelSliderConf.textAlignment = .left
    // labelSliderConf.textColor = .white
    // labelSliderConf.font = UIFont.preferredFont(forTextStyle: .subheadline)
    // self.addSubview(labelSliderConf)

    // sliderConf.minimumValue = 0
    // sliderConf.maximumValue = 1
    // sliderConf.value = 0.25
    // sliderConf.minimumTrackTintColor = .white
    // sliderConf.maximumTrackTintColor = .systemGray.withAlphaComponent(0.7)
    // sliderConf.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    // self.addSubview(sliderConf)

    // labelSliderIoU.text = "0.45 IoU Threshold"
    // labelSliderIoU.textAlignment = .left
    // labelSliderIoU.textColor = .white
    // labelSliderIoU.font = UIFont.preferredFont(forTextStyle: .subheadline)
    // self.addSubview(labelSliderIoU)

    // sliderIoU.minimumValue = 0
    // sliderIoU.maximumValue = 1
    // sliderIoU.value = 0.45
    // sliderIoU.minimumTrackTintColor = .white
    // sliderIoU.maximumTrackTintColor = .systemGray.withAlphaComponent(0.7)
    // sliderIoU.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    // self.addSubview(sliderIoU)

    // self.labelSliderNumItems.text = "0 items (max " + String(Int(sliderNumItems.value)) + ")"
    // self.labelSliderConf.text = "0.25 Confidence Threshold"
    // self.labelSliderIoU.text = "0.45 IoU Threshold"

    // labelZoom.text = "1.00x"
    // labelZoom.textColor = .white
    // labelZoom.font = UIFont.systemFont(ofSize: 14)
    // labelZoom.textAlignment = .center
    // labelZoom.font = UIFont.preferredFont(forTextStyle: .body)
    // self.addSubview(labelZoom)

    // let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)

    // playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
    // playButton.tintColor = .white
    // pauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
    // pauseButton.tintColor = .white
    // switchCameraButton = UIButton()
    // switchCameraButton.setImage(
    //   UIImage(systemName: "camera.rotate", withConfiguration: config), for: .normal)
    // switchCameraButton.tintColor = .white
    // playButton.isEnabled = false
    // pauseButton.isEnabled = true
    // playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    // pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
    // switchCameraButton.addTarget(self, action: #selector(switchCameraTapped), for: .touchUpInside)
    // toolbar.backgroundColor = .black.withAlphaComponent(0.7)
    // self.addSubview(toolbar)
    // toolbar.addSubview(playButton)
    // toolbar.addSubview(pauseButton)
    // toolbar.addSubview(switchCameraButton)

    self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinch)))
  }

  public override func layoutSubviews() {
    setupOverlayLayer()
    let isLandscape = bounds.width > bounds.height
    activityIndicator.frame = CGRect(x: center.x - 50, y: center.y - 50, width: 100, height: 100)
    if isLandscape {
      // toolbar.backgroundColor = .black.withAlphaComponent(0.7)
      // playButton.tintColor = .white
      // pauseButton.tintColor = .white
      // switchCameraButton.tintColor = .white

      // let width = bounds.width
      // let height = bounds.height

      // let topMargin: CGFloat = 0

      // let titleLabelHeight: CGFloat = height * 0.1
      // labelName.frame = CGRect(
      //   x: 0,
      //   y: topMargin,
      //   width: width,
      //   height: titleLabelHeight
      // )

      // let subLabelHeight: CGFloat = height * 0.04
      // labelFPS.frame = CGRect(
      //   x: 0,
      //   y: center.y - height * 0.24 - subLabelHeight,
      //   width: width,
      //   height: subLabelHeight
      // )

      // let sliderWidth: CGFloat = width * 0.2
      // let sliderHeight: CGFloat = height * 0.1

      // labelSliderNumItems.frame = CGRect(
      //   x: width * 0.1,
      //   y: labelFPS.frame.minY - sliderHeight,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // sliderNumItems.frame = CGRect(
      //   x: width * 0.1,
      //   y: labelSliderNumItems.frame.maxY + 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // labelSliderConf.frame = CGRect(
      //   x: width * 0.1,
      //   y: sliderNumItems.frame.maxY + 10,
      //   width: sliderWidth * 1.5,
      //   height: sliderHeight
      // )

      // sliderConf.frame = CGRect(
      //   x: width * 0.1,
      //   y: labelSliderConf.frame.maxY + 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // labelSliderIoU.frame = CGRect(
      //   x: width * 0.1,
      //   y: sliderConf.frame.maxY + 10,
      //   width: sliderWidth * 1.5,
      //   height: sliderHeight
      // )

      // sliderIoU.frame = CGRect(
      //   x: width * 0.1,
      //   y: labelSliderIoU.frame.maxY + 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // let zoomLabelWidth: CGFloat = width * 0.2
      // labelZoom.frame = CGRect(
      //   x: center.x - zoomLabelWidth / 2,
      //   y: self.bounds.maxY - 120,
      //   width: zoomLabelWidth,
      //   height: height * 0.03
      // )

      // let toolBarHeight: CGFloat = 66
      // let buttonHeihgt: CGFloat = toolBarHeight * 0.75
      // toolbar.frame = CGRect(x: 0, y: height - toolBarHeight, width: width, height: toolBarHeight)
      // playButton.frame = CGRect(x: 0, y: 0, width: buttonHeihgt, height: buttonHeihgt)
      // pauseButton.frame = CGRect(
      //   x: playButton.frame.maxX, y: 0, width: buttonHeihgt, height: buttonHeihgt)
      // switchCameraButton.frame = CGRect(
      //   x: pauseButton.frame.maxX, y: 0, width: buttonHeihgt, height: buttonHeihgt)
    } else {
      // toolbar.backgroundColor = .black.withAlphaComponent(0.7)
      // playButton.tintColor = .white
      // pauseButton.tintColor = .white
      // switchCameraButton.tintColor = .white

      // let width = bounds.width
      // let height = bounds.height

      // let topMargin: CGFloat = 0

      // let titleLabelHeight: CGFloat = height * 0.1
      // labelName.frame = CGRect(
      //   x: 0,
      //   y: topMargin,
      //   width: width,
      //   height: titleLabelHeight
      // )

      // let subLabelHeight: CGFloat = height * 0.04
      // labelFPS.frame = CGRect(
      //   x: 0,
      //   y: labelName.frame.maxY + 15,
      //   width: width,
      //   height: subLabelHeight
      // )

      // let sliderWidth: CGFloat = width * 0.46
      // let sliderHeight: CGFloat = height * 0.02

      // sliderNumItems.frame = CGRect(
      //   x: width * 0.01,
      //   y: center.y - sliderHeight - height * 0.24,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // labelSliderNumItems.frame = CGRect(
      //   x: width * 0.01,
      //   y: sliderNumItems.frame.minY - sliderHeight - 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // labelSliderConf.frame = CGRect(
      //   x: width * 0.01,
      //   y: center.y + height * 0.24,
      //   width: sliderWidth * 1.5,
      //   height: sliderHeight
      // )

      // sliderConf.frame = CGRect(
      //   x: width * 0.01,
      //   y: labelSliderConf.frame.maxY + 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // labelSliderIoU.frame = CGRect(
      //   x: width * 0.01,
      //   y: sliderConf.frame.maxY + 10,
      //   width: sliderWidth * 1.5,
      //   height: sliderHeight
      // )

      // sliderIoU.frame = CGRect(
      //   x: width * 0.01,
      //   y: labelSliderIoU.frame.maxY + 10,
      //   width: sliderWidth,
      //   height: sliderHeight
      // )

      // let zoomLabelWidth: CGFloat = width * 0.2
      // labelZoom.frame = CGRect(
      //   x: center.x - zoomLabelWidth / 2,
      //   y: self.bounds.maxY - 120,
      //   width: zoomLabelWidth,
      //   height: height * 0.03
      // )

      // let toolBarHeight: CGFloat = 66
      // let buttonHeihgt: CGFloat = toolBarHeight * 0.75
      // toolbar.frame = CGRect(x: 0, y: height - toolBarHeight, width: width, height: toolBarHeight)
      // playButton.frame = CGRect(x: 0, y: 0, width: buttonHeihgt, height: buttonHeihgt)
      // pauseButton.frame = CGRect(
      //   x: playButton.frame.maxX, y: 0, width: buttonHeihgt, height: buttonHeihgt)
      // switchCameraButton.frame = CGRect(
      //   x: pauseButton.frame.maxX, y: 0, width: buttonHeihgt, height: buttonHeihgt)
    }

    self.videoCapture.previewLayer?.frame = self.bounds
  }

  private func setUpOrientationChangeNotification() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(orientationDidChange),
      name: UIDevice.orientationDidChangeNotification, object: nil)
  }

  @objc func orientationDidChange() {
    var orientation: AVCaptureVideoOrientation = .portrait
    switch UIDevice.current.orientation {
    case .portrait:
      orientation = .portrait
    case .portraitUpsideDown:
      orientation = .portraitUpsideDown
    case .landscapeRight:
      orientation = .landscapeLeft
    case .landscapeLeft:
      orientation = .landscapeRight
    default:
      return
    }
    videoCapture.updateVideoOrientation(orientation: orientation)

    //      frameSizeCaptured = false
  }

  @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
    guard let device = videoCapture.captureDevice else { return }

    // Return zoom value between the minimum and maximum zoom values
    func minMaxZoom(_ factor: CGFloat) -> CGFloat {
      return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
    }

    func update(scale factor: CGFloat) {
      do {
        try device.lockForConfiguration()
        defer {
          device.unlockForConfiguration()
        }
        device.videoZoomFactor = factor
      } catch {
        print("\(error.localizedDescription)")
      }
    }

    let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
    switch pinch.state {
    case .began, .changed:
      update(scale: newScaleFactor)
      // self.labelZoom.text = String(format: "%.2fx", newScaleFactor)
      // self.labelZoom.font = UIFont.preferredFont(forTextStyle: .title2)
    case .ended:
      lastZoomFactor = minMaxZoom(newScaleFactor)
      update(scale: lastZoomFactor)
      // self.labelZoom.font = UIFont.preferredFont(forTextStyle: .body)
    default: break
    }
  }

  @objc func playTapped() {
    selection.selectionChanged()
    self.videoCapture.start()
    // playButton.isEnabled = false
    // pauseButton.isEnabled = true
  }

  @objc func pauseTapped() {
    selection.selectionChanged()
    self.videoCapture.stop()
    // playButton.isEnabled = true
    // pauseButton.isEnabled = false
  }

  @objc func switchCameraTapped() {
    self.videoCapture.captureSession.beginConfiguration()
    let currentInput = self.videoCapture.captureSession.inputs.first as? AVCaptureDeviceInput
    self.videoCapture.captureSession.removeInput(currentInput!)
    guard let currentPosition = currentInput?.device.position else { return }

    let nextCameraPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back

    let newCameraDevice = bestCaptureDevice(position: nextCameraPosition)

    guard let videoInput1 = try? AVCaptureDeviceInput(device: newCameraDevice) else {
      return
    }

    self.videoCapture.captureSession.addInput(videoInput1)
    var orientation: AVCaptureVideoOrientation = .portrait
    switch UIDevice.current.orientation {
    case .portrait:
      orientation = .portrait
    case .portraitUpsideDown:
      orientation = .portraitUpsideDown
    case .landscapeRight:
      orientation = .landscapeLeft
    case .landscapeLeft:
      orientation = .landscapeRight
    default:
      return
    }
    self.videoCapture.updateVideoOrientation(orientation: orientation)

    self.videoCapture.captureSession.commitConfiguration()
  }

  public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
    self.photoCaptureCompletion = completion
    let settings = AVCapturePhotoSettings()
    usleep(20_000)  // short 10 ms delay to allow camera to focus
    self.videoCapture.photoOutput.capturePhoto(
      with: settings, delegate: self as AVCapturePhotoCaptureDelegate
    )
  }

  public func setInferenceFlag(ok: Bool) {
    videoCapture.inferenceOK = ok
  }

  private func addTapGestureRecognizer() {
    // 既存のジェスチャーを削除してから追加（重複を防ぐため）
    self.gestureRecognizers?.forEach { 
      if $0 is UITapGestureRecognizer {
        self.removeGestureRecognizer($0)
      }
    }
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap(_:)))
    self.addGestureRecognizer(tapGesture)
  }

  @objc func handleViewTap(_ gesture: UITapGestureRecognizer) {
    let currentTime = CACurrentMediaTime()
    if currentTime - lastTapHandledTime < minTapInterval {
      // print("YOLOView Tap: Tap ignored due to rapid succession.")
      return
    }

    guard gesture.state == .ended,
          let yoloResult = self.lastYOLOResult,
          !yoloResult.boxes.isEmpty else {
      // print("Tap ignored: No result or boxes, or gesture not ended.")
      return
    }

    let tapLocationInView = gesture.location(in: self)

    // guard let overlay = self.overlayLayer, overlay.bounds.width > 0, overlay.bounds.height > 0 else {
    guard self.overlayLayer.bounds.width > 0, self.overlayLayer.bounds.height > 0 else {
      print("YOLOView Tap: Overlay layer not properly set up for tap detection.")
      return
    }

    let tapLocationInOverlay = self.layer.convert(tapLocationInView, to: self.overlayLayer)

    guard self.overlayLayer.bounds.contains(tapLocationInOverlay) else {
      // print("YOLOView Tap: Tap is outside overlay bounds.")
      return
    }

    let normalizedTapX = tapLocationInOverlay.x / self.overlayLayer.bounds.width
    let normalizedTapY = tapLocationInOverlay.y / self.overlayLayer.bounds.height
    let normalizedTapPoint = CGPoint(x: normalizedTapX, y: normalizedTapY)

    var tappedBoxesInLocation: [Box] = []

    for boxData in yoloResult.boxes {
      if boxData.xywhn.contains(normalizedTapPoint) {
        tappedBoxesInLocation.append(boxData)
      }
    }

    if tappedBoxesInLocation.isEmpty {
      // print("YOLOView Tap: Tapped on background (no object detected at this specific tap location).")
    } else {
      let bestBox = tappedBoxesInLocation.max(by: { $0.conf < $1.conf })
      
      if let selectedBox = bestBox {
        // Prepare the dictionary to be passed to the callback
        let objectInfoDict: [String: String] = [
            "Name": selectedBox.cls,
            "Index": String(selectedBox.index),
            "Confidence": String(format: "%.2f", selectedBox.conf),
            // Add other properties from selectedBox.xywh if needed, converting CGRect to String
            "xywh_x": String(format: "%.2f", selectedBox.xywh.origin.x),
            "xywh_y": String(format: "%.2f", selectedBox.xywh.origin.y),
            "xywh_width": String(format: "%.2f", selectedBox.xywh.size.width),
            "xywh_height": String(format: "%.2f", selectedBox.xywh.size.height)
        ]
        // Call the new callback
        onObjectTapped?(objectInfoDict)
        
        // Original print statements (can be kept for debugging or removed)
        // let consoleOutputInfo = "Tapped Object -> Name: \\(selectedBox.cls), Index: \\(selectedBox.index), Confidence: \\(String(format: "%.2f", selectedBox.conf))"
        // print("--- YOLOView: Tapped Object Info ---")
        // print(consoleOutputInfo)
        // print("-------------------------------------")
        lastTapHandledTime = currentTime
      } else {
        // print("YOLOView Tap: Could not determine best object to display.")
      }
    }
  }
}

extension YOLOView: AVCapturePhotoCaptureDelegate {
  public func photoOutput(
    _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
  ) {
    if let error = error {
      print("error occurred : \(error.localizedDescription)")
    }
    if let dataImage = photo.fileDataRepresentation() {
      let dataProvider = CGDataProvider(data: dataImage as CFData)
      let cgImageRef: CGImage! = CGImage(
        jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true,
        intent: .defaultIntent)
      var isCameraFront = false
      if let currentInput = self.videoCapture.captureSession.inputs.first as? AVCaptureDeviceInput,
        currentInput.device.position == .front
      {
        isCameraFront = true
      }
      var orientation: CGImagePropertyOrientation = isCameraFront ? .leftMirrored : .right
      switch UIDevice.current.orientation {
      case .landscapeLeft:
        orientation = isCameraFront ? .downMirrored : .up
      case .landscapeRight:
        orientation = isCameraFront ? .upMirrored : .down
      default:
        break
      }
      var image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: .right)
      if let orientedCIImage = CIImage(image: image)?.oriented(orientation),
        let cgImage = CIContext().createCGImage(orientedCIImage, from: orientedCIImage.extent)
      {
        image = UIImage(cgImage: cgImage)
      }
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFill
      imageView.frame = self.frame
      let imageLayer = imageView.layer
      self.layer.insertSublayer(imageLayer, above: videoCapture.previewLayer)

      var tempViews = [UIView]()
      let boundingBoxInfos = makeBoundingBoxInfos(from: boundingBoxViews)
      for info in boundingBoxInfos where !info.isHidden {
        let boxView = createBoxView(from: info)
        boxView.frame = info.rect

        self.addSubview(boxView)
        tempViews.append(boxView)
      }
      let bounds = UIScreen.main.bounds
      UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
      self.drawHierarchy(in: bounds, afterScreenUpdates: true)
      let img = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      imageLayer.removeFromSuperlayer()
      for v in tempViews {
        v.removeFromSuperview()
      }
      photoCaptureCompletion?(img)
      photoCaptureCompletion = nil
    } else {
      print("AVCapturePhotoCaptureDelegate Error")
    }
  }
}

public func processString(_ input: String) -> String {
  var output = input.replacingOccurrences(
    of: "yolo",
    with: "YOLO",
    options: .caseInsensitive,
    range: nil
  )

  output = output.replacingOccurrences(
    of: "obb",
    with: "OBB",
    options: .caseInsensitive,
    range: nil
  )

  guard !output.isEmpty else {
    return output
  }

  let first = output[output.startIndex]
  let firstUppercased = String(first).uppercased()

  if String(first) != firstUppercased {
    output = firstUppercased + output.dropFirst()
  }

  return output
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
