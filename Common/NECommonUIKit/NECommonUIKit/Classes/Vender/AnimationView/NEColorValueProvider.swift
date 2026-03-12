
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEColorValueProvider

/// A `NEValueProvider` that returns a CGColor Value
public final class NEColorValueProvider: NEValueProvider {
  // MARK: Lifecycle

  /// Initializes with a block provider
  public init(block: @escaping ColorValueBlock) {
    self.block = block
    color = NELottieColor(r: 0, g: 0, b: 0, a: 1)
    keyframes = nil
    identity = UUID()
  }

  /// Initializes with a single color.
  public init(_ color: NELottieColor) {
    self.color = color
    block = nil
    keyframes = nil
    hasUpdate = true
    identity = color
  }

  /// Initializes with multiple colors, with timing information
  public init(_ keyframes: [NEKeyframe<NELottieColor>]) {
    self.keyframes = keyframes
    color = NELottieColor(r: 0, g: 0, b: 0, a: 1)
    block = nil
    hasUpdate = true
    identity = keyframes
  }

  // MARK: Public

  /// Returns a NELottieColor for a CGColor(Frame Time)
  public typealias ColorValueBlock = (CGFloat) -> NELottieColor

  /// The color value of the provider.
  public var color: NELottieColor {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: NEValueProvider Protocol

  public var valueType: Any.Type {
    NELottieColor.self
  }

  public var storage: NEValueProviderStorage<NELottieColor> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame)
      }
    } else if let keyframes {
      return .keyframes(keyframes)
    } else {
      hasUpdate = false
      return .singleValue(color)
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  // MARK: Private

  private var hasUpdate = true

  private var block: ColorValueBlock?
  private var keyframes: [NEKeyframe<NELottieColor>]?
  private var identity: AnyHashable
}

// MARK: Equatable

extension NEColorValueProvider: Equatable {
  public static func == (_ lhs: NEColorValueProvider, _ rhs: NEColorValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
