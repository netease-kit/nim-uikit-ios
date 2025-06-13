//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

public typealias FusionContactCallBack = (NSError?) -> Void

@objcMembers
open class FusionContactSelectedViewModel: NSObject {
  /// 数据源
  var memberDatas = [NEFusionContactCellModel]()
  /// 选中数据
  var memberSelectedSet = Set<String>()

  /// 通讯里API单例
  var contactRepo = ContactRepo.shared

  override public init() {
    super.init()
  }

  /// 获取成员数据
  /// - Parameter filters: 过滤器
  open func loadMemberDatas(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)

    // 优选从缓存中取
    if !NEFriendUserCache.shared.isEmpty() {
      var friends = NEFriendUserCache.shared.getFriendListNotInBlocklist().map(\.value)
      friends.sort { model1, model2 in
        if let time1 = model1.friend?.createTime, let time2 = model2.friend?.createTime {
          return time2 > time1
        }
        return false
      }
      memberDatas.removeAll()
      for user in friends {
        if let accountId = user.user?.accountId, let filtersSet = filters {
          if filtersSet.contains(accountId) {
            continue
          }
        }
        let model = NEFusionContactCellModel()
        model.user = user
        memberDatas.append(model)
      }
      completion(nil)
      return
    }

    // 缓存中没有则远端查询, 刷新统一走缓存通知
    contactRepo.getContactList { friends, error in
      NEALog.infoLog("contact bar getFriendList", desc: "friend count:\(String(describing: friends?.count))")
    }
  }

  /// 获取数字人数据
  open func loadAIUserData(_ filters: Set<String>? = nil) {
    let aiUsers = NEAIUserManager.shared.getAllAIUsers()
    for aiUser in aiUsers {
      if let accountId = aiUser.accountId {
        if filters?.contains(accountId) ?? false {
          continue
        }
        let model = NEFusionContactCellModel()
        model.aiUser = aiUser
        memberDatas.append(model)
      }
    }
  }
}
