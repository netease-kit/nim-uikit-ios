
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

// MARK: Debugging & Developer options

@available(iOSApplicationExtension, unavailable)
public extension NEKeyboardManager {
  private enum AssociatedKeys {
    static var enableDebugging = "enableDebugging"
  }

  @objc var enableDebugging: Bool {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.enableDebugging) as? Bool ?? false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.enableDebugging,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**
   @warning Use below methods to completely enable/disable notifications registered by library internally.
   Please keep in mind that library is totally dependent on NSNotification of UITextField, UITextField, Keyboard etc.
   If you do unregisterAllNotifications then library will not work at all. You should only use below methods if you want to completedly disable all library functions.
   You should use below methods at your own risk.
   */
  @objc func registerAllNotifications() {
    //  Registering for keyboard notification.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardDidShow(_:)),
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardDidHide(_:)),
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )

    //  Registering for UITextField notification.
    registerTextFieldViewClass(
      UITextField.self,
      didBeginEditingNotificationName: UITextField.textDidBeginEditingNotification.rawValue,
      didEndEditingNotificationName: UITextField.textDidEndEditingNotification.rawValue
    )

    //  Registering for UITextView notification.
    registerTextFieldViewClass(
      UITextView.self,
      didBeginEditingNotificationName: UITextView.textDidBeginEditingNotification.rawValue,
      didEndEditingNotificationName: UITextView.textDidEndEditingNotification.rawValue
    )

    //  Registering for orientation changes notification
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(willChangeStatusBarOrientation(_:)),
      name: UIApplication.willChangeStatusBarOrientationNotification,
      object: UIApplication.shared
    )
  }

  @objc func unregisterAllNotifications() {
    //  Unregistering for keyboard notification.
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )

    //  Unregistering for UITextField notification.
    unregisterTextFieldViewClass(
      UITextField.self,
      didBeginEditingNotificationName: UITextField.textDidBeginEditingNotification.rawValue,
      didEndEditingNotificationName: UITextField.textDidEndEditingNotification.rawValue
    )

    //  Unregistering for UITextView notification.
    unregisterTextFieldViewClass(
      UITextView.self,
      didBeginEditingNotificationName: UITextView.textDidBeginEditingNotification.rawValue,
      didEndEditingNotificationName: UITextView.textDidEndEditingNotification.rawValue
    )

    //  Unregistering for orientation changes notification
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.willChangeStatusBarOrientationNotification,
      object: UIApplication.shared
    )
  }

  enum Static {
    static var indentation = 0
  }

  internal func showLog(_ logString: String, indentation: Int = 0) {
    guard enableDebugging else {
      return
    }

    if indentation < 0 {
      Static.indentation = max(0, Static.indentation + indentation)
    }

    var preLog = "NEKeyboardManager"
    for _ in 0 ... Static.indentation {
      preLog += "|\t"
    }

    print(preLog + logString)

    if indentation > 0 {
      Static.indentation += indentation
    }
  }
}
