// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A set of the minimum changes to get from one array of `NEDiffableSection`s to another, used for
/// diffing.
struct NESectionedChangeset {
  // MARK: Lifecycle

  init(sectionChangeset: NEIndexSetChangeset,
       itemChangeset: NEIndexPathChangeset) {
    self.sectionChangeset = sectionChangeset
    self.itemChangeset = itemChangeset
  }

  // MARK: Internal

  /// A set of the minimum changes to get from one set of sections to another.
  var sectionChangeset: NEIndexSetChangeset

  /// A set of the minimum changes to get from one set of items to another, aggregated across all
  /// sections.
  var itemChangeset: NEIndexPathChangeset

  /// Whether there are any inserts, deletes, moves, or updates in this changeset.
  var isEmpty: Bool {
    sectionChangeset.isEmpty && itemChangeset.isEmpty
  }
}
