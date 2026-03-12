
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class PhotoBrowserFlowLayout: UICollectionViewFlowLayout {
  public var lastOffset: CGPoint

  override public init() {
    lastOffset = .zero
    super.init()
  }

  public required init?(coder: NSCoder) {
    lastOffset = .zero
    super.init(coder: coder)
  }

  override public func prepare() {
    super.prepare()
    lastOffset = collectionView?.contentOffset ?? .zero
    collectionView?.decelerationRate = .fast
  }
}

extension PhotoBrowserFlowLayout {
  /**
   * 这个方法的返回值，就决定了collectionView停止滚动时的偏移量
   */

  override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                           withScrollingVelocity velocity: CGPoint) -> CGPoint {
    var proposedContentOffset = proposedContentOffset
    let pageSpace = stepSpace()
    let offsetMax: CGFloat = collectionView?.contentSize.width ?? UIScreen.main.bounds.size
      .width - (pageSpace + sectionInset.right + minimumLineSpacing)
    let offsetMin: CGFloat = 0
    /* 修改之前记录的位置，如果小于最小contentsize或者大于最大contentsize则重置值 */
    if lastOffset.x < offsetMin {
      lastOffset.x = offsetMin
    } else if lastOffset.x > offsetMax {
      lastOffset.x = offsetMax
    }

    let offsetForCurrentPointX: CGFloat = abs(proposedContentOffset.x - lastOffset
      .x) // 目标位移点距离当前点的距离绝对值
    let velocityX: CGFloat = velocity.x
    let direction: Bool = (proposedContentOffset.x - lastOffset.x) >
      0 // 判断当前滑动方向,手指向左滑动：YES；手指向右滑动：NO

    if offsetForCurrentPointX > (pageSpace / 8), lastOffset.x >= offsetMin,
       lastOffset.x <= offsetMax {
      var pageFactor: CGFloat = 0 // 分页因子，用于计算滑过的cell个数
      if velocityX != 0 {
        // 滑动
        pageFactor = abs(velocityX) // 速率越快，cell滑动的数量越多
      } else {
        /**
         * 拖动
         * 没有速率，则计算：位移差/默认步距=分页因子
         */
        pageFactor = abs(offsetForCurrentPointX / pageSpace)
      }
      /* 设置pageFactor上限为2, 防止滑动速率过大，导致翻页过多 */
      pageFactor = pageFactor < 1 ? 1 : 1
      let pageOffsetX = pageSpace * pageFactor
      proposedContentOffset = CGPoint(
        x: lastOffset.x + (direction ? pageOffsetX : -pageOffsetX),
        y: proposedContentOffset.y
      )
    } else {
      proposedContentOffset = CGPoint(x: lastOffset.x, y: lastOffset.y)
    }
    // 记录当前最新位置
    lastOffset.x = proposedContentOffset.x
    return proposedContentOffset
  }

  /**
   *计算每滑动一页的距离：步距
   */
  func stepSpace() -> CGFloat {
    itemSize.width + minimumLineSpacing
  }
}
