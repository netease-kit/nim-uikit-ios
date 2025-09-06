// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public protocol NEPageViewControllerDelegate: AnyObject {
  func pageViewController(_ pageViewController: NEPageViewController,
                          willStartScrollingFrom startingViewController: UIViewController,
                          destinationViewController: UIViewController)

  func pageViewController(_ pageViewController: NEPageViewController,
                          isScrollingFrom startingViewController: UIViewController,
                          destinationViewController: UIViewController?,
                          progress: CGFloat)

  func pageViewController(_ pageViewController: NEPageViewController,
                          didFinishScrollingFrom startingViewController: UIViewController,
                          destinationViewController: UIViewController,
                          transitionSuccessful: Bool)
}
