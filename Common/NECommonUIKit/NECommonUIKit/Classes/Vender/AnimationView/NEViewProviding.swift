// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// The capability of providing an `View` instance
///
/// Typically conformed to by the `CallbackContext` of a `NECallbackContextEpoxyModeled`.
protocol NEViewProviding {
  /// The `UIView` view of this type.
  associatedtype View: NEViewType

  /// The `UIView` view instance provided by this type.
  var view: View { get }
}
