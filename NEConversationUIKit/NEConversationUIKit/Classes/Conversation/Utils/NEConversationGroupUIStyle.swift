// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

struct NEConversationGroupUIStyle {
  let pageBackgroundColor: UIColor
  let navigationBackgroundColor: UIColor
  let contentBackgroundColor: UIColor
  let cardBackgroundColor: UIColor
  let primaryColor: UIColor
  let primaryDisabledColor: UIColor
  let selectedBackgroundColor: UIColor
  let titleTextColor: UIColor
  let secondaryTextColor: UIColor
  let tertiaryTextColor: UIColor
  let lineColor: UIColor
  let dangerColor: UIColor
  let sheetMaskColor: UIColor
  let emptyImageName: String
  let managerImageName: String
  let addImageName: String
  let hiddenAddImageName: String
  let deleteImageName: String
  let disableImageName: String
  let settingImageName: String
  let dragImageName: String
  let selectedImageName: String
  let unselectedImageName: String
  let addConversationAvatarCornerRadius: CGFloat
  let settingConversationAvatarCornerRadius: CGFloat

  static let normal = NEConversationGroupUIStyle(
    pageBackgroundColor: UIColor(hexString: "#F5F7FA"),
    navigationBackgroundColor: UIColor(hexString: "#F5F7FA"),
    contentBackgroundColor: .white,
    cardBackgroundColor: .white,
    primaryColor: .ne_normalTheme,
    primaryDisabledColor: UIColor(hexString: "#337EFF", 0.5),
    selectedBackgroundColor: UIColor(hexString: "#EAF2FF"),
    titleTextColor: .ne_darkText,
    secondaryTextColor: .ne_greyText,
    tertiaryTextColor: .ne_lightText,
    lineColor: UIColor(hexString: "#EFF1F4"),
    dangerColor: .ne_redText,
    sheetMaskColor: UIColor.black.withAlphaComponent(0.35),
    emptyImageName: "user_empty",
    managerImageName: "conversation_group_manager",
    addImageName: "conversation_group_add_new",
    hiddenAddImageName: "conversation_group_hidden_add",
    deleteImageName: "conversation_group_delete",
    disableImageName: "conversation_group_disable",
    settingImageName: "conversation_group_setting",
    dragImageName: "conversation_group_right_draw",
    selectedImageName: "conversation_group_select_selected",
    unselectedImageName: "conversation_group_select_unselected",
    addConversationAvatarCornerRadius: 24,
    settingConversationAvatarCornerRadius: 18
  )

}
