
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/**
 UIView hierarchy category.
 */
@available(iOSApplicationExtension, unavailable)
@objc public extension UIView {
  // MARK: viewControllers

  /**
   Returns the UIViewController object that manages the receiver.
   */
  func neViewContainingController() -> UIViewController? {
    var nextResponder: UIResponder? = self

    repeat {
      nextResponder = nextResponder?.next

      if let viewController = nextResponder as? UIViewController {
        return viewController
      }

    } while nextResponder != nil

    return nil
  }

  /**
   Returns the topMost UIViewController object in hierarchy.
   */
  func neTopMostController() -> UIViewController? {
    var controllersHierarchy = [UIViewController]()

    if var topController = window?.rootViewController {
      controllersHierarchy.append(topController)

      while let presented = topController.presentedViewController {
        topController = presented

        controllersHierarchy.append(presented)
      }

      var matchController: UIResponder? = neViewContainingController()

      while let mController = matchController as? UIViewController,
            controllersHierarchy.contains(mController) == false {
        repeat {
          matchController = matchController?.next

        } while matchController != nil && matchController is UIViewController == false
      }

      return matchController as? UIViewController

    } else {
      return neViewContainingController()
    }
  }

  /**
   Returns the UIViewController object that is actually the parent of this object. Most of the time it's the viewController object which actually contains it, but result may be different if it's viewController is added as childViewController of another viewController.
   */
  func neParentContainerViewController() -> UIViewController? {
    var matchController = neViewContainingController()
    var parentContainerViewController: UIViewController?

    if var navController = matchController?.navigationController {
      while let parentNav = navController.navigationController {
        navController = parentNav
      }

      var parentController: UIViewController = navController

      while let parent = parentController.parent,
            parent.isKind(of: UINavigationController.self) == false,
            parent.isKind(of: UITabBarController.self) == false,
            parent.isKind(of: UISplitViewController.self) == false {
        parentController = parent
      }

      if navController == parentController {
        parentContainerViewController = navController.topViewController
      } else {
        parentContainerViewController = parentController
      }
    } else if let tabController = matchController?.tabBarController {
      if let navController = tabController.selectedViewController as? UINavigationController {
        parentContainerViewController = navController.topViewController
      } else {
        parentContainerViewController = tabController.selectedViewController
      }
    } else {
      while let parentController = matchController?.parent,
            parentController.isKind(of: UINavigationController.self) == false,
            parentController.isKind(of: UITabBarController.self) == false,
            parentController.isKind(of: UISplitViewController.self) == false {
        matchController = parentController
      }

      parentContainerViewController = matchController
    }

    let finalController = parentContainerViewController?
      .neParentNEContainerViewController() ?? parentContainerViewController

    return finalController
  }

  // MARK: Superviews/Subviews/Siglings

  /**
   Returns the superView of provided class type.

    @param classType class type of the object which is to be search in above hierarchy and return

    @param belowView view object in upper hierarchy where method should stop searching and return nil
   */
  func neSuperviewOfClassType(_ classType: UIView.Type, belowView: UIView? = nil) -> UIView? {
    var superView = superview

    while let unwrappedSuperView = superView {
      if unwrappedSuperView.isKind(of: classType) {
        // If it's UIScrollView, then validating for special cases
        if unwrappedSuperView.isKind(of: UIScrollView.self) {
          let classNameString = "\(type(of: unwrappedSuperView.self))"

          //  If it's not UITableViewWrapperView class, this is internal class which is actually
          //  manage in UITableview. The speciality of this class is that it's superview is UITableView.
          //  If it's not UITableViewCellScrollView class, this is internal class which is actually
          //  manage in UITableviewCell. The speciality of this class is that it's superview is
          //  UITableViewCell.
          // If it's not _UNEueuingScrollView class, actually we validate for _ prefix which usually
          // used by Apple internal classes
          if unwrappedSuperView.superview?.isKind(of: UITableView.self) == false,
             unwrappedSuperView.superview?.isKind(of: UITableViewCell.self) == false,
             classNameString.hasPrefix("_") == false {
            return superView
          }
        } else {
          return superView
        }
      } else if unwrappedSuperView == belowView {
        return nil
      }

      superView = unwrappedSuperView.superview
    }

    return nil
  }

  /**
   Returns all siblings of the receiver which canBecomeFirstResponder.
   */
  internal func neResponderSiblings() -> [UIView] {
    // Array of (UITextField/UITextView's).
    var tempTextFields = [UIView]()

    //	Getting all siblings
    if let siblings = superview?.subviews {
      for textField in siblings {
        if textField == self || textField.neIgnoreSwitchingByNextPrevious == false,
           textField.neCanBecomeFirstResponder() {
          tempTextFields.append(textField)
        }
      }
    }

    return tempTextFields
  }

  /**
   Returns all deep subViews of the receiver which canBecomeFirstResponder.
   */
  internal func neDeepResponderViews() -> [UIView] {
    // Array of (UITextField/UITextView's).
    var textfields = [UIView]()

    for textField in subviews {
      if textField == self || textField.neIgnoreSwitchingByNextPrevious == false,
         textField.neCanBecomeFirstResponder() {
        textfields.append(textField)
      }
      // Sometimes there are hidden or disabled views and textField inside them still recorded, so we added
      // some more validations here (Bug ID: #458)
      // Uncommented else (Bug ID: #625)
      else if textField.subviews.count != 0, isUserInteractionEnabled, !isHidden,
              alpha != 0.0 {
        for deepView in textField.neDeepResponderViews() {
          textfields.append(deepView)
        }
      }
    }

    // subviews are returning in opposite order. Sorting according the frames 'y'.
    return textfields.sorted(by: { (view1: UIView, view2: UIView) -> Bool in
      let frame1 = view1.convert(view1.bounds, to: self)
      let frame2 = view2.convert(view2.bounds, to: self)

      if frame1.minY != frame2.minY {
        return frame1.minY < frame2.minY
      } else {
        return frame1.minX < frame2.minX
      }
    })
  }

  private func neCanBecomeFirstResponder() -> Bool {
    var NEcanBecomeFirstResponder = false

    if conforms(to: UITextInput.self) {
      //  Setting toolbar to keyboard.
      if let textView = self as? UITextView {
        NEcanBecomeFirstResponder = textView.isEditable
      } else if let textField = self as? UITextField {
        NEcanBecomeFirstResponder = textField.isEnabled
      }
    }

    if NEcanBecomeFirstResponder {
      NEcanBecomeFirstResponder = isUserInteractionEnabled && !isHidden && alpha != 0.0 &&
        !neIsAlertViewTextField() && neTextFieldSearchBar() == nil
    }

    return NEcanBecomeFirstResponder
  }

  // MARK: Special TextFields

  /**
    Returns searchBar if receiver object is UISearchBarTextField, otherwise return nil.
   */
  internal func neTextFieldSearchBar() -> UISearchBar? {
    var responder: UIResponder? = next

    while let bar = responder {
      if let searchBar = bar as? UISearchBar {
        return searchBar
      } else if bar is UIViewController {
        break
      }

      responder = bar.next
    }

    return nil
  }

  /**
   Returns YES if the receiver object is UIAlertSheetTextField, otherwise return NO.
   */
  internal func neIsAlertViewTextField() -> Bool {
    var alertViewController: UIResponder? = neViewContainingController()

    var isAlertViewTextField = false

    while let controller = alertViewController, !isAlertViewTextField {
      if controller.isKind(of: UIAlertController.self) {
        isAlertViewTextField = true
        break
      }

      alertViewController = controller.next
    }

    return isAlertViewTextField
  }

  private func neDepth() -> Int {
    var depth = 0

    if let superView = superview {
      depth = superView.neDepth() + 1
    }

    return depth
  }
}

@available(iOSApplicationExtension, unavailable)
extension NSObject {
  func _NEDescription() -> String {
    "<\(self) \(Unmanaged.passUnretained(self).toOpaque())>"
  }
}
