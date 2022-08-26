
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class NEKitContactConfig: NSObject {
  public static let shared = NEKitContactConfig()

  // contact UI配置相关
  public var ui = ContactUIConfig()
}
