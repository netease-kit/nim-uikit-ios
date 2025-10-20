
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NENavigationController: UINavigationController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    setUpNavigation()
  }

  func setUpNavigation() {
    let appearance = UINavigationBarAppearance()
    appearance.backgroundImage = UIImage()
    appearance.backgroundColor = .white
    appearance.shadowColor = UIColor.ne_navLineColor
    navigationBar.standardAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
  }

  override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if !children.isEmpty {
      viewController.hidesBottomBarWhenPushed = true
    }

    super.pushViewController(viewController, animated: animated)
  }

  override open func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
    if !children.isEmpty {
      viewController.hidesBottomBarWhenPushed = true
    }

    return super.popToViewController(viewController, animated: animated)
  }
}
