// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEStyleIDProviding

protocol NEStyleIDProviding {
  /// An optional ID for a style type to use for reuse of a view.
  ///
  /// Use this to differentiate between different styling configurations.
  var styleID: AnyHashable? { get }
}

// MARK: - NEEpoxyModeled

extension NEEpoxyModeled where Self: NEStyleIDProviding {
  // MARK: Internal

  var styleID: AnyHashable? {
    get { self[styleIDProperty] }
    set { self[styleIDProperty] = newValue }
  }

  /// Returns a copy of this model with the `styleID` replaced with the provided `value`.
  func styleID(_ value: AnyHashable?) -> Self {
    copy(updating: styleIDProperty, to: value)
  }

  // MARK: Private

  private var styleIDProperty: NEEpoxyModelProperty<AnyHashable?> {
    .init(
      keyPath: \NEStyleIDProviding.styleID,
      defaultValue: nil,
      updateStrategy: .replace
    )
  }
}
