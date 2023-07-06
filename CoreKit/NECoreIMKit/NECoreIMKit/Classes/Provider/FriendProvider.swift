
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objc
public protocol FriendProviderDelegate: NSObjectProtocol {
//    Friend relationship changed
  func onFriendChanged(user: User)
  func onUserInfoChanged(user: User)
  func onBlackListChanged()
}

@objcMembers
public class FriendProvider: NSObject, NIMUserManagerDelegate {
  public static let shared = FriendProvider()
  private let mutiDelegate = MultiDelegate<FriendProviderDelegate>(strongReferences: false)
  override private init() {
    super.init()
    NIMSDK.shared().userManager.add(self)
  }

  public func addDelegate(delegate: FriendProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: FriendProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }

  /// 返回我的好友列表
  /// - Returns: 好友列表
  public func myFriends() -> [NIMUser]? {
    NIMSDK.shared().userManager.myFriends()
  }

  /// 获取好友信息
  /// fetch: 是否直接从远端拉取
  /// myFriends: 需要获取信息的好友列表
  /// - Returns: 好友列表
  public func getMyFriends(_ fetch: Bool = false, _ myFriends: [NIMUser]?, _ completion: @escaping ([User]?, NSError?) -> Void) {
    var friendList = [User]()
    guard let friends = myFriends else {
      completion(friendList, nil)
      return
    }

    let myGroup = DispatchGroup()

    if fetch {
      myGroup.enter()
      let userStrs = friends.map { $0.userId ?? "" }
      UserInfoProvider.shared.fetchUserInfo(userStrs) { error, users in
        if let u = users {
          friendList = u
        }
        myGroup.leave()
      }
    } else {
      for friend in friends {
        myGroup.enter()
        getFriendInfo(userId: friend.userId ?? "") { user, error in
          if let _ = user?.userInfo, let u = user {
            friendList.append(u)
          }
          myGroup.leave()
        }
      }
    }

    myGroup.notify(queue: .main) {
      completion(friendList, nil)
    }
  }

  /// 获取好友列表（废弃）
  /// fetch: 是否直接从远端拉取
  /// - Returns: 好友列表
  public func getMyFriends(_ fetch: Bool = false, _ completion: @escaping ([User]?, NSError?) -> Void) {
    var friendList = [User]()
    guard let friends = NIMSDK.shared().userManager.myFriends() else {
      completion(friendList, nil)
      return
    }

    let myGroup = DispatchGroup()

    if fetch {
      myGroup.enter()
      let userStrs = friends.map { $0.userId ?? "" }
      UserInfoProvider.shared.fetchUserInfo(userStrs) { error, users in
        if let u = users {
          friendList = u
        }
        myGroup.leave()
      }
    } else {
      for friend in friends {
        myGroup.enter()
        getFriendInfo(userId: friend.userId ?? "") { user, error in
          if let _ = user?.userInfo, let u = user {
            friendList.append(u)
          }
          myGroup.leave()
        }
      }
    }

    myGroup.notify(queue: .main) {
      completion(friendList, nil)
    }
  }

  /// 获取好友信息
  /// - Parameters:
  ///   - userId:id
  ///   - completion: 回调
  fileprivate func getFriendInfo(userId: String,
                                 _ completion: @escaping (User?, NSError?) -> Void) {
    if let userInfo = UserInfoProvider.shared.getUserInfo(userId: userId) {
      completion(userInfo, nil)
    } else {
      UserInfoProvider.shared.fetchUserInfo([userId]) { error, userInfos in
        if error == nil {
          completion(userInfos?.first, nil)
        } else {
          completion(nil, error)
        }
      }
    }
  }

  /// 从云信服务器批量获取用户资料，返回自定义类型User (废弃接口)
  /// - Parameters:
  ///   - accountList: 用户id集合
  ///   - completion: 成功回调
  fileprivate func fetchUserInfo(accountList: [String],
                                 _ completion: @escaping ([User], NSError?) -> Void) {
    NIMSDK.shared().userManager.fetchUserInfos(accountList) { imUsers, error in
      var users: [User] = []
      for imUser in imUsers ?? [] {
        users.append(User(user: imUser))
      }
      completion(users, error as NSError?)
    }
  }

  /// 从云信服务器批量获取用户资料，返回系统类型的用户信息(NIMUser)
  /// - Parameters:
  ///   - accids: 用户id集合
  ///   - completion: 成功回调
  public func fetchUserInfo(_ accids: [String],
                            _ completion: @escaping (Error?, [NIMUser]?) -> Void) {
    NIMSDK.shared().userManager.fetchUserInfos(accids) { users, error in
      completion(error, users)
    }
  }

//    get user info from local(废弃接口)
  fileprivate func getUserInfo(userId: String) -> User? {
    let imUser = NIMSDK.shared().userManager.userInfo(userId)
    if imUser?.userInfo != nil {
      return User(user: imUser)
    }
    return nil
  }

//  废弃接口，获取本地用户信息
  public func getUserInfoAdvanced(userIds: [String],
                                  _ completion: @escaping ([User], NSError?) -> Void) {
    var ramainIds = [String]()
    var users = [User]()
    for userId in userIds {
      print("get local user info:\(userId)")
      if let user = getUserInfo(userId: userId) {
        users.append(user)
      } else {
        ramainIds.append(userId)
      }
    }
    if !ramainIds.isEmpty {
      print("get remote user info ramainIds:\(ramainIds)")
      fetchUserInfo(accountList: ramainIds) { userArray, error in
        print("get remote user info userArray:\(userArray) error:\(error)")
        for u in userArray {
          users.append(u)
        }
        completion(users, error)
      }
    } else {
      completion(users, nil)
    }
  }

  public func addFriend(request: AddFriendRequest, _ completion: @escaping (NSError?) -> Void) {
    let req = NIMUserRequest()
    req.userId = request.account
    switch request.operationType {
    case .add:
      req.operation = .add
    case .addRequest:
      req.operation = .request
    case .verify:
      req.operation = .verify
    case .reject:
      req.operation = .reject
    }
    req.message = request.meassage
    NIMSDK.shared().userManager.requestFriend(req, completion: { error in
      completion(error as NSError?)
    })
  }

  /// deleteFiend
  /// - Parameters:
  ///   - account: account of user
  public func deleteFriend(account: String, _ deleteAlias: Bool = false,
                           _ completion: @escaping (NSError?) -> Void) {
//        NIMSDK.shared().userManager.deleteFriend(account) { error in
//            completion(error as NSError?)
//        }
    NIMSDK.shared().userManager.deleteFriend(account, removeAlias: deleteAlias) { error in
      completion(error as NSError?)
    }
  }

  public func isFriend(account: String) -> Bool {
    NIMSDK.shared().userManager.isMyFriend(account)
  }

  public func updateUser(_ user: User, _ completion: @escaping (Error?) -> Void) {
    let nimUser = NIMUser()
    nimUser.alias = user.alias
    nimUser.userId = user.userId
    NIMSDK.shared().userManager.update(nimUser) { error in
      completion(error)
    }
  }

//    public func updateMyUserInfo(values:[NSNumber:Any],_ completion:@escaping (NSError?)->Void) -> Void{
//        NIMSDK.shared().userManager.updateMyUserInfo(values) { error in
//            completion(error as? NSError)
//        }
//    }

  /// remove from black list
  public func removeFromBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().userManager.remove(fromBlackBlackList: account) { error in
      print(
        "[coreKitIM] removeFromBlackList error:\(String(describing: error?.localizedDescription))"
      )
      completion(error as NSError?)
    }
  }

  /// add black list
  public func addBlackList(account: String, _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().userManager.add(toBlackList: account) { error in
      print(
        "[coreKitIM] addBlackList error:\(String(describing: error?.localizedDescription))"
      )
      completion(error as NSError?)
    }
  }

  /// add black list
  public func isBlack(account: String) -> Bool {
    NIMSDK.shared().userManager.isUser(inBlackList: account)
  }

  // whether message notification is required
  public func notify(userId: String?) -> Bool {
    if let uid = userId {
      return NIMSDK.shared().userManager.notify(forNewMsg: uid)
    }
    return true
  }

  public func updateNotifyState(_ userId: String, _ notify: Bool,
                                _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().userManager.updateNotifyState(notify, forUser: userId) { error in
      completion(error)
    }
  }

  /// 查找成员
  /// - Parameters:
  ///   - option: 查询条件
  ///   - completion: 完成回调
  public func searchUser(option: NIMUserSearchOption,
                         _ completion: @escaping (NSError?, [NIMUser]?) -> Void) {
    NIMSDK.shared().userManager.searchUser(with: option) { users, error in
      completion(error as NSError?, users)
    }
  }

  // MARK: NIMUserManagerDelegate

  public func onFriendChanged(_ user: NIMUser) {
    print(#file + #function)
    mutiDelegate |> { delegate in
      delegate.onFriendChanged(user: User(user: user))
    }
  }

  public func onBlackListChanged() {
    print(#file + #function + "\(self)")
    mutiDelegate |> { delegate in
      delegate.onBlackListChanged()
    }
  }

  public func onUserInfoChanged(_ user: NIMUser) {
    print(#file + #function)
    mutiDelegate |> { delegate in
      delegate.onUserInfoChanged(user: User(user: user))
    }
  }
}
