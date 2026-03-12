// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public enum NEPagingMenuItemSource {
  case `class`(type: NEPagingCell.Type)
  case nib(nib: UINib)
}

extension NEPagingMenuItemSource: Equatable {
  public static func == (lhs: NEPagingMenuItemSource, rhs: NEPagingMenuItemSource) -> Bool {
    switch (lhs, rhs) {
    case let (.class(lhsType), .class(rhsType)):
      return lhsType == rhsType

    case let (.nib(lhsNib), .nib(rhsNib)):
      return lhsNib === rhsNib

    default:
      return false
    }
  }
}
