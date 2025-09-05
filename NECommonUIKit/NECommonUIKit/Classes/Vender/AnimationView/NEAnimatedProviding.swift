
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// The capability of providing a flag indicating whether an operation should be animated.
///
/// Typically conformed to by the `CallbackContext` of a `CallbackContextEpoxyModeled`.
@objc
protocol NEAnimatedProviding {
  /// Whether this operation should be animated.
  var animated: Bool { get }
}
