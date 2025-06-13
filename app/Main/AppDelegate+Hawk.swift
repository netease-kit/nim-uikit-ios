// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import Hawk
import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK

enum MethodCases: String {
  case startLogin
  case startLogout
  case enterContact
  case enterConversation
  case clickContactFriend
  case clickUserPageChat
  case clickUserPageDelete
  case clickUserPageAdd
  case pressBack
  case waitForTime
  case enterNotificationPage
  case clickNotificationAgree
  case clickNotificationClear
  case searchUser
  case enterSearchContact
  case searchContact
  case enterAddFriend
  case enterCreateGroup
  case enterCreateAdvance
  case selectFriend
  case clickSureToCreate
  case clickConversation
  case inputSendMsg
  case sendMsg
  case clickAddBlackList
  case enterBlackList
  case enterMyGroup
  case clickRemoveBlackList
  case assetView
  case assertChatMessage
  case clickSureDeleteFriend
  case clickSureExitGroup
  case clickSureDismissTeam
  case clickSureExitTeam
  case clickViewWithText
  case clickChatSetting
  case quitTeam
  case dismissTeam
  case deleteConversation
  case enterEditUserInfoPage
  case updateSignature
  case assertSignature
  case enterMinePage
  case clearEditText
  case updateEmail
  case assertEmail
  case updatePhone
  case assertPhone
  case updateNickname
  case assertNickname
  case assertSex
  case enterAboutNetEasePage
  case assertVersion
  case updateCommentName
  case enterInviteGroup
  case updateNicknameInTeam
  case enterTeamMember
  case assertMemberName
  case enterEditGroup
  case updateGroupName
  case assertGroupName
  case assertCommentName
  case makeSureCreateGroup
}

extension AppDelegate {
  func setupHawk() {
    let config = NEHawkConfig()
    config.applicationName = "IMUIKit UI"
    if let version = Bundle.main
      .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
      config.version = version
    }
    config.deviceIdMap = NETestDevice()
    config.isUITest = true
    NEHawkManager.shared().managerConfig(config)
    NEHawkManager.shared().uiDelegate = self
    NEHawkManager.shared().execute()
  }
}

extension AppDelegate: NEHawkUICustomHandler {
  func hawkManager(_ manager: NEHawkManager, handleCase caseModel: NECaseModel) {
    // 需要特殊处理的 case
    let contactRepo = ContactRepo.shared
    if caseModel.className == "IMKitHelper" {
      // 清理好友：移除黑名单、删除备注、仅保留 uidList 中的好友
      if caseModel.methodName == "clearFriendInfo",
         let uidList = caseModel.params[0]["uidList"] as? [String] {
        // 查询黑名单并移除
        contactRepo.getBlockList { blackList, error in
          let blackListUids = blackList?.compactMap(\.user?.accountId)
          blackListUids?.forEach { uid in
            contactRepo.removeBlockList(accountId: uid) { error in
              if let err = error {
                print("移除黑名单(\(uid))失败：\(err.localizedDescription)")
              }
            }
          }
        }

        // 查询好友列表
        contactRepo.getContactList { users, error in
          if let userIds = users?.compactMap(\.user?.accountId) {
            // 删除所有好友(默认会删除备注)
            for uid in userIds {
              SettingRepo.shared.setP2PMessageMuteMode(accountId: uid, muteMode: .NIM_P2P_MESSAGE_MUTE_MODE_OFF) { error in
                if let err = error {
                  print("关闭免打扰(\(uid))失败：\(err.localizedDescription)")
                }
              }

              if !uidList.contains(uid) {
                let params = V2NIMFriendDeleteParams()
                params.deleteAlias = true
                contactRepo.deleteFriend(account: uid, params: params) { error in
                  if let err = error {
                    print("删除好友(\(uid))失败：\(err.localizedDescription)")
                  } else {
                    NEFriendUserCache.shared.removeFriendInfo(uid)
                  }
                }
              }
            }

            // 添加好友
            for uid in uidList {
              let params = V2NIMFriendAddParams()
              params.addMode = .FRIEND_MODE_TYPE_ADD
              contactRepo.addFriend(accountId: uid, params: params) { error in
                if let err = error {
                  print("添加好友(\(uid))失败：\(err.localizedDescription)")
                }
              }
            }

            NEHawkManager.shared().sendMessage(caseModel)
          }
        }

        return
      }

      // 清理消息和群聊：清空消息、清空会话、仅保留 teamNameList 中同名的群聊
      if caseModel.methodName == "clearAccount",
         let uidList = caseModel.params[0]["uidList"] as? [String],
         let teamNameList = caseModel.params[1]["teamNameList"] as? [String] {
        let conversationRepo = ConversationRepo.shared
        let chatRepo = ChatRepo.shared
        let teamRepo = TeamRepo.shared

        // 清空 uidList 消息和标记列表
        for uid in uidList {
          guard let conversationId = V2NIMConversationIdUtil.p2pConversationId(uid) else {
            continue
          }

          // 清空标记
          chatRepo.getPinnedMessageList(conversationId: conversationId) { pinList, error in
            if let pinItems = pinList {
              for pinItem in pinItems {
                if let messageRefer = pinItem.messageRefer {
                  chatRepo.unpinMessage(messageRefer: messageRefer, serverExtension: "") { error in
                    if let err = error {
                      print("清空标记(\(conversationId))失败：\(err.localizedDescription)")
                    }
                  }
                }
              }
            }
          }

          // 清空消息
          let option = V2NIMClearHistoryMessageOption()
          option.conversationId = conversationId
          option.deleteRoam = true
          option.onlineSync = true
          chatRepo.clearHistoryMessage(option: option) { error in
            if let err = error {
              print("清空消息(\(uid))失败：\(err.localizedDescription)")
            }
          }
        }

        // 查询会话列表
        conversationRepo.getConversationList(0, 200) { conversations, offset, finished, error in
          if let conversations = conversations {
            for conversation in conversations {
              // 删除所有会话
              conversationRepo.deleteConversation(conversation.conversationId, true) { error in
                if let err = error {
                  print("删除所有会话失败：\(err.localizedDescription)")
                }
              }
            }
          }
        }

        // 查询群聊列表
        teamRepo.getTeamList { teamList, error in
          teamList?.forEach { team in
            // 删除多的群聊
            if let teamName = team.teamName,
               !teamNameList.contains(teamName),
               let tid = team.teamId {
              if team.owner == IMKitClient.instance.account() {
                teamRepo.dismissTeam(tid) { error in
                  if let err = error {
                    print("解散群聊(\(tid))失败：\(err.localizedDescription)")
                  }
                }
              } else {
                teamRepo.leaveTeam(tid) { error in
                  if let err = error {
                    print("退出群聊(\(tid))失败：\(err.localizedDescription)")
                  }
                }
              }
            }
          }
        }

        NEHawkManager.shared().sendMessage(caseModel)
        return
      }
    }

    var actions: [NEHawkElementAction]?
    switch caseModel.methodName {
    case MethodCases.startLogin.rawValue: // 登录
      if let account = caseModel.params[0]["phone"] as? String,
         let password = caseModel.params[1]["verifyCode"] as? String {
        actions = startLogin(account, password: password)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.startLogout.rawValue: // 退出登录
      actions = startLogout()
    case MethodCases.enterContact.rawValue: // 进入通讯录
      actions = enterContact()
    case MethodCases.clickContactFriend.rawValue: // 点击通讯录好友
      if let accountName = caseModel.params[0]["accountName"] as? String {
        actions = clickContactFriend(accountName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.clickUserPageChat.rawValue: // 用户信息页 点击聊天按钮
      actions = clickUserPageChat()
    case MethodCases.clickUserPageDelete.rawValue: // 用户信息页 删除好友
      actions = clickUserPageDelete()
    case MethodCases.clickUserPageAdd.rawValue: // 添加好友
      actions = clickUserPageAdd()
    case MethodCases.pressBack.rawValue: // 返回上一级
      actions = pressBack()
    case MethodCases.enterNotificationPage.rawValue: // 验证消息
      actions = enterNotificationPage()
    case MethodCases.clickNotificationAgree.rawValue: // 点击系统通知页面同意
      actions = clickNotificationAgree()
    case MethodCases.clickNotificationClear.rawValue: // 系统通知页面 清空按钮
      actions = clickNotificationClear()
    case MethodCases.searchUser.rawValue: // 输入id 搜索好友
      if let account = caseModel.params[0]["account"] as? String {
        actions = searchUser(account)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterSearchContact.rawValue: // 从通讯录进入好友搜索界面
      actions = enterSearchContact()
    case MethodCases.searchContact.rawValue: // 好友搜索页面 搜索
      if let searchText = caseModel.params[0]["searchText"] as? String {
        actions = searchContact(searchText)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterAddFriend.rawValue: // 通讯录 进入 好友添加页面
      actions = enterAddFriend()
    case MethodCases.enterCreateGroup.rawValue: // 创建群组
      actions = enterCreateGroup()
    case MethodCases.enterCreateAdvance.rawValue: // 创建高级群
      actions = enterCreateAdvance()
    case MethodCases.selectFriend.rawValue: // 创建群中人员选择
      if let accountList = caseModel.params[0]["accountList"] as? [String] {
        actions = selectFriend(accountList)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.clickSureToCreate.rawValue: // 确定创建群
      actions = clickSureToCreate()
    case MethodCases.clickConversation.rawValue: // 点击会话
      if let conversationName = caseModel.params[0]["conversationName"] as? String {
        actions = clickConversation(conversationName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.inputSendMsg.rawValue: // 聊天室输入发送文字
      if let sendTest = caseModel.params[0]["sendTest"] as? String {
        actions = inputSendMsg(sendTest)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.sendMsg.rawValue: // 发送消息
      actions = sendMsg()
    case MethodCases.clickAddBlackList.rawValue: // 添加黑名单
      actions = clickAddBlackList()
    case MethodCases.enterBlackList.rawValue: // 进入黑名单
      actions = enterBlackList()
    case MethodCases.enterMyGroup.rawValue: // 进入我的群聊
      actions = enterMyGroup()
    case MethodCases.clickRemoveBlackList.rawValue: // 解除黑名单
      actions = clickRemoveBlackList()
    case MethodCases.assetView.rawValue:
      if let text = caseModel.params[0]["text"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertChatMessage.rawValue:
      if let text = caseModel.params[0]["text"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertSignature.rawValue: // 签名
      if let text = caseModel.params[0]["signature"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertEmail.rawValue: // 邮箱
      if let text = caseModel.params[0]["email"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertPhone.rawValue: // 手机号
      if let text = caseModel.params[0]["phone"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertSex.rawValue: // 性别
      if let text = caseModel.params[0]["sex"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertNickname.rawValue: // 昵称
      if let text = caseModel.params[0]["nickname"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertVersion.rawValue: // 版本
      if let text = caseModel.params[0]["version"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.clickSureDeleteFriend.rawValue: // 确定删除好友
      actions = clickSureDeleteFriend()
    case MethodCases.clickSureExitGroup.rawValue: // 确定退出讨论组
      let flag = clickSureExitGroup()
      if flag {
        NEHawkManager.shared().sendMessage(caseModel)
        return
      }
    case MethodCases.clickSureExitTeam.rawValue: // 确定退出群聊
      let flag = clickSureExitTeam()
      if flag {
        NEHawkManager.shared().sendMessage(caseModel)
        return
      }
    case MethodCases.clickSureDismissTeam.rawValue: // 确定解散群聊
      let flag = clickSureDismissTeam()
      if flag {
        NEHawkManager.shared().sendMessage(caseModel)
        return
      }
    case MethodCases.clickViewWithText.rawValue: // 根据文案点击
      if let text = caseModel.params[0]["text"] as? String {
        actions = clickViewWithText(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.clickChatSetting.rawValue: // 会话页面 设置按钮
      actions = clickChatSetting()
    case MethodCases.quitTeam.rawValue: // 退出群聊/讨论组
      actions = quitTeam()
    case MethodCases.dismissTeam.rawValue: // 解散群聊
      actions = dismissTeam()
    case MethodCases.deleteConversation.rawValue: // 删除单个会话
      if let accountName = caseModel.params[0]["accountName"] as? String {
        actions = deleteConversation(accountName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterEditUserInfoPage.rawValue: // 进入个人信息编辑页
      actions = enterEditUserInfoPage()
    case MethodCases.updateSignature.rawValue: // 更新签名
      if let signature = caseModel.params[0]["signature"] as? String {
        actions = updateSignature(signature)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterMinePage.rawValue: // 进入个人信息页
      actions = enterMinePage()
    case MethodCases.clearEditText.rawValue: // 清除编辑框
      actions = clearEditText()
    case MethodCases.updateEmail.rawValue: // 更新邮箱
      if let email = caseModel.params[0]["email"] as? String {
        actions = updateEmail(email)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.updatePhone.rawValue: // 更新手机号
      if let phone = caseModel.params[0]["phone"] as? String {
        actions = updatePhone(phone)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.updateNickname.rawValue: // 更新昵称
      if let nickname = caseModel.params[0]["nickname"] as? String {
        actions = updateNickname(nickname)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterAboutNetEasePage.rawValue: // 进入关于云信页
      actions = enterAboutNetEasePage()
    case MethodCases.updateCommentName.rawValue: // 更新备注名
      if let commentName = caseModel.params[0]["commentName"] as? String {
        actions = updateCommentName(commentName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterConversation.rawValue:
      actions = enterConversation()
    case MethodCases.enterInviteGroup.rawValue: // 邀请成员入组
      actions = enterInviteGroup()
    case MethodCases.updateNicknameInTeam.rawValue: // 更新群昵称
      if let nickName = caseModel.params[0]["nickname"] as? String {
        actions = updateNicknameInTeam(nickName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterTeamMember.rawValue: // 进入群成员列表
      actions = enterTeamMember()
    case MethodCases.assertMemberName.rawValue:
      if let nickname = caseModel.params[0]["nickname"] as? String {
        actions = assertMemberName(nickname)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.enterEditGroup.rawValue: // 进入编辑群
      actions = enterEditGroup()
    case MethodCases.updateGroupName.rawValue: // 修改讨论组名称
      if let groupName = caseModel.params[0]["groupName"] as? String {
        actions = updateGroupName(groupName)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertGroupName.rawValue: // 断言讨论组
      if let text = caseModel.params[0]["groupName"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.assertCommentName.rawValue: // 断言好友备注
      if let text = caseModel.params[0]["commentName"] as? String {
        actions = assetView(text)
      } else {
        let error = NEHawkError.nullParameter()
        NEHawkManager.shared().sendMessage(caseModel, error: error)
        return
      }
    case MethodCases.makeSureCreateGroup.rawValue: // 确认创建讨论组
      actions = makeSureCreateGroup()
    default:
      break
    }
    NEHawkManager.shared().execute(actions, caseModel: caseModel)
  }

  // MARK: - 登录

  func startLogin(_ account: String, password: String) -> [NEHawkElementAction]? {
    let loginAction = NEHawkElement().ne_type(.button).ne_label("注册/登录")
    let loginAction1 = NEHawkElement().ne_type(.button).ne_name("注册/登录")
    if loginAction.isExist() {
      loginAction.ne_click().ne_wait(2).execute()
    } else if loginAction1.isExist() {
      loginAction1.ne_click().ne_wait(2).execute()
    }
    let phoneAction = NEHawkElement().ne_type(.textField).ne_placeholderValue("请输入手机号").ne_editText(account).ne_wait(2)
    phoneAction.execute()
    let pwdAction = NEHawkElement().ne_type(.textField).ne_placeholderValue("输入验证码").ne_editText(password).ne_wait(2)
    pwdAction.execute()

    let doneElement = NEHawkElement().ne_type(.button).ne_predicate("label == 'Done' OR label == '完成'")
    let loginBtnAction = NEHawkElement().ne_type(.button).ne_label("登录").ne_click().ne_wait(2)

    if doneElement.isExist() {
      return [doneElement.ne_click().ne_wait(2), loginBtnAction]
    }
    return [loginBtnAction]
  }

  // MARK: - 退出登录

  func startLogout() -> [NEHawkElementAction]? {
    let tabbarElement = NEHawkElement().ne_type(.tabBar).ne_childElement(.button).ne_label("我")
    let tabbarAction = tabbarElement.ne_click().ne_wait(3)

    let setElement = NEHawkElement().ne_type(.table).ne_childElement(.cell).ne_childElement(.staticText).ne_label("设置")
    let setAction = setElement.ne_click()

    let logoutAction = NEHawkElement().ne_type(.button).ne_label("退出登录").ne_click()

    let alertElement = NEHawkElement().ne_type(.alert).ne_label("提示").ne_childElement(.button).ne_label("确定")
    let alertAction = alertElement.ne_click().ne_wait(2)

    return [tabbarAction, setAction, logoutAction, alertAction]
  }

  // MARK: - 通讯录界面

  func enterContact() -> [NEHawkElementAction]? {
    let tabBar = NEHawkElement().ne_type(.tabBar) // .ne_label("标签栏")
    let tabbarElement = tabBar.ne_childElement(.button).ne_label("通讯录")
    let tabbarAction = tabbarElement.ne_click().ne_wait(3)
    return [tabbarAction]
  }

  // MARK: - 消息界面

  func enterConversation() -> [NEHawkElementAction]? {
    let tabbarElement = NEHawkElement().ne_type(.tabBar).ne_childElement(.button).ne_label("消息")
    let tabbarAction = tabbarElement.ne_click().ne_wait(3)

    return [tabbarAction]
  }

  // MARK: - 点击通讯录好友

  func clickContactFriend(_ accountName: String) -> [NEHawkElementAction]? {
    let friendAction = NEHawkElement().ne_type(.staticText).ne_label(accountName).ne_click().ne_wait(2)
    return [friendAction]
  }

  // MARK: - 用户信息页 点击聊天按钮

  func clickUserPageChat() -> [NEHawkElementAction]? {
    let chatAction = NEHawkElement().ne_type(.staticText).ne_label("聊天").ne_click().ne_wait(2)
    return [chatAction]
  }

  // MARK: - 用户信息页 删除好友

  func clickUserPageDelete() -> [NEHawkElementAction]? {
    let swipeUpElement = NEHawkElement().ne_type(.staticText).ne_label("备注名").ne_wait(2)
    let swipeUpAction = swipeUpElement.ne_swipeUp().ne_wait(2)
    let deleteAction = NEHawkElement().ne_type(.staticText).ne_label("删除好友").ne_click().ne_wait(2)
    return [swipeUpAction, deleteAction]
  }

  // MARK: - 用户信息页 添加好友

  func clickUserPageAdd() -> [NEHawkElementAction]? {
    let addAction = NEHawkElement().ne_type(.staticText).ne_label("添加好友").ne_click().ne_wait(2)
    return [addAction]
  }

  // MARK: - 返回上一级

  func pressBack() -> [NEHawkElementAction]? {
    let navigationBarElement = NEHawkElement().ne_type(.button).ne_label("backArrow").ne_wait(2)

    if navigationBarElement.isExist() {
      return [navigationBarElement.ne_click()]
    }
    return nil
  }

  // MARK: - 通讯录 验证消息

  func enterNotificationPage() -> [NEHawkElementAction]? {
    let verifyAction = NEHawkElement().ne_type(.staticText).ne_label("验证消息").ne_click().ne_wait(2)
    return [verifyAction]
  }

  // MARK: - 点击系统通知页面同意

  func clickNotificationAgree() -> [NEHawkElementAction]? {
    let agreeElement = NEHawkElement().ne_type(.table).ne_childElement(.button).ne_label("同意")
    let agreeAction = agreeElement.ne_click().ne_wait(2)
    return [agreeAction]
  }

  // MARK: - 系统通知页面 清空按钮

  func clickNotificationClear() -> [NEHawkElementAction]? {
    let cleanElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("清空")
    let cleanAction = cleanElement.ne_click().ne_wait(2)

//    let alertElement = NEHawkElement().ne_type(.alert).ne_label("提示").ne_childElement(.button).ne_label("确定")
//    let alertAction = alertElement.ne_click().ne_wait(2)

    return [cleanAction]
  }

  // MARK: - 输入id 搜索好友

  func searchUser(_ account: String) -> [NEHawkElementAction]? {
    let textFieldAction = NEHawkElement().ne_type(.textField).ne_placeholderValue("请输入账号").ne_editText(account).ne_wait(2)

//    let searchAction = NEHawkElement().ne_type(.button).ne_name("Search").ne_click()
    let searchAction = NEHawkElement().ne_type(.button).ne_predicate("label == 'Search' OR label == '搜索' OR label == 'search'").ne_click()

    return [textFieldAction, searchAction]
  }

  // MARK: - 从通讯录进入好友搜索界面

  func enterSearchContact() -> [NEHawkElementAction]? {
    let searchElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_index(1)
    let searchAction = searchElement.ne_click().ne_wait(2)
    return [searchAction]
  }

  // MARK: - 好友搜索页面 搜索

  func searchContact(_ searchText: String) -> [NEHawkElementAction]? {
    let textFieldAction = NEHawkElement().ne_type(.textField).ne_placeholderValue("请输入你要搜索的关键字").ne_editText(searchText).ne_wait(2)
    return [textFieldAction]
  }

  // MARK: - 通讯录 进入 好友添加页面

  func enterAddFriend() -> [NEHawkElementAction]? {
    let addElement = NEHawkElement().ne_type(.button).ne_label("add")
//    let addElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_index(2)
    let addAction = addElement.ne_click().ne_wait(2)
    return [addAction]
  }

  // MARK: - 创建群组

  func enterCreateGroup() -> [NEHawkElementAction]? {
    let addAction = NEHawkElement().ne_type(.button).ne_label("chat add").ne_click().ne_wait(2)
    let createAction = NEHawkElement().ne_type(.button).ne_label("创建讨论组").ne_click().ne_wait(2)
    return [addAction, createAction]
  }

  // MARK: - 创建高级群

  func enterCreateAdvance() -> [NEHawkElementAction]? {
    let addAction = NEHawkElement().ne_type(.button).ne_label("chat add").ne_click().ne_wait(2)
    let createAction = NEHawkElement().ne_type(.button).ne_label("创建高级群").ne_click().ne_wait(2)
    return [addAction, createAction]
  }

  // MARK: - 创建群中人员选择

  func selectFriend(_ accountList: [String]) -> [NEHawkElementAction]? {
    guard accountList.count > 0 else { return nil }
    var actions = [NEHawkElementAction]()
    for account in accountList {
      let action = NEHawkElement().ne_type(.staticText).ne_label(account).ne_click().ne_wait(2).ne_preWait(2)
      actions.append(action)
    }
    return actions
  }

  // MARK: - 点击确定创建群

  func clickSureToCreate() -> [NEHawkElementAction]? {
    let naviBarElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_index(2)
    let naviBarAction = naviBarElement.ne_click().ne_wait(2)

    let alertElement = NEHawkElement().ne_type(.alert).ne_label("提示").ne_childElement(.button).ne_label("确定")
    let alertAction = alertElement.ne_click().ne_wait(2)
    return [naviBarAction, alertAction]
  }

  // MARK: - 点击确定退出讨论组

  func clickSureExitGroup() -> Bool {
    let alertElement1 = NEHawkElement().ne_type(.alert).ne_label("是否退出讨论组？").ne_childElement(.button).ne_label("确定").ne_wait(2)
    let alertElement2 = NEHawkElement().ne_type(.button).ne_label("确定").ne_wait(2)
    let alertElement3 = NEHawkElement().ne_type(.alert).ne_childElement(.button).ne_index(2).ne_wait(2)

    if alertElement1.isExist() {
      alertElement1.ne_click().execute()
    } else if alertElement2.isExist() {
      alertElement2.ne_click().execute()
    } else if alertElement3.isExist() {
      alertElement3.ne_click().execute()
    } else {
      return false
    }

    let backElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("backArrow").ne_wait(2)
    if backElement.isExist() {
      backElement.ne_click().execute()
    }
    return true
  }

  // MARK: - 点击确定解散群聊

  func clickSureDismissTeam() -> Bool {
    let alertElement1 = NEHawkElement().ne_type(.alert).ne_label("是否解散群聊？").ne_childElement(.button).ne_label("确定").ne_wait(2)
    let alertElement2 = NEHawkElement().ne_type(.button).ne_label("确定").ne_wait(2)
    let alertElement3 = NEHawkElement().ne_type(.alert).ne_childElement(.button).ne_index(2).ne_wait(2)

    if alertElement1.isExist() {
      alertElement1.ne_click().execute()
    } else if alertElement2.isExist() {
      alertElement2.ne_click().execute()
    } else if alertElement3.isExist() {
      alertElement3.ne_click().execute()
    } else {
      return false
    }

    let backElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("backArrow").ne_wait(2)
    if backElement.isExist() {
      backElement.ne_click().execute()
    }
    return true
  }

  // MARK: - 点击确定退出群聊

  func clickSureExitTeam() -> Bool {
    let alertElement1 = NEHawkElement().ne_type(.alert).ne_label("是否退出群聊？").ne_childElement(.button).ne_label("确定").ne_wait(2)
    let alertElement2 = NEHawkElement().ne_type(.button).ne_label("确定").ne_wait(2)
    let alertElement3 = NEHawkElement().ne_type(.alert).ne_childElement(.button).ne_index(2).ne_wait(2)

    if alertElement1.isExist() {
      alertElement1.ne_click().execute()
    } else if alertElement2.isExist() {
      alertElement2.ne_click().execute()
    } else if alertElement3.isExist() {
      alertElement3.ne_click().execute()
    } else {
      return false
    }

    let backElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("backArrow").ne_wait(2)
    if backElement.isExist() {
      backElement.ne_click().execute()
    }
    return true
  }

  // MARK: - 点击会话

  func clickConversation(_ conversationName: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.staticText).ne_label(conversationName).ne_click().ne_wait(2)
    return [action]
  }

  // MARK: - 聊天室输入发送文字

  func inputSendMsg(_ sendText: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.textView).ne_editText(sendText).ne_wait(2)
    return [action]
  }

  // MARK: - 发送消息

  func sendMsg() -> [NEHawkElementAction]? {
    let sendAction = NEHawkElement().ne_type(.button).ne_predicate("label == 'send' OR label == '发送'").ne_click().ne_wait(2)
    return [sendAction]
  }

  // MARK: - 加入黑名单

  func clickAddBlackList() -> [NEHawkElementAction]? {
    let switchElement = NEHawkElement().ne_type(.table).ne_childElement(.cell).ne_index(6).ne_childElement(.switch)
    let switchAction = switchElement.ne_click().ne_wait(2)
    return [switchAction]
  }

  // MARK: - 通讯录 进入黑名单

  func enterBlackList() -> [NEHawkElementAction]? {
    let blackAction = NEHawkElement().ne_type(.staticText).ne_label("黑名单").ne_click().ne_wait(2)
    return [blackAction]
  }

  // MARK: - 通讯录 我的群聊

  func enterMyGroup() -> [NEHawkElementAction]? {
    let myGroupAction = NEHawkElement().ne_type(.staticText).ne_label("我的群聊").ne_click().ne_wait(2)
    return [myGroupAction]
  }

  // MARK: - 解除黑名单

  func clickRemoveBlackList() -> [NEHawkElementAction]? {
    let removeAction = NEHawkElement().ne_type(.button).ne_label("解除").ne_click().ne_wait(2)
    return [removeAction]
  }

  // MARK: - 断言 视图是否存在

  func assetView(_ text: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.staticText).ne_label(text).ne_show().ne_wait(5).ne_preWait(2)
    return [action]
  }

  // MARK: - 点击删除好友弹框确认删除

  func clickSureDeleteFriend() -> [NEHawkElementAction]? {
    let alertElement = NEHawkElement().ne_type(.button).ne_label("删除好友")
    let alertAction = alertElement.ne_click().ne_wait(2)

    return [alertAction]
  }

  // MARK: - 根据文案点击

  func clickViewWithText(_ text: String) -> [NEHawkElementAction]? {
    let barElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label(text).ne_wait(3)

    let textElement = NEHawkElement().ne_type(.staticText).ne_label(text).ne_wait(3)

    let buttonElement = NEHawkElement().ne_type(.button).ne_label(text).ne_wait(3)

    let textFiledElement = NEHawkElement().ne_type(.textField).ne_value(text).ne_wait(3)

//    let alertElement = NEHawkElement().ne_type(.alert).ne_childElement(.button).ne_index(2).ne_wait(2)

    if barElement.isExist() {
      return [barElement.ne_click().ne_wait(2)]
    } else if textElement.isExist() {
      return [textElement.ne_click().ne_wait(2)]
    } else if buttonElement.isExist() {
      return [buttonElement.ne_click().ne_wait(2)]
    } else if textFiledElement.isExist() {
      return [textFiledElement.ne_click().ne_wait(2)]
    }
    return nil
  }

  // MARK: - 点击会话页面 设置按钮

  func clickChatSetting() -> [NEHawkElementAction]? {
    let naviElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("three point")
//    let naviElement = NEHawkElement().ne_type(.button).ne_label("three point")
    let naviAction = naviElement.ne_click().ne_wait(2)
    return [naviAction]
  }

  // MARK: - 退出群聊 / 讨论组

  func quitTeam() -> [NEHawkElementAction]? {
//    let setElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_label("three point")
    let setElement = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_index(2)
    let setAction = setElement.ne_click().ne_wait(2)
    setAction.execute()

//      let swipeUpElement = NEHawkElement().ne_type(.staticText).ne_label("历史记录").ne_wait(2)
//      let swipeUpAction = swipeUpElement.ne_swipeUp().ne_wait(2)
//      swipeUpAction.execute()

    let exitDiscussionGroupElement = NEHawkElement().ne_type(.button).ne_label("退出讨论组")
    let exitGroupChat = NEHawkElement().ne_type(.button).ne_label("退出群聊")

    if exitDiscussionGroupElement.isExist() {
      let exitAction = exitDiscussionGroupElement.ne_click().ne_wait(2)
      return [exitAction]
    } else if exitGroupChat.isExist() {
      let exitAction = exitGroupChat.ne_click().ne_wait(2)
      return [exitAction]
    }
    return nil
  }

  // MARK: - 解散群聊

  func dismissTeam() -> [NEHawkElementAction]? {
    let tableAction = NEHawkElement().ne_type(.table).ne_swipeUp().ne_wait(3).ne_preWait(2)
    let dissolveAction = NEHawkElement().ne_type(.button).ne_label("解散群聊").ne_click().ne_wait(2).ne_preWait(2)
    return [tableAction, dissolveAction]
  }

  // MARK: - 删除会话列表中的单个会话

  func deleteConversation(_ accountName: String) -> [NEHawkElementAction]? {
    let cellElement = NEHawkElement().ne_type(.table).ne_childElement(.cell).ne_childElement(.staticText).ne_label(accountName)
    let cellAction = cellElement.ne_swipeLeft().ne_wait(2)

    let deleteElement = NEHawkElement().ne_type(.table).ne_childElement(.button).ne_label("删除")
    let deleteAction = deleteElement.ne_click().ne_wait(2)

    return [cellAction, deleteAction]
  }

  // MARK: - 进入个人信息编辑页面

  func enterEditUserInfoPage() -> [NEHawkElementAction]? {
    // 包含 账号
    let accountAction = NEHawkElement().ne_type(.staticText).ne_predicate("label BEGINSWITH '账号'").ne_click().ne_wait(2)
    return [accountAction]
  }

  // MARK: - 更新个性签名

  func updateSignature(_ signature: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.textField).ne_editText(signature).ne_wait(2)
    return [action]
  }

  // MARK: - 进入个人信息页

  func enterMinePage() -> [NEHawkElementAction]? {
    let mineElement = NEHawkElement().ne_type(.tabBar).ne_childElement(.button).ne_label("我")
    let mineAction = mineElement.ne_click().ne_wait(5)
    return [mineAction]
  }

  // MARK: - 清除文本

  func clearEditText() -> [NEHawkElementAction]? {
    let cleanAction = NEHawkElement().ne_type(.button).ne_label("清除文本")
    let cleanAction1 = NEHawkElement().ne_type(.button).ne_name("清除文本")
    let cleanAction2 = NEHawkElement().ne_type(.button).ne_label("clear btn")
    let cleanAction3 = NEHawkElement().ne_type(.button).ne_name("clear btn")
    let cleanAction4 = NEHawkElement().ne_type(.button).ne_value("clear btn")
    let cleanAction5 = NEHawkElement().ne_type(.button).ne_index(2)
    if cleanAction.isExist() {
      return [cleanAction.ne_click().ne_wait(2)]
    } else if cleanAction1.isExist() {
      return [cleanAction1.ne_click().ne_wait(2)]
    } else if cleanAction2.isExist() {
      return [cleanAction2.ne_click().ne_wait(2)]
    } else if cleanAction3.isExist() {
      return [cleanAction3.ne_click().ne_wait(2)]
    } else if cleanAction4.isExist() {
      return [cleanAction4.ne_click().ne_wait(2)]
    } else if cleanAction5.isExist() {
      return [cleanAction5.ne_click().ne_wait(2)]
    }
    return nil
  }

  // MARK: - 更新邮箱

  func updateEmail(_ email: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.textField).ne_editText(email).ne_wait(2)
    return [action]
  }

  // MARK: - 更新手机号

  func updatePhone(_ phone: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.textField).ne_editText(phone).ne_wait(2)
    return [action]
  }

  // MARK: - 更新昵称

  func updateNickname(_ nickname: String) -> [NEHawkElementAction]? {
    let action = NEHawkElement().ne_type(.textField).ne_editText(nickname).ne_wait(2)
    return [action]
  }

  // MARK: - 进入 关于云信页面

  func enterAboutNetEasePage() -> [NEHawkElementAction]? {
    let aboutAction = NEHawkElement().ne_type(.staticText).ne_label("关于云信").ne_click().ne_wait(2)
    return [aboutAction]
  }

  // MARK: - 更新备注名

  func updateCommentName(_ commentName: String) -> [NEHawkElementAction]? {
    let commentAction = NEHawkElement().ne_type(.textField).ne_placeholderValue("请输入备注名").ne_editText(commentName).ne_wait(2)
    return [commentAction]
  }

  // MARK: - 邀请成员入组

  func enterInviteGroup() -> [NEHawkElementAction]? {
    let inviteAction = NEHawkElement().ne_type(.button).ne_label("add").ne_click().ne_wait(2)
    return [inviteAction]
  }

  // MARK: - 更新群昵称

  func updateNicknameInTeam(_ nickName: String) -> [NEHawkElementAction]? {
    let nickNameAction = NEHawkElement().ne_type(.textView).ne_editText(nickName).ne_wait(2)
    return [nickNameAction]
  }

  // MARK: - 进入群成员列表

  func enterTeamMember() -> [NEHawkElementAction]? {
    let memberAction = NEHawkElement().ne_type(.staticText).ne_label("群成员").ne_click().ne_wait(2)
    return [memberAction]
  }

  // MARK: - 断言群成员

  func assertMemberName(_ nickName: String) -> [NEHawkElementAction]? {
    let nameAction = NEHawkElement().ne_type(.staticText).ne_label(nickName).ne_show().ne_wait(2)
    return [nameAction]
  }

  // MARK: - 进入编辑群

  func enterEditGroup() -> [NEHawkElementAction]? {
    let tableElement = NEHawkElement().ne_type(.table).ne_childElement(.other).ne_index(1).ne_childElement(.button).ne_index(1)
    let action = tableElement.ne_click().ne_wait(2)
    return [action]
  }

  // MARK: - 更新讨论组名称

  func updateGroupName(_ groupName: String) -> [NEHawkElementAction]? {
    let inputAction = NEHawkElement().ne_type(.textView).ne_editText(groupName).ne_wait(2)
    return [inputAction]
  }

  // MARK: - 确认创建讨论组

  func makeSureCreateGroup() -> [NEHawkElementAction]? {
    let makeSureAction = NEHawkElement().ne_type(.navigationBar).ne_childElement(.button).ne_index(2).ne_click().ne_preWait(3).ne_wait(5)
//    let makeSureAction = NEHawkElement().ne_type(.button).ne_predicate("label BEGINSWITH '确定'").ne_click().ne_wait(5).ne_preWait(3)
    return [makeSureAction]
  }
}
