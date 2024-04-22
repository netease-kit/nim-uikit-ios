
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
    sectionData.append(getThirdSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    // 新消息通知
    let messageNotify = SettingCellModel()
    messageNotify.cellName = NSLocalizedString("new_message_remind", comment: "")
    messageNotify.type = SettingCellType.SettingSwitchCell.rawValue
    // TODO: 换V2
    messageNotify.switchOpen = settingRepo.getPushEnable()
    messageNotify.swichChange = { isOpen in
//      let config = V2NIMDndConfig()
//      config.dndOn = isOpen
//      weakSelf?.repo.setDndConfig(config: config)
      weakSelf?.settingRepo.setPushEnable(isOpen)
    }
    model.cellModels.append(contentsOf: [
      messageNotify, // 新消息通知
    ])
    model.setCornerType()
    return model
  }

  private func getThirdSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self

    let messageDetailItem = SettingCellModel()
    messageDetailItem.cellName = NSLocalizedString("display_message_detail", comment: "")
    messageDetailItem.type = SettingCellType.SettingSwitchCell.rawValue
    // TODO: 换V2
    messageDetailItem.switchOpen = settingRepo.getPushDetailEnable()
    messageDetailItem.swichChange = { isOpen in
      weakSelf?.settingRepo.setPushShowDetail(isOpen) { error in
        if let err = error {
          print("设置失败: \(err)")
          messageDetailItem.switchOpen = !isOpen
        }
      }
    }

    model.cellModels.append(contentsOf: [messageDetailItem])
    model.setCornerType()
    return model
  }
}
