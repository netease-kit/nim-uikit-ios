
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@available(iOSApplicationExtension, unavailable)
@objc extension UIViewController {
  private enum NEAssociatedKeys {
    static var neLayoutGuideConstraint = "neLayoutGuideConstraint"
  }

  /**
    This method is provided to override by viewController's if the library lifts a viewController which you doesn't want to lift . This may happen if you have implemented side menu feature in your app and the library try to lift the side menu controller. Overriding this method in side menu class to return correct controller should fix the problem.
   */
  open func neParentNEContainerViewController() -> UIViewController? {
    self
  }

  /**
   To set customized distance from keyboard for textField/textView. Can't be less than zero

    @deprecated    Due to change in core-logic of handling distance between textField and keyboard distance, this layout contraint tweak is no longer needed and things will just work out of the box regardless of constraint pinned with safeArea/layoutGuide/superview
   */
  @available(
    *,
    deprecated,
    message: "Due to change in core-logic of handling distance between textField and keyboard distance, this layout contraint tweak is no longer needed and things will just work out of the box regardless of constraint pinned with safeArea/layoutGuide/superview."
  )
  @IBOutlet public var neLayoutGuideConstraint: NSLayoutConstraint? {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.neLayoutGuideConstraint
      ) as? NSLayoutConstraint
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.neLayoutGuideConstraint,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}
