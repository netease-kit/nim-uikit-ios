// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol NEPageViewManagerDataSource: AnyObject {
  func viewControllerBefore(_ viewController: UIViewController) -> UIViewController?
  func viewControllerAfter(_ viewController: UIViewController) -> UIViewController?
}
