
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class NENavigationController: UINavigationController {
  override public func viewDidLoad() {
    super.viewDidLoad()
    setUpNavigation()
  }

  func setUpNavigation() {
    if #available(iOS 13.0, *) {
      let appearance = UINavigationBarAppearance()
      appearance.backgroundImage = UIImage()
      appearance.backgroundColor = .white
      appearance.shadowColor = .white
      navigationBar.standardAppearance = appearance
      navigationBar.scrollEdgeAppearance = appearance
    }
  }

  override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if children.count > 0 {
      viewController.hidesBottomBarWhenPushed = true
      if children.count > 1 {
        viewController.hidesBottomBarWhenPushed = false
      }
    }
    super.pushViewController(viewController, animated: true)
  }
}
