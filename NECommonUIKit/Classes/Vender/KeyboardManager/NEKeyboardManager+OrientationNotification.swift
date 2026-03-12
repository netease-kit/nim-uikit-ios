
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

// MARK: UIStatusBar Notification methods

@available(iOSApplicationExtension, unavailable)
extension NEKeyboardManager {
  /**  UIApplicationWillChangeStatusBarOrientationNotification. Need to set the textView to it's original position. If any frame changes made. (Bug ID: #92) */
  @objc func willChangeStatusBarOrientation(_ notification: Notification) {
    let currentStatusBarOrientation: UIInterfaceOrientation
    #if swift(>=5.1)
      if #available(iOS 13, *) {
        currentStatusBarOrientation = keyWindow()?.windowScene?
          .interfaceOrientation ?? UIInterfaceOrientation.unknown
      } else {
        currentStatusBarOrientation = UIApplication.shared.statusBarOrientation
      }
    #else
      currentStatusBarOrientation = UIApplication.shared.statusBarOrientation
    #endif

    guard let statusBarOrientation = notification
      .userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
      currentStatusBarOrientation.rawValue != statusBarOrientation else {
      return
    }

    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    // If textViewContentInsetChanged is saved then restore it.
    if let textView = textFieldView as? UITextView,
       textView.responds(to: #selector(getter: UITextView.isEditable)) {
      if isTextViewContentInsetChanged {
        isTextViewContentInsetChanged = false
        if textView.contentInset != startingTextViewContentInsets {
          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              self
                .showLog(
                  "Restoring textView.contentInset to: \(self.startingTextViewContentInsets)"
                )

              // Setting textField to it's initial contentInset
              textView.contentInset = self.startingTextViewContentInsets
              textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets

            },
            completion: { _ in }
          )
        }
      }
    }

    restorePosition()

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }
}
