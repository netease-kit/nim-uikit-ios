
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

extension CAShapeLayer {
  /// Adds animations for the given `NECombinedShapeItem` to this `CALayer`
  @nonobjc
  func addAnimations(for combinedShapes: NECombinedShapeItem,
                     context: NELayerAnimationContext,
                     pathMultiplier: PathMultiplier)
    throws {
    try neAddAnimation(
      for: .path,
      keyframes: combinedShapes.shapes,
      value: { paths in
        let combinedPath = CGMutablePath()
        for path in paths {
          combinedPath.addPath(path.cgPath().duplicated(times: pathMultiplier))
        }
        return combinedPath
      },
      context: context
    )
  }
}

// MARK: - NECombinedShapeItem

/// A custom `NEShapeItem` subclass that combines multiple `NEShape`s into a single `NEKeyframeGroup`
final class NECombinedShapeItem: NEShapeItem {
  // MARK: Lifecycle

  init(shapes: NEKeyframeGroup<[NEBezierPath]>, name: String) {
    self.shapes = shapes
    super.init(name: name, type: .shape, hidden: false)
  }

  required init(from _: Decoder) throws {
    fatalError("init(from:) has not been implemented")
  }

  required init(dictionary _: [String: Any]) throws {
    fatalError("init(dictionary:) has not been implemented")
  }

  // MARK: Internal

  let shapes: NEKeyframeGroup<[NEBezierPath]>
}

extension NECombinedShapeItem {
  /// Manually combines the given shape keyframes by manually interpolating at each frame
  static func manuallyInterpolating(shapes: [NEKeyframeGroup<NEBezierPath>],
                                    name: String)
    -> NECombinedShapeItem {
    let interpolators = shapes.map { shape in
      NEKeyframeInterpolator(keyframes: shape.keyframes)
    }

    let times = shapes.flatMap { $0.keyframes.map { $0.time } }

    let minimumTime = times.min() ?? 0
    let maximumTime = times.max() ?? 0
    let animationLocalTimeRange = Int(minimumTime) ... Int(maximumTime)

    let interpolatedKeyframes = animationLocalTimeRange.map { localTime in
      NEKeyframe(
        value: interpolators.compactMap { interpolator in
          interpolator.value(frame: NEAnimationFrameTime(localTime)) as? NEBezierPath
        },
        time: NEAnimationFrameTime(localTime)
      )
    }

    return NECombinedShapeItem(
      shapes: NEKeyframeGroup(keyframes: ContiguousArray(interpolatedKeyframes)),
      name: name
    )
  }
}
