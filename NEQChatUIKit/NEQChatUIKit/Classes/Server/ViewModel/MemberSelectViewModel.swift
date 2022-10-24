// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEQChatKit
import NECoreIMKit

@objc
public protocol MemberSelectViewModelDelegate: NSObjectProtocol {
  func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void)
}

@objcMembers
public class MemberSelectViewModel: NSObject {
  let repo = QChatRepo()

  var datas = [UserInfo]()

  weak var delegate: MemberSelectViewModelDelegate?

  var lastTimeTag: TimeInterval = 0

  let pageSize = 50

  private let className = "MemberSelectViewModel"

  override init() {}

  func loadFirst(serverId: UInt64?, completion: @escaping (NSError?, [UserInfo]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    lastTimeTag = 0
    datas.removeAll()
    print("self?.datas:\(datas.count)")
    getServerMebers(serverId) { [weak self] error, userInfos in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "MemberSelectViewModel"),
        desc: "CALLBACK getServerMebers " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        completion(error as NSError?, userInfos)
      } else {
        if let userArray = userInfos, !userArray.isEmpty {
//                    判断有没设置delegate
          if let del = self?.delegate {
            self?.lastTimeTag = userArray.last?.serverMember?.createTime ?? 0
            var accids = [String]()
            for user in userArray {
              if let accid = user.serverMember?.accid {
                accids.append(accid)
              }
            }
            del.filterMembers(accid: accids) { filterAccids in
              if let filterIds = filterAccids {
                var tmp = [UserInfo]()
                for user in userArray {
                  if filterIds.contains(user.serverMember?.accid ?? "") {
                  } else {
                    tmp.append(user)
                    self?.datas.append(user)
                  }
                }
                completion(error as NSError?, tmp)
              } else {
                self?.datas = userArray
                completion(error as NSError?, userArray)
              }
            }
          } else {
            // 未设置
            self?.datas = userArray
            completion(error as NSError?, userArray)
          }

        } else {
          // 结果为空
          completion(error as NSError?, userInfos)
        }
      }
    }
  }

  func loadMore(serverId: UInt64?, completion: @escaping (NSError?, [UserInfo]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    getServerMebers(serverId) { [weak self] error, userInfos in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "MemberSelectViewModel"),
        desc: "CALLBACK getServerMebers " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        completion(error as NSError?, userInfos)
      } else {
        if var userArray = userInfos, userArray.count > 0 {
          if let del = self?.delegate {
            self?.lastTimeTag = userArray.last?.serverMember?.createTime ?? 0
            var accids = [String]()
            for user in userArray {
              if let accid = user.serverMember?.accid {
                accids.append(accid)
              }
            }

            del.filterMembers(accid: accids) { filterAccids in
              var tmp = [UserInfo]()
              for user in userArray {
                if accids.contains(user.serverMember?.accid ?? "") {
                } else {
                  tmp.append(user)
                  self?.datas.append(user)
                }
              }
              completion(error as NSError?, tmp)
            }
          } else {
            for u in userArray {
              self?.datas.append(u)
            }
            completion(error as NSError?, userArray)
          }

        } else {
          // 结果为空
          completion(error as NSError?, userInfos)
        }
      }
    }
  }

  func getServerMebers(_ serverId: UInt64?,
                       completion: @escaping (NSError?, [UserInfo]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    var param = GetServerMembersByPageParam()
    param.serverId = serverId
    param.timeTag = lastTimeTag
    param.limit = pageSize
    repo.getServerMembers(param) { error, members in
      var memberArray = [UserInfo]()
      members.forEach { member in
        memberArray.append(UserInfo(member))
      }
      completion(error as NSError?, memberArray)
    }
  }
}
