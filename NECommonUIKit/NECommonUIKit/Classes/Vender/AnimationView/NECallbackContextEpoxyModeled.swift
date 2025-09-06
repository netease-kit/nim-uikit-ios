
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// An Epoxy model with an associated context type that's passed into callback closures.
protocol NECallbackContextEpoxyModeled: NEEpoxyModeled {
  /// A context type that's passed into callback closures.
  associatedtype CallbackContext
}
