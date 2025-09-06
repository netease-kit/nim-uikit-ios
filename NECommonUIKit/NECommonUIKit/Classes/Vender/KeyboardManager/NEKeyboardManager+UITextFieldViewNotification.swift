
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

// MARK: UITextField/UITextView Notifications

@available(iOSApplicationExtension, unavailable)
extension NEKeyboardManager {
  private enum AssociatedKeys {
    static var textFieldView = "textFieldView"
    static var topViewBeginOrigin = "topViewBeginOrigin"
    static var rootViewController = "rootViewController"
    static var rootViewControllerWhilePopGestureRecognizerActive =
      "rootViewControllerWhilePopGestureRecognizerActive"
    static var topViewBeginOriginWhilePopGestureRecognizerActive =
      "topViewBeginOriginWhilePopGestureRecognizerActive"
  }

  /** To save UITextField/UITextView object voa textField/textView notifications. */
  weak var textFieldView: UIView? {
    get {
      (objc_getAssociatedObject(self, &AssociatedKeys.textFieldView) as? WeakObjectContainer)?
        .object as? UIView
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.textFieldView,
        WeakObjectContainer(object: newValue),
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  var topViewBeginOrigin: CGPoint {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.topViewBeginOrigin) as? CGPoint ??
        NEKeyboardManager.kNECGPointInvalid
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.topViewBeginOrigin,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** To save rootViewController */
  weak var rootViewController: UIViewController? {
    get {
      (objc_getAssociatedObject(self,
                                &AssociatedKeys.rootViewController) as? WeakObjectContainer)?
        .object as? UIViewController
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.rootViewController,
        WeakObjectContainer(object: newValue),
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** To overcome with popGestureRecognizer issue Bug ID: #1361 */
  weak var rootViewControllerWhilePopGestureRecognizerActive: UIViewController? {
    get {
      (objc_getAssociatedObject(
        self,
        &AssociatedKeys.rootViewControllerWhilePopGestureRecognizerActive
      ) as? WeakObjectContainer)?.object as? UIViewController
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.rootViewControllerWhilePopGestureRecognizerActive,
        WeakObjectContainer(object: newValue),
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  var topViewBeginOriginWhilePopGestureRecognizerActive: CGPoint {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.topViewBeginOriginWhilePopGestureRecognizerActive
      ) as? CGPoint ?? NEKeyboardManager.kNECGPointInvalid
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.topViewBeginOriginWhilePopGestureRecognizerActive,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /**  UITextFieldTextDidBeginEditingNotification, UITextViewTextDidBeginEditingNotification. Fetching UITextFieldView object. */
  @objc func textFieldViewDidBeginEditing(_ notification: Notification) {
    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    //  Getting object
    textFieldView = notification.object as? UIView

    if overrideKeyboardAppearance, let textInput = textFieldView as? UITextInput,
       textInput.keyboardAppearance != keyboardAppearance {
      // Setting textField keyboard appearance and reloading inputViews.
      if let textFieldView = textFieldView as? UITextField {
        textFieldView.keyboardAppearance = keyboardAppearance
      } else if let textFieldView = textFieldView as? UITextView {
        textFieldView.keyboardAppearance = keyboardAppearance
      }
      textFieldView?.reloadInputViews()
    }

    // If autoToolbar enable, then add toolbar on all the UITextField/UITextView's if required.
    if privateIsEnableAutoToolbar() {
      // UITextView special case. Keyboard Notification is firing before textView notification so we need to
      // resign it first and then again set it as first responder to add toolbar on it.
      if let textView = textFieldView as? UIScrollView,
         textView.responds(to: #selector(getter: UITextView.isEditable)),
         textView.inputAccessoryView == nil {
        UIView.animate(
          withDuration: 0.00001,
          delay: 0,
          options: animationCurve,
          animations: { () in
            self.addToolbarIfRequired()

          },
          completion: { _ in
            // On textView toolbar didn't appear on first time, so forcing textView to reload it's
            // inputViews.
            textView.reloadInputViews()
          }
        )
      } else {
        // Adding toolbar
        addToolbarIfRequired()
      }
    } else {
      removeToolbarIfRequired()
    }

    resignFirstResponderGesture.isEnabled = privateShouldResignOnTouchOutside()
    textFieldView?.window?
      .addGestureRecognizer(resignFirstResponderGesture) //   (Enhancement ID: #14)

    if privateIsEnabled() == false {
      restorePosition()
      topViewBeginOrigin = NEKeyboardManager.kNECGPointInvalid
    } else {
      if topViewBeginOrigin.equalTo(NEKeyboardManager.kNECGPointInvalid) { //  (Bug ID: #5)
        rootViewController = textFieldView?.neParentContainerViewController()

        if let controller = rootViewController {
          if rootViewControllerWhilePopGestureRecognizerActive == controller {
            topViewBeginOrigin = topViewBeginOriginWhilePopGestureRecognizerActive
          } else {
            topViewBeginOrigin = controller.view.frame.origin
          }

          rootViewControllerWhilePopGestureRecognizerActive = nil
          topViewBeginOriginWhilePopGestureRecognizerActive = NEKeyboardManager
            .kNECGPointInvalid

          showLog("Saving \(controller) beginning origin: \(topViewBeginOrigin)")
        }
      }

      // If textFieldView is inside ignored responder then do nothing. (Bug ID: #37, #74, #76)
      // See notes:-
      // https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html If it is UIAlertView textField then do not affect anything (Bug ID: #70).
      if keyboardShowing,
         let textFieldView = textFieldView,
         textFieldView.neIsAlertViewTextField() == false {
        //  keyboard is already showing. adjust position.
        optimizedAdjustPosition()
      }
    }

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }

  /**  UITextFieldTextDidEndEditingNotification, UITextViewTextDidEndEditingNotification. Removing fetched object. */
  @objc func textFieldViewDidEndEditing(_ notification: Notification) {
    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    // Removing gesture recognizer   (Enhancement ID: #14)
    textFieldView?.window?.removeGestureRecognizer(resignFirstResponderGesture)

    // We check if there's a change in original frame or not.

    if let textView = textFieldView as? UIScrollView,
       textView.responds(to: #selector(getter: UITextView.isEditable)) {
      if isTextViewContentInsetChanged {
        isTextViewContentInsetChanged = false

        if textView.contentInset != startingTextViewContentInsets {
          showLog("Restoring textView.contentInset to: \(startingTextViewContentInsets)")

          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              // Setting textField to it's initial contentInset
              textView.contentInset = self.startingTextViewContentInsets
              textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets

            },
            completion: { _ in }
          )
        }
      }
    }

    // Setting object to nil
    textFieldView = nil

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }
}
