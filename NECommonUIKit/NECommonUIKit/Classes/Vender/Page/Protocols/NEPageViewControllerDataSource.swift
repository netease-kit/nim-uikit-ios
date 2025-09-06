// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public protocol NEPageViewControllerDataSource: AnyObject {
  func pageViewController(_ pageViewController: NEPageViewController,
                          viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?

  func pageViewController(_ pageViewController: NEPageViewController,
                          viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
}
