// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Connects a LottieTextProvider to a group of text layers
final class NELayerTextProvider {
  // MARK: Lifecycle

  init(textProvider: NEAnimationKeypathTextProvider) {
    self.textProvider = textProvider
    textLayers = []
    reloadTexts()
  }

  // MARK: Internal

  private(set) var textLayers: [NETextCompositionLayer]

  var textProvider: NEAnimationKeypathTextProvider {
    didSet {
      reloadTexts()
    }
  }

  func addTextLayers(_ layers: [NETextCompositionLayer]) {
    textLayers += layers
  }

  func reloadTexts() {
    for textLayer in textLayers {
      textLayer.textProvider = textProvider
    }
  }
}
