// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELottieAnimationSource

/// A data source for a Lottie animation.
/// Either a `NELottieAnimation` loaded from a `.json` file,
/// or a `NEDotLottieFile` loaded from a `.lottie` file.
public enum NELottieAnimationSource: Sendable {
  /// A `NELottieAnimation` loaded from a `.json` file
  case lottieAnimation(NELottieAnimation)

  /// A `NEDotLottieFile` loaded from a `.lottie` file
  case dotLottieFile(NEDotLottieFile)
}

extension NELottieAnimationSource {
  /// The default animation displayed by this data source
  var animation: NELottieAnimation? {
    switch self {
    case let .lottieAnimation(animation):
      return animation
    case .dotLottieFile:
      return dotLottieAnimation?.animation
    }
  }

  /// The `NEDotLottieFile.Animation`, if this is a dotLottie animation
  var dotLottieAnimation: NEDotLottieFile.Animation? {
    switch self {
    case .lottieAnimation:
      return nil
    case let .dotLottieFile(dotLottieFile):
      return dotLottieFile.animation()
    }
  }
}

public extension NELottieAnimation {
  /// This animation represented as a `NELottieAnimationSource`
  var animationSource: NELottieAnimationSource {
    .lottieAnimation(self)
  }
}

public extension NEDotLottieFile {
  /// This animation represented as a `NELottieAnimationSource`
  var animationSource: NELottieAnimationSource {
    .dotLottieFile(self)
  }
}
