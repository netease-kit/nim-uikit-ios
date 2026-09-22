
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

    if animated {
      super.pushViewController(viewController, animated: true)
      return
    }

    // Some iOS 27 layouts apply implicit animations while a destination is
    // loaded during an otherwise non-animated push. Keep the initial layout
    // and the tab bar visibility change in the same disabled transaction.
    UIView.performWithoutAnimation {
      super.pushViewController(viewController, animated: false)
      view.layoutIfNeeded()
      tabBarController?.view.layoutIfNeeded()
      viewController.viewIfLoaded?.layoutIfNeeded()
    }
  }

  override open func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
    if !children.isEmpty {
      viewController.hidesBottomBarWhenPushed = true
    }

    return super.popToViewController(viewController, animated: animated)
  }
}
