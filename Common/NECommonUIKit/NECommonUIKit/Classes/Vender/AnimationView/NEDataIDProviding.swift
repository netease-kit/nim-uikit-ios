
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDataIDProviding

/// The capability of providing a stable data identifier with an erased type.
///
/// While it has similar semantics, this type cannot inherit from `Identifiable` as this would give
/// it an associated type, which would cause the `keyPath` used in its `NEEpoxyModelProperty` to not
/// be stable across types if written as `\Self.dataID` since the `KeyPath` `Root` would be
/// different for each type.
///
/// - SeeAlso: `Identifiable`.
protocol NEDataIDProviding {
  /// A stable identifier that uniquely identifies this instance, with its typed erased.
  ///
  /// Defaults to `NEDefaultDataID.noneProvided` if no data ID is provided.
  var dataID: AnyHashable { get }
}

// MARK: - NEEpoxyModeled

extension NEEpoxyModeled where Self: NEDataIDProviding {
  // MARK: Internal

  /// A stable identifier that uniquely identifies this model, with its typed erased.
  var dataID: AnyHashable {
    get { self[dataIDProperty] }
    set { self[dataIDProperty] = newValue }
  }

  /// Returns a copy of this model with the ID replaced with the provided ID.
  func dataID(_ value: AnyHashable) -> Self {
    copy(updating: dataIDProperty, to: value)
  }

  // MARK: Private

  private var dataIDProperty: NEEpoxyModelProperty<AnyHashable> {
    NEEpoxyModelProperty(
      keyPath: \NEDataIDProviding.dataID,
      defaultValue: NEDefaultDataID.noneProvided,
      updateStrategy: .replace
    )
  }
}

// MARK: - NEDefaultDataID

/// The default data ID when none is provided.
enum NEDefaultDataID: Hashable, CustomDebugStringConvertible {
  case noneProvided

  var debugDescription: String {
    "NEDefaultDataID.noneProvided"
  }
}
