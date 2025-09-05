
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

private let NEFlag: Int = 666

public extension UITabBar {
  // MARK: - 显示小红点

  func showBadgOn(index itemIndex: Int, tabbarItemNums: CGFloat = 4.0) {
    // 移除之前的小红点
    removeBadgeOn(index: itemIndex)

    // 创建小红点
    let bageView = UIView()
    bageView.tag = itemIndex + NEFlag
    bageView.layer.cornerRadius = 3
    bageView.backgroundColor = UIColor.red
    bageView.accessibilityIdentifier = "id.bageDot"
    let tabFrame = frame

    // 确定小红点的位置
    let percentX: CGFloat = (CGFloat(itemIndex) + 0.59) / tabbarItemNums
    let x = CGFloat(ceilf(Float(percentX * tabFrame.size.width)))
    let y = CGFloat(ceilf(Float(0.015 * tabFrame.size.height)))
    bageView.frame = CGRect(x: x, y: y, width: 6, height: 6)
    addSubview(bageView)
  }

  func setRedDotView(index ItemIndex: Int) {
    let tabBarItem = items?[ItemIndex]
    tabBarItem?.badgeValue = "·"
    tabBarItem?.badgeColor = .clear
    // 判断是 ipad
    if UIDevice.current.userInterfaceIdiom == .pad {
      tabBarItem?.badgeValue = "●"
    } else {
      tabBarItem?.setBadgeTextAttributes([.foregroundColor: UIColor.red, .font: UIFont.systemFont(ofSize: 50)], for: .normal)
    }
  }

  func hideRedDocView(index ItemIndex: Int) {
    let tabBarItem = items?[ItemIndex]
    tabBarItem?.badgeValue = nil
  }

  // MARK: - 隐藏小红点

  func hideBadg(on itemIndex: Int) {
    // 移除小红点
    removeBadgeOn(index: itemIndex)
  }

  // MARK: - 移除小红点

  private func removeBadgeOn(index itemIndex: Int) {
    // 按照tag值进行移除
    _ = subviews.map {
      if $0.tag == itemIndex + NEFlag {
        $0.removeFromSuperview()
      }
    }
  }

  func setServerBadge(count: String?) {
    let item = items?[1]
    item?.badgeValue = count
  }
}
