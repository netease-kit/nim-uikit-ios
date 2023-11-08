// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
public class MessageCustomModel: MessageContentModel {
  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .custom
  }
}
