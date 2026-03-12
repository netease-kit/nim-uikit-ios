// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

struct NEPagingDistance {
  private let view: NECollectionView
  private let hasItemsBefore: Bool
  private let hasItemsAfter: Bool
  private let fromItem: NEPagingItem
  private let fromAttributes: NEPagingCellLayoutAttributes?
  private let toItem: NEPagingItem
  private let toAttributes: NEPagingCellLayoutAttributes
  private let selectedScrollPosition: NEPagingSelectedScrollPosition
  private let sizeCache: NEPagingSizeCache
  private let navigationOrientation: NEPagingNavigationOrientation

  private var fromSize: CGFloat {
    guard let attributes = fromAttributes else { return 0 }
    switch navigationOrientation {
    case .vertical:
      return attributes.bounds.height
    case .horizontal:
      return attributes.bounds.width
    }
  }

  private var fromCenter: CGFloat {
    guard let attributes = fromAttributes else { return 0 }
    switch navigationOrientation {
    case .vertical:
      return attributes.center.y
    case .horizontal:
      return attributes.center.x
    }
  }

  private var toSize: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return toAttributes.bounds.height
    case .horizontal:
      return toAttributes.bounds.width
    }
  }

  private var toCenter: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return toAttributes.center.y
    case .horizontal:
      return toAttributes.center.x
    }
  }

  private var contentOffset: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return view.contentOffset.y
    case .horizontal:
      return view.contentOffset.x
    }
  }

  private var contentSize: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return view.contentSize.height
    case .horizontal:
      return view.contentSize.width
    }
  }

  private var viewSize: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return view.bounds.height
    case .horizontal:
      return view.bounds.width
    }
  }

  private var viewCenter: CGFloat {
    switch navigationOrientation {
    case .vertical:
      return view.bounds.midY
    case .horizontal:
      return view.bounds.midX
    }
  }

  init?(view: NECollectionView,
        currentPagingItem: NEPagingItem,
        upcomingPagingItem: NEPagingItem,
        visibleItems: NEPagingItems,
        sizeCache: NEPagingSizeCache,
        selectedScrollPosition: NEPagingSelectedScrollPosition,
        layoutAttributes: [IndexPath: NEPagingCellLayoutAttributes],
        navigationOrientation: NEPagingNavigationOrientation) {
    guard
      let upcomingIndexPath = visibleItems.indexPath(for: upcomingPagingItem),
      let upcomingAttributes = layoutAttributes[upcomingIndexPath] else {
      return nil
    }

    self.view = view
    hasItemsBefore = visibleItems.hasItemsBefore
    hasItemsAfter = visibleItems.hasItemsAfter
    fromItem = currentPagingItem
    toItem = upcomingPagingItem
    toAttributes = upcomingAttributes
    self.selectedScrollPosition = selectedScrollPosition
    self.sizeCache = sizeCache
    self.navigationOrientation = navigationOrientation

    if let currentIndexPath = visibleItems.indexPath(for: currentPagingItem),
       let fromAttributes = layoutAttributes[currentIndexPath] {
      self.fromAttributes = fromAttributes
    } else {
      fromAttributes = nil
    }
  }

  /// 计算位移
  func calculate() -> CGFloat {
    var distance: CGFloat = 0

    switch selectedScrollPosition {
    case .left:
      distance = distanceLeft()
    case .right:
      distance = distanceRight()
    case .preferCentered, .center:
      distance = distanceCentered()
    }

    if view.near(edge: .left, clearance: -distance), distance < 0, hasItemsBefore == false {
      distance = -(contentOffset + view.contentInset.left)
    } else if view.near(edge: .right, clearance: distance), distance > 0, hasItemsAfter == false {
      let originalDistance = distance
      distance = contentSize - (contentOffset + viewSize)

      if sizeCache.implementsSizeDelegate {
        let toWidth = sizeCache.itemWidthSelected(for: toItem)
        distance += toWidth - toSize

        if let _ = fromAttributes {
          let fromWidth = sizeCache.itemSize(for: fromItem)
          distance -= fromSize - fromWidth
        }

        if selectedScrollPosition == .preferCentered {
          let center = viewCenter
          let centerAfterTransition = toCenter - distance
          if centerAfterTransition < center {
            distance = originalDistance
          }
        }
      }
    }

    return distance
  }

  private func distanceLeft() -> CGFloat {
    let currentPosition = toCenter - (toSize / 2)
    var distance = currentPosition - contentOffset

    if sizeCache.implementsSizeDelegate {
      if let _ = fromAttributes {
        if fromItem.isBefore(item: toItem) {
          let fromWidth = sizeCache.itemSize(for: fromItem)
          let fromDiff = fromSize - fromWidth
          distance -= fromDiff
        }
      }
    }
    return distance
  }

  private func distanceRight() -> CGFloat {
    let currentPosition = toCenter + (toSize / 2)
    let width = contentOffset + viewSize
    var distance = currentPosition - width

    if sizeCache.implementsSizeDelegate {
      let toWidth = sizeCache.itemWidthSelected(for: toItem)
      if let _ = fromAttributes {
        if toItem.isBefore(item: fromItem) {
          let toDiff = toWidth - toSize
          distance += toDiff
        } else {
          let fromWidth = sizeCache.itemSize(for: fromItem)
          let fromDiff = fromSize - fromWidth
          let toDiff = toWidth - toSize
          distance -= fromDiff
          distance += toDiff
        }
      } else {
        distance += toWidth - toSize
      }
    }

    return distance
  }

  private func distanceCentered() -> CGFloat {
    var distance = toCenter - viewCenter

    if let _ = fromAttributes {
      let distanceToCenter = viewCenter - fromCenter
      let distanceBetweenCells = toCenter - fromCenter
      distance = distanceBetweenCells - distanceToCenter

      if sizeCache.implementsSizeDelegate {
        let toWidth = sizeCache.itemWidthSelected(for: toItem)
        let fromWidth = sizeCache.itemSize(for: fromItem)

        if toItem.isBefore(item: fromItem) {
          distance = -(toSize + (fromCenter - (toCenter + (toSize / 2))) - (toWidth / 2)) - distanceToCenter
        } else {
          let toDiff = (toWidth - toSize) / 2
          distance = fromWidth + (toCenter - (fromCenter + (fromSize / 2))) + toDiff - (fromSize / 2) - distanceToCenter
        }
      }
    } else if sizeCache.implementsSizeDelegate {
      let toWidth = sizeCache.itemWidthSelected(for: toItem)
      let toDiff = toWidth - toSize
      distance += toDiff / 2
    }

    return distance
  }
}
