// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEViewDifferentiatorProviding

/// The capability of providing a view differentiator that facilitates generating collection view
/// cell reuse identifiers.
protocol NEViewDifferentiatorProviding {
  /// The view differentiator for the item model.
  var viewDifferentiator: NEViewDifferentiator { get }
}

// MARK: - NEViewDifferentiator

/// Facilitates differentiating between two models' views, based on their view type, optional style
/// identifier, and optional element kind for supplementary view models. If two models have the same
/// view differentiator, then they're compatible with one another for element reuse. If two models
/// have different view differentiators, then they're incompatible with one another for element
/// reuse.
struct NEViewDifferentiator: Hashable {
  // MARK: Lifecycle

  init(viewType: AnyClass, styleID: AnyHashable?) {
    viewTypeDescription = "\(type(of: viewType.self))"
    self.styleID = styleID
  }

  // MARK: Public

  var viewTypeDescription: String
  var styleID: AnyHashable?
}
