
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
extension UIAlertController {
  class func reconfimAlertView(title: String?, message: String?,
                               confirm: @escaping () -> Void) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: localizable("cancel"), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: localizable("ok"), style: .default) { action in
      confirm()
    })
    return alert
  }
}
