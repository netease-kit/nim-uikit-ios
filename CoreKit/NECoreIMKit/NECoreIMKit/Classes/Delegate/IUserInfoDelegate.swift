
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

import NIMSDK

/// 发送文本消息的回调
/// @param error
public typealias FetchCallback = ([User]?, NSError?) -> Void

public typealias UpdateCallback = (NSError?) -> Void

@objc
public protocol IUserInfoDelegate: NSObjectProtocol {
  @objc
  optional func getUserInfo(account: String) -> User?

  @objc(fetchUserInfoList:completion:)
  optional func fetchUserInfo(accountList list: [String], completion: FetchCallback?)

  @objc(updateUserInfo:completion:)
  optional func updateUserInfo(values: [NSNumber: Any], completion: UpdateCallback?)
}
