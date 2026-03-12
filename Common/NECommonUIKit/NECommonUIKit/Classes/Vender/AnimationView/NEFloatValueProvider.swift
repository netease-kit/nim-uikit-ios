// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEFloatValueProvider

/// A `NEValueProvider` that returns a CGFloat Value
public final class NEFloatValueProvider: NEValueProvider {
  // MARK: Lifecycle

  /// Initializes with a block provider
  public init(block: @escaping CGFloatValueBlock) {
    self.block = block
    float = 0
    identity = UUID()
  }

  /// Initializes with a single float.
  public init(_ float: CGFloat) {
    self.float = float
    block = nil
    hasUpdate = true
    identity = float
  }

  // MARK: Public

  /// Returns a CGFloat for a CGFloat(Frame Time)
  public typealias CGFloatValueBlock = (CGFloat) -> CGFloat

  public var float: CGFloat {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: NEValueProvider Protocol

  public var valueType: Any.Type {
    NELottieVector1D.self
  }

  public var storage: NEValueProviderStorage<NELottieVector1D> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return NELottieVector1D(Double(block(frame)))
      }
    } else {
      hasUpdate = false
      return .singleValue(NELottieVector1D(Double(float)))
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

  private var block: CGFloatValueBlock?
  private var identity: AnyHashable
}

// MARK: Equatable

extension NEFloatValueProvider: Equatable {
  public static func == (_ lhs: NEFloatValueProvider, _ rhs: NEFloatValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
