
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NETeamUIKit
import NIMSDK

@objcMembers
public class IntroduceViewModel: NSObject {
  var sectionData = [SettingCellModel]()

  func getData() {
    let versionItem = SettingCellModel()
    versionItem.cellName = localizable("version")
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    if let version = appVersion {
      versionItem.subTitle = "V\(version)"
    }

    let imVersionItem = SettingCellModel()
    imVersionItem.cellName = localizable("im_version")
    imVersionItem.subTitle = "\(NIMSDK.shared().sdkVersion())"
    imVersionItem.type = SettingCellType.SettingSubtitleCell.rawValue

    let introduceItem = SettingCellModel()
    introduceItem.cellName = localizable("product_intro")
    sectionData.append(contentsOf: [versionItem, imVersionItem, introduceItem])
  }
}
