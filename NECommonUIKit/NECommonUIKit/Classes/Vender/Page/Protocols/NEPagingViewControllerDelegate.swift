// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public protocol NEPagingViewControllerDelegate: AnyObject {
  func pagingViewController(_: NEPagingViewController,
                            isScrollingFromItem currentPagingItem: NEPagingItem,
                            toItem upcomingPagingItem: NEPagingItem?,
                            startingViewController: UIViewController,
                            destinationViewController: UIViewController?,
                            progress: CGFloat)

  func pagingViewController(_: NEPagingViewController,
                            willScrollToItem pagingItem: NEPagingItem,
                            startingViewController: UIViewController,
                            destinationViewController: UIViewController)

  func pagingViewController(_ pagingViewController: NEPagingViewController,
                            didScrollToItem pagingItem: NEPagingItem,
                            startingViewController: UIViewController?,
                            destinationViewController: UIViewController,
                            transitionSuccessful: Bool)

  func pagingViewController(_ pagingViewController: NEPagingViewController,
                            didSelectItem pagingItem: NEPagingItem)
}
