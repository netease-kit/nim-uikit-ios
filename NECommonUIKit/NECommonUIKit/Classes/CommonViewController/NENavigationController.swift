
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
    if #available(iOS 13.0, *) {
      let appearance = UINavigationBarAppearance()
      appearance.backgroundImage = UIImage()
      appearance.backgroundColor = .white
      appearance.shadowColor = UIColor.ne_navLineColor
      navigationBar.standardAppearance = appearance
      navigationBar.scrollEdgeAppearance = appearance
    }
  }

  override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if children.count > 0 {
      viewController.hidesBottomBarWhenPushed = true
      if children.count > 1 {
        viewController.hidesBottomBarWhenPushed = false
      }
    }
    super.pushViewController(viewController, animated: true)
  }

  override open func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
    if children.count > 0 {
      viewController.hidesBottomBarWhenPushed = true
    }
    return super.popToViewController(viewController, animated: animated)
  }
}
