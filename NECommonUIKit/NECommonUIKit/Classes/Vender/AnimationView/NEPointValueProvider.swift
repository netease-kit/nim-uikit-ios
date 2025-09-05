// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NEPointValueProvider

/// A `NEValueProvider` that returns a CGPoint Value
public final class NEPointValueProvider: NEValueProvider {
  // MARK: Lifecycle

  /// Initializes with a block provider
  public init(block: @escaping PointValueBlock) {
    self.block = block
    point = .zero
    identity = UUID()
  }

  /// Initializes with a single point.
  public init(_ point: CGPoint) {
    self.point = point
    block = nil
    hasUpdate = true
    identity = [point.x, point.y]
  }

  // MARK: Public

  /// Returns a CGPoint for a CGFloat(Frame Time)
  public typealias PointValueBlock = (CGFloat) -> CGPoint

  public var point: CGPoint {
    didSet {
      hasUpdate = true
    }
  }

  // MARK: NEValueProvider Protocol

  public var valueType: Any.Type {
    NELottieVector3D.self
  }

  public var storage: NEValueProviderStorage<NELottieVector3D> {
    if let block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame).vector3dValue
      }
    } else {
      hasUpdate = false
      return .singleValue(point.vector3dValue)
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

  private var block: PointValueBlock?
  private let identity: AnyHashable
}

// MARK: Equatable

extension NEPointValueProvider: Equatable {
  public static func == (_ lhs: NEPointValueProvider, _ rhs: NEPointValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
