
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public enum OperationType: Int {
//    添加好友 直接添加为好友,无需验证
  case add
//    请求添加好友
  case addRequest
//    通过添加好友请求
  case verify
//    拒绝添加好友请求
  case reject
}

@objcMembers
public class AddFriendRequest: NSObject {
  public var account: String = ""
  public var operationType: OperationType = .add
  public var meassage: String?

//    convenience public init(account: String, operationType: OperationType, message: String?) {
//        self.account = account
//        self.operationType = operationType
//        self.meassage = message
//    }
}
