
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class IMKitLoginManager: NSObject {
  public static let instance = IMKitLoginManager()

  /// 踢人
  /// - Parameters:
  ///   - client: 当前登录的其他客户端
  ///   - comletion: 完成回调
  public func kickOtherClient(client: NIMLoginClient, comletion: @escaping (Error?) -> Void) {
    NIMSDK.shared().loginManager.kickOtherClient(client, completion: comletion)
  }

  /// 返回当前登录帐号
  /// - Returns: 当前登录帐号,如果没有登录成功,这个地方会返回空字符串""
  public func currentAccount() -> String {
    NIMSDK.shared().loginManager.currentAccount()
  }

  /// 当前登录状态
  /// - Returns: 当前登录状态
  public func isLogined() -> Bool {
    NIMSDK.shared().loginManager.isLogined()
  }

  /// 当前 SDK 鉴权模式
  /// - Returns: 当前 SDK 鉴权模式
  public func currentAuthMode() -> NIMSDKAuthMode {
    NIMSDK.shared().loginManager.currentAuthMode()
  }

  /// 返回当前登录的设备列表
  /// - Returns: 当前登录设备列表 内部是NIMLoginClient,不包括自己
  public func currentLoginClients() -> [NIMLoginClient]? {
    NIMSDK.shared().loginManager.currentLoginClients()
  }

  /// 查询服务器时间
  /// - Parameter completion: 回调
  public func queryServerTime(_ completion: @escaping (Error?, NIMServerTime) -> Void) {
    NIMSDK.shared().loginManager.queryServerTimeCompletion(completion)
  }

  /// 添加代理
  /// - Parameter delegate: 代理
  public func addDelegate(delegate: NIMLoginManagerDelegate) {
    NIMSDK.shared().loginManager.add(delegate)
  }

  /// 移除代理
  /// - Parameter delegate: 代理
  public func removeDelegate(delegate: NIMLoginManagerDelegate) {
    NIMSDK.shared().loginManager.remove(delegate)
  }
}
