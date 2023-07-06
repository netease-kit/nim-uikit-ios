
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
// public protocol UserInfoProviderDelegate: AnyObject {
//
// }

@objcMembers
public class UserInfoProvider: NSObject {
  public static let shared = UserInfoProvider()

  public weak var userDelegate: IUserInfoDelegate?
  private let mutiDelegate = MultiDelegate<IUserInfoDelegate>(strongReferences: false)

  override public init() {}

  public func addDelegate(_ delegate: IUserInfoDelegate) {
    userDelegate = delegate
  }

  public func removeDelegate(_ delegate: IUserInfoDelegate) {
    userDelegate = nil
  }

  /// 从本地获取用户资料
  /// - Parameter userId: 用户id
  /// - Returns: 返回自定义用户信息
  public func getUserInfo(userId: String) -> User? {
    if let delegate = userDelegate {
      return delegate.getUserInfo?(account: userId)
    } else {
      let imUser = NIMSDK.shared().userManager.userInfo(userId)
      if imUser?.userInfo != nil {
        return User(user: imUser)
      }
      return nil
    }
  }

  /// 从云信服务器批量获取用户资料，返回系统类型的用户信息(NIMUser)
  /// - Parameters:
  ///   - accids: 用户id集合
  ///   - completion: 成功回调
  public func fetchUserInfo(_ accids: [String],
                            _ completion: @escaping (NSError?, [User]?) -> Void) {
    if let delegate = userDelegate {
      delegate.fetchUserInfo?(accountList: accids) { imUsers, error in
        completion(error as NSError?, imUsers)
      }

    } else {
      NIMSDK.shared().userManager.fetchUserInfos(accids) { imUsers, error in
        var users: [User] = []
        for imUser in imUsers ?? [] {
          users.append(User(user: imUser))
        }
        completion(error as NSError?, users)
      }
    }
  }

  /// 修改自己的用户资料
  /// - Parameters:
  ///   - values: 需要更新的用户信息键值对
  ///   - completion: 完成回调
  public func updateMyUserInfo(values: [NSNumber: Any],
                               _ completion: @escaping (NSError?) -> Void) {
    if let delegate = userDelegate {
      delegate.updateUserInfo?(values: values, completion: { error in
        completion(error)
      })
    } else {
      NIMSDK.shared().userManager.updateMyUserInfo(values) { error in
        completion(error as? NSError)
      }
    }
  }

  /// return Blacklist
  /// - Returns: Blacklist
  public func getBlacklist() -> [User] {
    var blackList: [User] = []
    guard let blacks = NIMSDK.shared().userManager.myBlackList() else {
      print("[coreKitIM] getBlacklist:\(blackList)")
      return blackList
    }
    print("[coreKitIM] getBlacklist:\(blacks)")
    for black in blacks {
      if let blackUser = getUserInfo(userId: black.userId ?? "") {
        blackList.append(blackUser)
      } else {
        blackList.append(User(user: black))
      }
    }
    return blackList
  }
}
