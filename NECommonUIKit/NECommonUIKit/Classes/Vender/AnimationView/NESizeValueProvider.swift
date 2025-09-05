// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

// MARK: - NESizeValueProvider

/// A `NEValueProvider` that returns a CGSize Value
public final class NESizeValueProvider: NEValueProvider {
  // MARK: Lifecycle

  /// Initializes with a block provider
  public init(block: @escaping SizeValueBlock) {
    self.block = block
    size = .zero
    identity = UUID()
  }

  /// Initializes with a single size.
  public init(_ size: CGSize) {
    self.size = size
    block = nil
    hasUpdate = true
    identity = [size.width, size.height]
  }

  // MARK: Public

  /// Returns a CGSize for a CGFloat(Frame Time)
  public typealias SizeValueBlock = (CGFloat) -> CGSize

  public var size: CGSize {
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
      return .singleValue(size.vector3dValue)
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

  private var block: SizeValueBlock?
  private let identity: AnyHashable
}

// MARK: Equatable

extension NESizeValueProvider: Equatable {
  public static func == (_ lhs: NESizeValueProvider, _ rhs: NESizeValueProvider) -> Bool {
    lhs.identity == rhs.identity
  }
}
