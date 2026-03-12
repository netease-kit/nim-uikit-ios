
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NECompositionLayer

/// The base class for a child layer of CompositionContainer
class NECompositionLayer: CALayer, NEKeypathSearchable {
  // MARK: Lifecycle

  init(layer: NELayerModel, size: CGSize) {
    transformNode = NELayerTransformNode(transform: layer.transform)
    if let masks = layer.masks?.filter({ $0.mode != .none }), !masks.isEmpty {
      maskLayer = NEMaskContainerLayer(masks: masks)
    } else {
      maskLayer = nil
    }
    matteType = layer.matte
    inFrame = layer.inFrame.cgFloat
    outFrame = layer.outFrame.cgFloat
    timeStretch = layer.timeStretch.cgFloat
    startFrame = layer.startTime.cgFloat
    keypathName = layer.name
    childKeypaths = [transformNode.transformProperties]
    super.init()
    anchorPoint = .zero
    actions = [
      "opacity": NSNull(),
      "transform": NSNull(),
      "bounds": NSNull(),
      "anchorPoint": NSNull(),
      "sublayerTransform": NSNull(),
    ]

    contentsLayer.anchorPoint = .zero
    contentsLayer.bounds = CGRect(origin: .zero, size: size)
    contentsLayer.actions = [
      "opacity": NSNull(),
      "transform": NSNull(),
      "bounds": NSNull(),
      "anchorPoint": NSNull(),
      "sublayerTransform": NSNull(),
      "hidden": NSNull(),
    ]
    compositingFilter = layer.blendMode.filterName
    addSublayer(contentsLayer)

    if let maskLayer {
      contentsLayer.mask = maskLayer
    }

    name = layer.name
  }

  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? NECompositionLayer else {
      fatalError("Wrong Layer Class")
    }
    transformNode = layer.transformNode
    matteType = layer.matteType
    inFrame = layer.inFrame
    outFrame = layer.outFrame
    timeStretch = layer.timeStretch
    startFrame = layer.startFrame
    keypathName = layer.keypathName
    childKeypaths = [transformNode.transformProperties]
    maskLayer = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  weak var layerDelegate: NECompositionLayerDelegate?

  let transformNode: NELayerTransformNode

  let contentsLayer = CALayer()

  let maskLayer: NEMaskContainerLayer?

  let matteType: NEMatteType?

  let inFrame: CGFloat
  let outFrame: CGFloat
  let startFrame: CGFloat
  let timeStretch: CGFloat

  // MARK: Keypath Searchable

  let keypathName: String

  final var childKeypaths: [NEKeypathSearchable]

  var renderScale: CGFloat = 1 {
    didSet {
      updateRenderScale()
    }
  }

  var matteLayer: NECompositionLayer? {
    didSet {
      if let matte = matteLayer {
        if let type = matteType, type == .invert {
          mask = NEInvertedMatteLayer(inputMatte: matte)
        } else {
          mask = matte
        }
      } else {
        mask = nil
      }
    }
  }

  var keypathProperties: [String: NEAnyNodeProperty] {
    [:]
  }

  var keypathLayer: CALayer? {
    contentsLayer
  }

  final func displayWithFrame(frame: CGFloat, forceUpdates: Bool) {
    transformNode.updateTree(frame, forceUpdates: forceUpdates)
    let layerVisible = frame.isInRangeOrEqual(inFrame, outFrame)
    /// Only update contents if current time is within the layers time bounds.
    if layerVisible {
      displayContentsWithFrame(frame: frame, forceUpdates: forceUpdates)
      maskLayer?.updateWithFrame(frame: frame, forceUpdates: forceUpdates)
    }
    contentsLayer.transform = transformNode.globalTransform
    contentsLayer.opacity = transformNode.opacity
    contentsLayer.isHidden = !layerVisible
    layerDelegate?.frameUpdated(frame: frame)
  }

  func displayContentsWithFrame(frame _: CGFloat, forceUpdates _: Bool) {
    /// To be overridden by subclass
  }

  func updateRenderScale() {
    contentsScale = renderScale
  }
}

// MARK: - NECompositionLayerDelegate

protocol NECompositionLayerDelegate: AnyObject {
  func frameUpdated(frame: CGFloat)
}
