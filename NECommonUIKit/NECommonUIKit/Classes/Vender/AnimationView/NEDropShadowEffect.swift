// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

final class NEDropShadowEffect: NELayerEffect {
  // MARK: Lifecycle

  required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    try super.init(dictionary: dictionary)
  }

  // MARK: Internal

  /// The color of the drop shadow
  var color: NEColorEffectValue? {
    value(named: "Shadow Color")
  }

  /// Opacity between 0 and 255
  var opacity: NEVector1DEffectValue? {
    value(named: "Opacity")
  }

  /// The direction / angle of the drop shadow, in degrees
  var direction: NEVector1DEffectValue? {
    value(named: "Direction")
  }

  /// The distance of the drop shadow
  var distance: NEVector1DEffectValue? {
    value(named: "Distance")
  }

  /// The softness of the drop shadow
  var softness: NEVector1DEffectValue? {
    value(named: "Softness")
  }
}
