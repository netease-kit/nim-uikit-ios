
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class NEKitConversationConfig: NSObject {
  public static let shared = NEKitConversationConfig()

  // conversation ui 配置
  public var ui = ConversationUIConfig()
}
