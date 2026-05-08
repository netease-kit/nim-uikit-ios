//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NESubscribeManager: NSObject, NESubscribeListener {
  public static let shared = NESubscribeManager()

  let fileName = "SubscribeCacheFile"

  let subscribeRepo = SubscribeRepo.shared

  /// 订阅分页大小限制，SDK 限制每次订阅不超过100
  let pageLimit = 100

  /// 订阅大小限制，SDK 限制订阅总数不超过 3000
  let totalLimit = 3000

  let workSerialQueue = DispatchQueue(label: "com.ne.subscribe.serialQueue")

  /// 已订阅账号
  private var cacheSet: Set<String> = .init()

  /// 订阅状态缓存，仅订阅总数未超限时有效
  public var cacheDic: [String: V2NIMUserStatus] = .init()

  private var networkBroken = false // 网络断开标志

  override private init() {
    super.init()
    if IMKitConfigCenter.shared.enableOnlineStatus {
      setupCommon()
    }
  }

  /// 初始化
  func setupCommon() {
    weak var weakSelf = self
    workSerialQueue.async {
      if let cacheSet = weakSelf?.loadCache() {
        for accid in Array(cacheSet) {
          weakSelf?.cacheSet.insert(accid)
        }

        // 如果重新启动时候有缓存，证明之前可能发生异常(应用进程在后台被结束，没有从成员列表页返回上一页面等)导致订阅没有取消，需要再做一次取消订阅操作，否则订阅超出上限，导致后续订阅失败
        if cacheSet.count <= 0 {
          return
        }
        let cacheAccounts = Array(cacheSet)
        let chunkAccis = cacheAccounts.chunk(self.pageLimit)
        let queue = DispatchQueue.global()
        let group = DispatchGroup()
        var unSubscribeUserAccis = [String]()
        for accids in chunkAccis {
          group.enter()
          queue.async {
            weakSelf?.subscribeRepo.unsubscribeUserStatus(accids) { failedIds, error in
              let set = Set(failedIds ?? [String]())
              for accid in accids {
                if set.contains(accid) == false {
                  unSubscribeUserAccis.append(accid)
                }
              }
              group.leave()
            }
          }
        }
        group.notify(queue: .main) {
          weakSelf?.deleteAccidsFromCache(unSubscribeUserAccis)
        }
      }
    }

    subscribeRepo.addListener(self)
    IMKitClient.instance.addLoginListener(self)
  }

  /// 获取缓存的订阅内容，仅订阅总数未超限时有效，超限后需重新订阅
  open func getSubscribeStatus(_ accountId: String) -> V2NIMUserStatus? {
    outOfLimit() ? nil : cacheDic[accountId]
  }

  /// 是否已经订阅，仅订阅总数未超限时有效，超限后需重新订阅
  open func hasSubscribe(_ accountId: String) -> Bool {
    outOfLimit() ? false : cacheSet.contains(accountId)
  }

  /// 订阅总数是否超过限制
  open func outOfLimit() -> Bool {
    cacheSet.count > totalLimit
  }

  // 获取应用的 Document 目录路径
  func getDocumentsDirectory() -> URL {
    if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      return documentsPath
    } else {
      fatalError("Unable to access documents directory")
    }
  }

  public func cleanCache() {
    cacheDic.removeAll()
    cacheSet.removeAll()
  }

  /// 保存 Set<String> 到文件
  func saveCache() {
    let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
    let array = Array(cacheSet)
    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: true)
      try data.write(to: filePath)
    } catch {
      print("Error while saving set to file: \(error)")
    }
  }

  /// 从文件加载 Set<String> 到内存
  func loadCache() -> Set<String> {
    let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
    do {
      if FileManager.default.fileExists(atPath: filePath.path) {
        let data = try Data(contentsOf: filePath)
        if let array = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] {
          return Set(array)
        }
      }
    } catch {
      print("Error while loading set from file: \(error)")
    }
    return Set<String>()
  }

  /// 订阅用户在线状态
  /// - Parameter accounts: 要订阅的用户ID
  /// - Parameter completion: 订阅结果回调
  open func subscribeUsersOnlineState(_ accounts: [String], _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    let chunkAccis = accounts.chunk(pageLimit)
    var successIds = [String]()
    let group = DispatchGroup()
    var completionError: NSError?

    for accids in chunkAccis {
      group.enter()
      DispatchQueue.global().async {
        weakSelf?.subscribeRepo.subscribeUserStatus(accids, nil, true) { failedIds, error in
          let set = Set(failedIds ?? [String]())
          for accid in accids {
            if set.contains(accid) == false {
              successIds.append(accid)
            }
          }

          if let err = error {
            completionError = err
          }

          group.leave()
        }
      }
    }

    group.notify(queue: .main) {
      weakSelf?.addAccidsToCache(successIds)
      completion(completionError)
    }
  }

  /// 取消订阅在线状态
  /// - Parameter accounts: 要取消订阅的用户ID
  /// - Parameter completion: 取消订阅结果回调
  open func unSubscribeUsersOnlineState(_ accounts: [String], _ completion: @escaping (NSError?) -> Void) {
    weak var weakSelf = self
    let chunkAccis = accounts.chunk(pageLimit)
    var successIds = [String]()
    let group = DispatchGroup()
    var completionError: NSError?

    for accids in chunkAccis {
      group.enter()
      DispatchQueue.global().async {
        weakSelf?.subscribeRepo.unsubscribeUserStatus(accids) { failedIds, error in
          let set = Set(failedIds ?? [String]())
          for accid in accids {
            if set.contains(accid) == false {
              successIds.append(accid)
            }
          }

          if let err = error {
            completionError = err
          }
          group.leave()
        }
      }
    }

    group.notify(queue: .main) {
      weakSelf?.deleteAccidsFromCache(successIds)
      completion(completionError)
    }
  }

  /// 过滤已经订阅过的用户
  /// - Parameter accounts: 要订阅的用户ID
  /// - Parameter completion: 返回过滤后的用户ID
  open func filterSubscribedUsers(_ accounts: [String], _ completion: @escaping ([String]) -> Void) {
    weak var weakSelf = self
    let chunkAccis = accounts.chunk(pageLimit)
    let queue = DispatchQueue.global()
    let group = DispatchGroup()
    var filiterAccids = [String]()
    for accids in chunkAccis {
      group.enter()
      queue.async {
        weakSelf?.subscribeRepo.queryUserStatusSubscriptions(accids) { results, error in
          if error != nil {
            filiterAccids.append(contentsOf: accids)
          } else {
            if let filterIds = results?.map({ result in
              result.accountId
            }) {
              let filterSet = Set(filterIds)
              for accid in accids {
                if filterSet.contains(accid) == false {
                  filiterAccids.append(accid)
                }
              }
            }
          }
          group.leave()
        }
      }
    }
    group.notify(queue: .main) {
      completion(filiterAccids)
    }
  }

  /// 订阅成功加入缓存记录
  /// - Parameter accids: 订阅成功的用户ID
  open func addAccidsToCache(_ accids: [String]) {
    for accid in accids {
      cacheSet.insert(accid)
    }
    saveCache()
  }

  /// 取消订阅成功移除缓存
  /// - Parameter accids: 取消订阅的用户ID
  open func deleteAccidsFromCache(_ accids: [String]) {
    for accid in accids {
      cacheSet.remove(accid)
      cacheDic.removeValue(forKey: accid)
    }
    saveCache()
  }

  /// 用户状态变更
  /// - Parameter data: 用户状态列表
  public func onUserStatusChanged(_ data: [V2NIMUserStatus]) {
    for d in data {
      cacheDic[d.accountId] = d
    }
  }
}

// MARK: - NEIMKitClientListener

extension NESubscribeManager: NEIMKitClientListener {
  /// 登录连接状态回调
  /// - Parameter status: 连接状态
  open func onConnectStatus(_ status: V2NIMConnectStatus) {
    if status == .CONNECT_STATUS_WAITING {
      networkBroken = true
    }

    if status == .CONNECT_STATUS_CONNECTED, networkBroken {
      networkBroken = false
      cleanCache()
    }
  }

  ///  登录状态变更回调
  ///  - Parameter status: 登录状态
  open func onLoginStatus(_ status: V2NIMLoginStatus) {
    if status == .LOGIN_STATUS_LOGOUT {
      cleanCache()
    }
  }

  /// 被踢下线回调
  /// - Parameter detail: 被踢下线的详细信息
  open func onKickedOffline(_ detail: V2NIMKickedOfflineDetail) {
    cleanCache()
  }
}
