
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

/**
 Uses default keyboard distance for textField.
 */
@available(iOSApplicationExtension, unavailable)
public let kNEUseDefaultKeyboardDistance = CGFloat.greatestFiniteMagnitude

/**
 UIView category for managing UITextField/UITextView
 */
@available(iOSApplicationExtension, unavailable)
@objc public extension UIView {
  private enum NEAssociatedKeys {
    static var keyboardDistanceFromTextField = "keyboardDistanceFromTextField"
    static var ignoreSwitchingByNextPrevious = "ignoreSwitchingByNextPrevious"
    static var enableMode = "enableMode"
    static var shouldResignOnTouchOutsideMode = "shouldResignOnTouchOutsideMode"
  }

  /**
   To set customized distance from keyboard for textField/textView. Can't be less than zero
   */
  var neKeyboardDistanceFromTextField: CGFloat {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.keyboardDistanceFromTextField
      ) as? CGFloat ?? kNEUseDefaultKeyboardDistance
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.keyboardDistanceFromTextField,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   If shouldIgnoreSwitchingByNextPrevious is true then library will ignore this textField/textView while moving to other textField/textView using keyboard toolbar next previous buttons. Default is false
   */
  var neIgnoreSwitchingByNextPrevious: Bool {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.ignoreSwitchingByNextPrevious
      ) as? Bool ??
        false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.ignoreSwitchingByNextPrevious,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   Override Enable/disable managing distance between keyboard and textField behaviour for this particular textField.
   */
  var neEnableMode: NEEnableMode {
    get {
      objc_getAssociatedObject(self, &NEAssociatedKeys.enableMode) as? NEEnableMode ?? .default
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.enableMode,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   Override resigns Keyboard on touching outside of UITextField/View behaviour for this particular textField.
   */
  var neShouldResignOnTouchOutsideMode: NEEnableMode {
    get {
      objc_getAssociatedObject(
        self,
        &NEAssociatedKeys.shouldResignOnTouchOutsideMode
      ) as? NEEnableMode ?? .default
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &NEAssociatedKeys.shouldResignOnTouchOutsideMode,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}
