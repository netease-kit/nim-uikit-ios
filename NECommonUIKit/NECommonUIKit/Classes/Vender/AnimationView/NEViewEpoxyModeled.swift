// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// An Epoxy model with an associated `UIView` type.
protocol NEViewEpoxyModeled: NEEpoxyModeled {
  /// The view type associated with this model.
  ///
  /// An instance of this view is typically configured by this model.
  associatedtype View: NEViewType
}
