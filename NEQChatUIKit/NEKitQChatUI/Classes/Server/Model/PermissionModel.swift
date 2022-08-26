
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEKitCoreIM

class PermissionModel: NSObject {
  let commonPermission = [
    #keyPath(PermissionModel.managerServer),
    #keyPath(PermissionModel.allChannelProperty),
    #keyPath(PermissionModel.role),
  ]

  let commonPermissionDic = [
    #keyPath(PermissionModel.managerServer): localizable("qchat_manager_server"),
    #keyPath(PermissionModel.allChannelProperty): localizable("qchat_manager_channel"),
    #keyPath(PermissionModel.role): localizable("qchat_manager_role"),
  ]

  @objc var allChannelProperty = ChatPermissionType.manageChannel.rawValue

  @objc var role = ChatPermissionType.manageRole.rawValue

  @objc var managerServer = ChatPermissionType.manageServer.rawValue

  let messagePermission = [#keyPath(PermissionModel.sendMessage)]

  let messagePermissionDic =
    [#keyPath(PermissionModel.sendMessage): localizable("qchat_send_message")]

  @objc var sendMessage = ChatPermissionType.sendMsg.rawValue

//    @objc var deleteOtherMemberMessage = ChatPermissionType.deleteOtherMsg.rawValue
//
//    @objc var recallMessage = ChatPermissionType.revokeMsg.rawValue
//
//    @objc var atAnyMember  = ChatPermissionType.remindOther.rawValue
//
//    @objc var atAllMember = ChatPermissionType.remindAll.rawValue

  /*
   let messagePermission = [#keyPath(PermissionModel.sendMessage),
                            #keyPath(PermissionModel.deleteOtherMemberMessage),
                            #keyPath(PermissionModel.recallMessage),
                            #keyPath(PermissionModel.atAnyMember),
                            #keyPath(PermissionModel.atAllMember)]

   let messagePermissionDic = [#keyPath(PermissionModel.sendMessage):localizable("qchat_send_message"),
                               #keyPath(PermissionModel.deleteOtherMemberMessage):localizable("qchat_delete_message"),
                               #keyPath(PermissionModel.recallMessage):localizable("qchat_recall_message"),
                               #keyPath(PermissionModel.atAnyMember):localizable("qchat_at_any"),
                               #keyPath(PermissionModel.atAllMember):localizable("qchat_at_all")]

   @objc var sendMessage = ChatPermissionType.sendMsg.rawValue

   @objc var deleteOtherMemberMessage = ChatPermissionType.deleteOtherMsg.rawValue

   @objc var recallMessage = ChatPermissionType.revokeMsg.rawValue

   @objc var atAnyMember  = ChatPermissionType.remindOther.rawValue

   @objc var atAllMember = ChatPermissionType.remindAll.rawValue
   */

  let memberPermission = [#keyPath(PermissionModel.modifyOwnServer),
                          #keyPath(PermissionModel.modifyOthersServer),
                          #keyPath(PermissionModel.inviteMember),
                          #keyPath(PermissionModel.kickout),
                          #keyPath(PermissionModel.managerBlackAndWhite)]

  let memberPermissionDic = [
    #keyPath(PermissionModel.modifyOwnServer): localizable("qchat_modify_own_server"),
    #keyPath(PermissionModel.modifyOthersServer): localizable("qchat_modify_other_server"),
    #keyPath(PermissionModel.inviteMember): localizable("qchat_invite_member"),
    #keyPath(PermissionModel.kickout): localizable("qchat_kickout_member"),
    #keyPath(PermissionModel.managerBlackAndWhite): localizable("qchat_manager_channel_list"),
  ]

  @objc var modifyOwnServer = ChatPermissionType.manageServer.rawValue

  @objc var modifyOthersServer = ChatPermissionType.modifyOthersInfoInServer.rawValue

  @objc var inviteMember = ChatPermissionType.inviteToServer.rawValue

  @objc var kickout = ChatPermissionType.kickOthersInServer.rawValue

  @objc var managerBlackAndWhite = ChatPermissionType.manageBlackWhiteList.rawValue

  var changeMap = [String: Bool]()

  override init() {
    super.init()
  }

  func getChangePermission() -> [ChatPermissionType: Bool] {
    var permissions = [ChatPermissionType: Bool]()
    changeMap.forEach { (key: String, v: Bool) in
      if let permissionKey = value(forKey: key) as? String,
         let type = ChatPermissionType(rawValue: permissionKey) {
        permissions[type] = v
      }
    }
    return permissions
  }
}
