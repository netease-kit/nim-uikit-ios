//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

protocol TeamMembersViewModelDelegate: NSObject {
  func didNeedRefreshUI()
}

class TeamMembersViewModel: NSObject {
  weak var delegate: TeamMembersViewModelDelegate?

  var datas = [TeamMemberInfoModel]()

  let repo = TeamRepo.shared
  public var currentMember: NIMTeamMember?

  func getMemberInfo(_ teamId: String) {
    currentMember = repo.getMemberInfo(IMKitClient.instance.imAccid(), teamId)
  }

  func removeTeamMember(_ teamdId: String, _ uids: [String], _ completion: @escaping (NSError?) -> Void) {
    repo.removeMembers(teamdId, uids) { error in
      completion(error as NSError?)
    }
  }

  func setShowDatas(_ memberDatas: [TeamMemberInfoModel]?) {
    var owner: TeamMemberInfoModel?
    var managers = [TeamMemberInfoModel]()
    var normalMembers = [TeamMemberInfoModel]()

    memberDatas?.forEach { model in
      if model.teamMember?.type == .owner {
        owner = model
      } else if model.teamMember?.type == .manager {
        managers.append(model)
      } else {
        normalMembers.append(model)
      }
    }

    datas.removeAll()
    if let findOwner = owner {
      datas.append(findOwner)
    }
    // managers 根据 时间排序 排序
    managers.sort { model1, model2 in
      if let time1 = model1.teamMember?.createTime, let time2 = model2.teamMember?.createTime {
        return time2 > time1
      }
      return false
    }
    // normalMembers 根据 时间排序 排序
    normalMembers.sort { model1, model2 in
      if let time1 = model1.teamMember?.createTime, let time2 = model2.teamMember?.createTime {
        return time2 > time1
      }
      return false
    }
    datas.append(contentsOf: managers)
    datas.append(contentsOf: normalMembers)
    delegate?.didNeedRefreshUI()
  }

  func removeModel(_ model: TeamMemberInfoModel?) {
    guard let rmModel = model else {
      return
    }
    datas.removeAll(where: { model in
      if let rmUid = rmModel.nimUser?.userId, let uid = model.nimUser?.userId {
        if rmUid == uid {
          return true
        }
      }
      return false
    })
  }
}
