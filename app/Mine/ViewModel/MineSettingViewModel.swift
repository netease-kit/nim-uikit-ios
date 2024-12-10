
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit

public protocol MineSettingViewModelDelegate: NSObjectProtocol {
  func didMessageRemindClick()
  func didStyleClick()
  func didClickCleanCache()
  func didClickSDKConfig()
  func didClickLanguage()
}

@objcMembers
public class MineSettingViewModel: NSObject {
  var sectionData = [SettingSectionModel]()
  weak var delegate: MineSettingViewModelDelegate?

  public func getData() {
    sectionData.removeAll()
    sectionData.append(getFirstSection())
    sectionData.append(getSecondSection())
    sectionData.append(getThreeSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    // 消息提醒
    let remind = SettingCellModel()
    remind.cellName = localizable("message_remind")
    remind.type = SettingCellType.SettingArrowCell.rawValue
    remind.cellClick = {
      weakSelf?.delegate?.didMessageRemindClick()
    }
    model.cellModels.append(remind)

    // 外观
    let style = SettingCellModel()
    style.cellName = localizable("style_selection")
    style.type = SettingCellType.SettingArrowCell.rawValue
    style.cellClick = {
      weakSelf?.delegate?.didStyleClick()
    }
    model.cellModels.append(style)

//        let cleanCache = SettingCellModel()
//        cleanCache.cellName = "清理缓存"
//        cleanCache.type = SettingCellType.SettingArrowCell.rawValue
//        cleanCache.cellClick = {
//            weakSelf?.delegate?.didClickCleanCache()
//        }
//        model.cellModels.append(cleanCache)

    model.setCornerType()
    return model
  }

  private func getSecondSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    // 听筒模式
    let receiverModel = SettingCellModel()
    receiverModel.cellName = localizable("receiver_mode")
    receiverModel.type = SettingCellType.SettingSwitchCell.rawValue
//        receiverModel.switchOpen = CoreKitEngine.instance.repo.getHandSetMode()
    receiverModel.switchOpen = SettingRepo.shared.getHandsetMode()

    receiverModel.swichChange = { isOpen in
      SettingRepo.shared.setHandsetMode(isOpen)
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
//    deleteFriend.cellName = localizable("delete_friend")
//    deleteFriend.type = SettingCellType.SettingSwitchCell.rawValue
//    deleteFriend.switchOpen = SettingRepo.shared.getDeleteFriendAlias()
//
//    deleteFriend.swichChange = { isOpen in
//      SettingRepo.shared.setDeleteFriendAlias(isOpen)
//    }

    // 消息已读未读功能
    let hasRead = SettingCellModel()
    hasRead.cellName = localizable("message_read_function")
    hasRead.type = SettingCellType.SettingSwitchCell.rawValue
//        hasRead.switchOpen = true
    hasRead.switchOpen = SettingRepo.shared.getShowReadStatus()
    hasRead.swichChange = { isOpen in
      SettingRepo.shared.setShowReadStatus(isOpen)
    }
    model.cellModels.append(contentsOf: [
      receiverModel, // 听筒模式
      hasRead, // 消息已读未读功能
    ])
    model.setCornerType()
    return model
  }

  private func getThreeSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    let sdkConfigModel = SettingCellModel()
    sdkConfigModel.cellName = "私有云环境配置"
    sdkConfigModel.type = SettingCellType.SettingArrowCell.rawValue
    sdkConfigModel.cellClick = {
      weakSelf?.delegate?.didClickSDKConfig()
    }
    model.cellModels.append(sdkConfigModel)

    let languageConfigModel = SettingCellModel()
    languageConfigModel.cellName = localizable("app_language")
    languageConfigModel.type = SettingCellType.SettingArrowCell.rawValue
    languageConfigModel.cellClick = {
      weakSelf?.delegate?.didClickLanguage()
    }
    model.cellModels.append(languageConfigModel)

    model.setCornerType()
    return model
  }
}
