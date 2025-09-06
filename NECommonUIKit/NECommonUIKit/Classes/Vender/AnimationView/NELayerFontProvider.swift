// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Connects a LottieFontProvider to a group of text layers
final class NELayerFontProvider {
  // MARK: Lifecycle

  init(fontProvider: NEAnimationFontProvider) {
    self.fontProvider = fontProvider
    textLayers = []
    reloadTexts()
  }

  // MARK: Internal

  private(set) var textLayers: [NETextCompositionLayer]

  var fontProvider: NEAnimationFontProvider {
    didSet {
      reloadTexts()
    }
  }

  func addTextLayers(_ layers: [NETextCompositionLayer]) {
    textLayers += layers
  }

  func reloadTexts() {
    for textLayer in textLayers {
      textLayer.fontProvider = fontProvider
    }
  }
}
