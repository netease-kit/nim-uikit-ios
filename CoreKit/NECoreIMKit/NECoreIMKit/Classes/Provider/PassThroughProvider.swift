// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class PassThroughProvider: NSObject {
  public static let shared = PassThroughProvider()

  override private init() {}

  /// 添加通知对象
  /// - Parameter delegate: 通知对象
  public func addDelegate(delegate: NIMPassThroughManagerDelegate) {
    NIMSDK.shared().passThroughManager.add(delegate)
  }

  /// 移除通知对象
  /// - Parameter delegate: 通知对象
  public func removeDelegate(delegate: NIMPassThroughManagerDelegate) {
    NIMSDK.shared().passThroughManager.remove(delegate)
  }
}
