
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit
import NIMSDK

@objcMembers
public class LanguageViewModel: NSObject {
  var sectionData = [SettingSectionModel]()

  let settingRepo = SettingRepo.shared

  func getData() {
    sectionData.append(getFirstSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()

    // 当前语言环境
    let language = NEAppLanguageUtil.getCurrentLanguage()

    // 中文
    let chinese = SettingCellModel()
    chinese.cellName = localizable("app_language_zh")
    chinese.defaultHeadData = "zh-Hans"
    chinese.type = SettingCellType.SettingSubtitleCustomCell.rawValue
    chinese.rightCustomViewIcon = language == .chinese ? UIImage(named: "language_select") : UIImage()
    chinese.titleWidth = 60
    model.cellModels.append(chinese)

    // English
    let english = SettingCellModel()
    english.cellName = localizable("app_language_en")
    english.defaultHeadData = "en"
    english.type = SettingCellType.SettingSubtitleCustomCell.rawValue
    english.rightCustomViewIcon = language == .english ? UIImage(named: "language_select") : UIImage()
    english.titleWidth = 60
    model.cellModels.append(english)

    model.setCornerType()
    return model
  }
}
