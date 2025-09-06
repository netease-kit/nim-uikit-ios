
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
extension NEKeyboardManager {
  /**    Get all UITextField/UITextView siblings of textFieldView. */
  func responderViews() -> [UIView]? {
    var superConsideredView: UIView?

    // If find any consider responderView in it's upper hierarchy then will get deepResponderView.
    for disabledClass in toolbarPreviousNextAllowedClasses {
      superConsideredView = textFieldView?.neSuperviewOfClassType(disabledClass)
      if superConsideredView != nil {
        break
      }
    }

    // If there is a superConsideredView in view's hierarchy, then fetching all it's subview that
    // responds. No sorting for superConsideredView, it's by subView position.    (Enhancement ID: #22)
    if let view = superConsideredView {
      return view.neDeepResponderViews()
    } else { // Otherwise fetching all the siblings
      guard let textFields = textFieldView?.neResponderSiblings() else {
        return nil
      }

      // Sorting textFields according to behaviour
      switch toolbarManageBehaviour {
      // If autoToolbar behaviour is bySubviews, then returning it.
      case .bySubviews: return textFields

      // If autoToolbar behaviour is by tag, then sorting it according to tag property.
      case .byTag: return textFields.neSortedArrayByTag()

      // If autoToolbar behaviour is by tag, then sorting it according to tag property.
      case .byPosition: return textFields.neSortedArrayByPosition()
      }
    }
  }

  func privateIsEnabled() -> Bool {
    var isEnabled = enable

    let enableMode = textFieldView?.neEnableMode

    if enableMode == .enabled {
      isEnabled = true
    } else if enableMode == .disabled {
      isEnabled = false
    } else if var textFieldViewController = textFieldView?.neViewContainingController() {
      // If it is searchBar textField embedded in Navigation Bar
      if textFieldView?.neTextFieldSearchBar() != nil,
         let navController = textFieldViewController as? UINavigationController,
         let topController = navController.topViewController {
        textFieldViewController = topController
      }

      // If viewController is kind of enable viewController class, then assuming it's enabled.
      if !isEnabled,
         enabledDistanceHandlingClasses
         .contains(where: { textFieldViewController.isKind(of: $0) }) {
        isEnabled = true
      }

      if isEnabled {
        // If viewController is kind of disabled viewController class, then assuming it's disabled.
        if disabledDistanceHandlingClasses
          .contains(where: { textFieldViewController.isKind(of: $0) }) {
          isEnabled = false
        }

        // Special Controllers
        if isEnabled {
          let classNameString = "\(type(of: textFieldViewController.self))"

          // _UIAlertControllerTextFieldViewController
          if classNameString.contains("UIAlertController"),
             classNameString.hasSuffix("TextFieldViewController") {
            isEnabled = false
          }
        }
      }
    }

    return isEnabled
  }

  func privateIsEnableAutoToolbar() -> Bool {
    guard var textFieldViewController = textFieldView?.neViewContainingController() else {
      return enableAutoToolbar
    }

    // If it is searchBar textField embedded in Navigation Bar
    if textFieldView?.neTextFieldSearchBar() != nil,
       let navController = textFieldViewController as? UINavigationController,
       let topController = navController.topViewController {
      textFieldViewController = topController
    }

    var enableToolbar = enableAutoToolbar

    if !enableToolbar,
       enabledToolbarClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
      enableToolbar = true
    }

    if enableToolbar {
      // If found any toolbar disabled classes then return.
      if disabledToolbarClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
        enableToolbar = false
      }

      // Special Controllers
      if enableToolbar {
        let classNameString = "\(type(of: textFieldViewController.self))"

        // _UIAlertControllerTextFieldViewController
        if classNameString.contains("UIAlertController"),
           classNameString.hasSuffix("TextFieldViewController") {
          enableToolbar = false
        }
      }
    }

    return enableToolbar
  }

  func privateShouldResignOnTouchOutside() -> Bool {
    var shouldResign = shouldResignOnTouchOutside

    let enableMode = textFieldView?.neShouldResignOnTouchOutsideMode

    if enableMode == .enabled {
      shouldResign = true
    } else if enableMode == .disabled {
      shouldResign = false
    } else if var textFieldViewController = textFieldView?.neViewContainingController() {
      // If it is searchBar textField embedded in Navigation Bar
      if textFieldView?.neTextFieldSearchBar() != nil,
         let navController = textFieldViewController as? UINavigationController,
         let topController = navController.topViewController {
        textFieldViewController = topController
      }

      // If viewController is kind of enable viewController class, then assuming
      // shouldResignOnTouchOutside is enabled.
      if !shouldResign,
         enabledTouchResignedClasses
         .contains(where: { textFieldViewController.isKind(of: $0) }) {
        shouldResign = true
      }

      if shouldResign {
        // If viewController is kind of disable viewController class, then assuming
        // shouldResignOnTouchOutside is disable.
        if disabledTouchResignedClasses
          .contains(where: { textFieldViewController.isKind(of: $0) }) {
          shouldResign = false
        }

        // Special Controllers
        if shouldResign {
          let classNameString = "\(type(of: textFieldViewController.self))"

          // _UIAlertControllerTextFieldViewController
          if classNameString.contains("UIAlertController"),
             classNameString.hasSuffix("TextFieldViewController") {
            shouldResign = false
          }
        }
      }
    }
    return shouldResign
  }
}
