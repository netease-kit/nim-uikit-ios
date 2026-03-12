// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class NEAlertViewController {
  static var alterWindow: UIWindow?

  public class func presentAlertViewController(_ title: String?, messageContent: String?, cancelTitle: String?, confirmTitle: String?, cancelComplete: (() -> Void)? = nil, confirmComplete: (() -> Void)? = nil) {
    let alertVC = UIAlertController(title: title, message: messageContent, preferredStyle: .alert)
    if let cancelTitle = cancelTitle {
      let cancelActon = UIAlertAction(title: cancelTitle, style: .cancel) { action in
        alterWindow?.resignKey()
        alterWindow = nil
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        if let cancelComplete = cancelComplete {
          cancelComplete()
        }
      }
      alertVC.addAction(cancelActon)
    }

    if let confirmTitle = confirmTitle {
      let confirmActon = UIAlertAction(title: confirmTitle, style: .default) { action in
        alterWindow?.resignKey()
        alterWindow = nil
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        if let confirmComplete = confirmComplete {
          confirmComplete()
        }
      }
      alertVC.addAction(confirmActon)
    }
    DispatchQueue.main.async {
      alterWindow = UIWindow(frame: UIScreen.main.bounds)
      alterWindow?.rootViewController = UIViewController()
      alterWindow?.windowLevel = .normal
      alterWindow?.makeKeyAndVisible()
      alterWindow?.rootViewController?.present(alertVC, animated: true)
    }
  }

  public class func removePresentAlertViewController() {
    alterWindow?.resignKey()
    alterWindow = nil
    UIApplication.shared.keyWindow?.makeKeyAndVisible()
  }
}
