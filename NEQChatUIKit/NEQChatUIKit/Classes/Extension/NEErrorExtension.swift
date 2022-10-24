
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
extension NSError {
  class func paramError() -> NSError {
    NSError(
      domain: "com.qchat.doamin",
      code: 600,
      userInfo: ["message": localizable("param_error")]
    )
  }
}
