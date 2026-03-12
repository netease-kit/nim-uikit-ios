
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEDiffableSection

/// A protocol that allows us to check identity and equality between sections of `NEDiffable` items
/// for the purposes of diffing.
protocol NEDiffableSection: NEDiffable {
  /// The diffable items in this section.
  associatedtype DiffableItems: Collection where
    DiffableItems.Index == Int,
    DiffableItems.Element: NEDiffable

  /// The diffable items in this section.
  var diffableItems: DiffableItems { get }
}
