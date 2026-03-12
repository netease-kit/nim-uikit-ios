// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreGraphics
import Foundation

/// A value provider that produces an array of values from an array of NEKeyframe Interpolators
final class NEGroupInterpolator<ValueType>: NEValueProvider where ValueType: NEInterpolatable {
  // MARK: Lifecycle

  /// Initialize with an array of array of keyframes.
  init(keyframeGroups: ContiguousArray<ContiguousArray<NEKeyframe<ValueType>>>) {
    keyframeInterpolators = ContiguousArray(keyframeGroups.map { NEKeyframeInterpolator(keyframes: $0) })
  }

  // MARK: Internal

  let keyframeInterpolators: ContiguousArray<NEKeyframeInterpolator<ValueType>>

  var valueType: Any.Type {
    [ValueType].self
  }

  var storage: NEValueProviderStorage<[ValueType]> {
    .closure { frame in
      self.keyframeInterpolators.map { $0.value(frame: frame) as! ValueType }
    }
  }

  func hasUpdate(frame: CGFloat) -> Bool {
    let updated = keyframeInterpolators.first(where: { $0.hasUpdate(frame: frame) })
    return updated != nil
  }
}
