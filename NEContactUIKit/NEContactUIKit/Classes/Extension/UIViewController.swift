
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

extension UIViewController {
  typealias AlertCallBack = () -> Void
  func showAlert(title: String = localizable("alert_tip"), message: String?,
                 sureText: String = localizable("alert_sure"),
                 cancelText: String = localizable("alert_cancel"),
                 _ sureBack: @escaping AlertCallBack, cancelBack: AlertCallBack? = nil) {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )

    let cancelAction = UIAlertAction(title: cancelText, style: .default) { action in
      if let block = cancelBack {
        block()
      }
    }
    alertController.addAction(cancelAction)
    let sureAction = UIAlertAction(title: sureText, style: .default) { action in
      sureBack()
    }
    alertController.addAction(sureAction)
    present(alertController, animated: true, completion: nil)
  }
}
