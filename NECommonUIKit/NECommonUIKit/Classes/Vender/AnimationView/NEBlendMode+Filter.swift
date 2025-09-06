
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

extension NEBlendMode {
  /// The Core Image filter name for this `NEBlendMode`, that can be applied to a `CALayer`'s `compositingFilter`.
  /// Supported compositing filters are defined here: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP30000136-SW71
  var filterName: String? {
    switch self {
    case .normal: return nil
    case .multiply: return "multiplyBlendMode"
    case .screen: return "screenBlendMode"
    case .overlay: return "overlayBlendMode"
    case .darken: return "darkenBlendMode"
    case .lighten: return "lightenBlendMode"
    case .colorDodge: return "colorDodgeBlendMode"
    case .colorBurn: return "colorBurnBlendMode"
    case .hardLight: return "hardLightBlendMode"
    case .softLight: return "softLightBlendMode"
    case .difference: return "differenceBlendMode"
    case .exclusion: return "exclusionBlendMode"
    case .hue: return "hueBlendMode"
    case .saturation: return "saturationBlendMode"
    case .color: return "colorBlendMode"
    case .luminosity: return "luminosityBlendMode"
    }
  }
}
