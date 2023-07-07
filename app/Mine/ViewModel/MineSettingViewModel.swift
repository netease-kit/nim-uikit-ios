
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit

public protocol MineSettingViewModelDelegate: NSObjectProtocol {
  func didMessageRemindClick()
  func didStyleClick()
  func didClickCleanCache()
}

@objcMembers
public class MineSettingViewModel: NSObject {
  var sectionData = [SettingSectionModel]()
  weak var delegate: MineSettingViewModelDelegate?

  public func getData() {
    sectionData.append(getFirstSection())
    sectionData.append(getSecondSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    // 消息提醒
    let remind = SettingCellModel()
    remind.cellName = NSLocalizedString("message_remind", comment: "")
    remind.type = SettingCellType.SettingArrowCell.rawValue
    remind.cornerType = .topLeft.union(.topRight)
//    remind.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
    remind.cellClick = {
      weakSelf?.delegate?.didMessageRemindClick()
    }
    model.cellModels.append(remind)

    // 外观
    let style = SettingCellModel()
    style.cellName = NSLocalizedString("style_selection", comment: "")
    style.type = SettingCellType.SettingArrowCell.rawValue
    style.cornerType = .bottomLeft.union(.bottomRight)
    style.cellClick = {
      weakSelf?.delegate?.didStyleClick()
    }
    model.cellModels.append(style)

//        let cleanCache = SettingCellModel()
//        cleanCache.cellName = "清理缓存"
//        cleanCache.type = SettingCellType.SettingArrowCell.rawValue
//        cleanCache.cornerType = .bottomLeft.union(.bottomRight)
//        cleanCache.cellClick = {
//            weakSelf?.delegate?.didClickCleanCache()
//        }
//        model.cellModels.append(cleanCache)

    return model
  }

  private func getSecondSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    // 听筒模式
    let receiverModel = SettingCellModel()
    receiverModel.cellName = NSLocalizedString("receiver_mode", comment: "")
    receiverModel.type = SettingCellType.SettingSwitchCell.rawValue
    receiverModel.cornerType = .topLeft.union(.topRight)
//        receiverModel.switchOpen = CoreKitEngine.instance.repo.getHandSetMode()
    receiverModel.switchOpen = IMKitEngine.instance.repo.getHandsetMode()

    receiverModel.swichChange = { isOpen in
      IMKitEngine.instance.repo.setHandsetMode(isOpen)
    }
//        //过滤通知
//        let filterNotify = SettingCellModel()
//        filterNotify.cellName = "过滤通知"
//        filterNotify.type = SettingCellType.SettingSwitchCell.rawValue
//        //filterNotify.switchOpen = true
//
//        filterNotify.swichChange = { isOpen in
//
//        }

    // 删除好友是否同步删除备注
//    let deleteFriend = SettingCellModel()
//    deleteFriend.cellName = NSLocalizedString("delete_friend", comment: "")
//    deleteFriend.type = SettingCellType.SettingSwitchCell.rawValue
//    deleteFriend.switchOpen = IMKitEngine.instance.repo.getDeleteFriendAlias()
//
//    deleteFriend.swichChange = { isOpen in
//      IMKitEngine.instance.repo.setDeleteFriendAlias(isOpen)
//    }

    // 消息已读未读功能
    let hasRead = SettingCellModel()
    hasRead.cellName = NSLocalizedString("message_read_function", comment: "")
    hasRead.type = SettingCellType.SettingSwitchCell.rawValue
    hasRead.cornerType = .bottomLeft.union(.bottomRight)
//        hasRead.switchOpen = true
    hasRead.switchOpen = IMKitEngine.instance.repo.getShowReadStatus()
    hasRead.swichChange = { isOpen in
      IMKitEngine.instance.repo.setShowReadStatus(isOpen)
    }
    model.cellModels.append(contentsOf: [receiverModel, hasRead])
    return model
  }
}
