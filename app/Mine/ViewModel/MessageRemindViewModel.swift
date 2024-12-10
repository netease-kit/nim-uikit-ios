
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit
import NIMSDK

@objcMembers
public class MessageRemindViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  let settingRepo = SettingRepo.shared

  func getData() {
    sectionData.append(getFirstSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    // 新消息通知
    let messageNotify = SettingCellModel()
    messageNotify.cellName = localizable("new_message_remind")
    messageNotify.type = SettingCellType.SettingSwitchCell.rawValue
    messageNotify.switchOpen = settingRepo.getPushEnable()
    messageNotify.swichChange = { isOpen in
      weakSelf?.settingRepo.setMessageNotify(isOpen) { error in
        if let err = error {
          print("设置失败: \(err)")
          messageNotify.switchOpen = !isOpen
        }
      }
    }
    model.cellModels.append(messageNotify)

    // 通知栏显示消息详情
    let messageDetailItem = SettingCellModel()
    messageDetailItem.cellName = localizable("display_message_detail")
    messageDetailItem.type = SettingCellType.SettingSwitchCell.rawValue
    messageDetailItem.switchOpen = settingRepo.getPushDetailEnable()
    messageDetailItem.swichChange = { isOpen in
      weakSelf?.settingRepo.setPushShowDetail(isOpen) { error in
        if let err = error {
          print("设置失败: \(err)")
          messageDetailItem.switchOpen = !isOpen
        }
      }
    }

    model.cellModels.append(messageDetailItem)
    model.setCornerType()
    return model
  }
}
