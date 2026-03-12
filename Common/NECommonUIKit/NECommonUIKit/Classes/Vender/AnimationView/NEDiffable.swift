
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDiffable

/// A protocol that allows us to check identity and equality between items for the purposes of
/// diffing.
protocol NEDiffable {
  /// Checks for equality between items when diffing.
  ///
  /// - Parameters:
  ///     - otherDiffableItem: The other item to check equality against while diffing.
  func isDiffableItemEqual(to otherDiffableItem: NEDiffable) -> Bool

  /// The identifier to use when checking identity while diffing.
  var diffIdentifier: AnyHashable { get }
}
