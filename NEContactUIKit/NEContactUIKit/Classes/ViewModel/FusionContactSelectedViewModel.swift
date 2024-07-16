//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class FusionContactSelectedViewModel: NSObject {
  /// 数据源
  var memberDatas = [NEFusionContactCellModel]()
  /// 选中数据
  var memberSelectedSet = Set<String>()

  /// 通讯里API单例
  var contactRepo = ContactRepo.shared

  /// 获取成员数据
  /// - Parameter filters: 过滤器
  func loadMemberDatas(_ filters: Set<String>? = nil, _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    weak var weakSelf = self
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
    contactRepo.getContactList { friends, error in
      NEALog.infoLog("contact bar getFriendList", desc: "friend count:\(String(describing: friends?.count))")
      weakSelf?.memberDatas.removeAll()
      friends?.forEach { user in
        if let accountId = user.user?.accountId, let filtersSet = filters {
          if filtersSet.contains(accountId) {
            return
          }
        }
        let model = NEFusionContactCellModel()
        model.user = user
        weakSelf?.memberDatas.append(model)
      }
      completion(error as NSError?)
    }
  }

  /// 获取数字人数据
  func loadAIUserData(_ filters: Set<String>? = nil) {
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
