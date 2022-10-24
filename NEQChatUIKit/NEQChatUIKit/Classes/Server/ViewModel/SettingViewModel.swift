// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEQChatKit

@objcMembers
public class SettingViewModel: NSObject {
  let repo = QChatRepo()
  var permissions = [SettingModel]()
  override init() {
    super.init()
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    let member = SettingModel()
    member.title = localizable("qchat_member")
    member.cornerType = CornerType.topLeft.union(CornerType.topRight)
    permissions.append(member)
    let idGroup = SettingModel()
    idGroup.title = localizable("qchat_id_group")
    idGroup.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
    permissions.append(idGroup)
  }
}
