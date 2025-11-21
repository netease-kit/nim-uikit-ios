
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import UIKit

class ConfigTestViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  var cellClassDic = [
    SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self,
    SettingCellType.SettingSubtitleCell.rawValue: CustomSettingTextviewCell.self,
  ]
  var sectionData = [SettingSectionModel]()

  /// 最近转发的会话 id 列表最大长度
  let recentForwardListMaxCountModel = CustomSettingCellModel()

  /// 群聊中允许添加的管理员人数
  let teamManagerCountModel = CustomSettingCellModel()

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    sectionData.append(getSectionData())
    setupSubviews()
    initialConfig()
  }

  func getSectionData() -> SettingSectionModel {
    let model = SettingSectionModel()

    let useSysNav = SettingCellModel()
    useSysNav.cellName = "使用系统导航栏"
    useSysNav.type = SettingCellType.SettingSwitchCell.rawValue
    useSysNav.switchOpen = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool ?? false
    useSysNav.swichChange = { isOpen in
      NEConfigManager.instance.setParameter(key: useSystemNav, value: isOpen)
    }
    model.cellModels.append(useSysNav)

    let showTeam = SettingCellModel()
    showTeam.cellName = "显示群聊"
    showTeam.type = SettingCellType.SettingSwitchCell.rawValue
    showTeam.switchOpen = IMKitConfigCenter.shared.enableTeam
    showTeam.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableTeam = isOpen
    }
    model.cellModels.append(showTeam)

    let showTeamAction = SettingCellModel()
    showTeamAction.cellName = "群聊申请邀请功能"
    showTeamAction.type = SettingCellType.SettingSwitchCell.rawValue
    showTeamAction.switchOpen = IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth
    showTeamAction.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth = isOpen
    }
    model.cellModels.append(showTeamAction)

    let showMessageCollection = SettingCellModel()
    showMessageCollection.cellName = "显示收藏"
    showMessageCollection.type = SettingCellType.SettingSwitchCell.rawValue
    showMessageCollection.switchOpen = IMKitConfigCenter.shared.enableCollectionMessage
    showMessageCollection.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableCollectionMessage = isOpen
    }
    model.cellModels.append(showMessageCollection)

    let showMessagePin = SettingCellModel()
    showMessagePin.cellName = "显示标记"
    showMessagePin.type = SettingCellType.SettingSwitchCell.rawValue
    showMessagePin.switchOpen = IMKitConfigCenter.shared.enablePinMessage
    showMessagePin.swichChange = { isOpen in
      IMKitConfigCenter.shared.enablePinMessage = isOpen
    }
    model.cellModels.append(showMessagePin)

    let showMessageTop = SettingCellModel()
    showMessageTop.cellName = "显示置顶"
    showMessageTop.type = SettingCellType.SettingSwitchCell.rawValue
    showMessageTop.switchOpen = IMKitConfigCenter.shared.enableTopMessage
    showMessageTop.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableTopMessage = isOpen
    }
    model.cellModels.append(showMessageTop)

    let showOnlineStatus = SettingCellModel()
    showOnlineStatus.cellName = "显示在线状态"
    showOnlineStatus.type = SettingCellType.SettingSwitchCell.rawValue
    showOnlineStatus.switchOpen = IMKitConfigCenter.shared.enableOnlineStatus
    showOnlineStatus.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableOnlineStatus = isOpen
    }
    model.cellModels.append(showOnlineStatus)

    let enableInsertLocalMsgWhenRevoke = SettingCellModel()
    enableInsertLocalMsgWhenRevoke.cellName = "撤回消息后是否插入提示消息"
    enableInsertLocalMsgWhenRevoke.type = SettingCellType.SettingSwitchCell.rawValue
    enableInsertLocalMsgWhenRevoke.switchOpen = IMKitConfigCenter.shared.enableInsertLocalMsgWhenRevoke
    enableInsertLocalMsgWhenRevoke.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableInsertLocalMsgWhenRevoke = isOpen
    }
    model.cellModels.append(enableInsertLocalMsgWhenRevoke)

    let strangerCallModel = SettingCellModel()
    strangerCallModel.cellName = "陌生人能否进行音视频通话"
    strangerCallModel.type = SettingCellType.SettingSwitchCell.rawValue
    strangerCallModel.switchOpen = IMKitConfigCenter.shared.enableOnlyFriendCall
    strangerCallModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableOnlyFriendCall = isOpen
    }
    model.cellModels.append(strangerCallModel)

    let invalidTeamDeleteModel = SettingCellModel()
    invalidTeamDeleteModel.cellName = "无效群聊是否删除会话"
    invalidTeamDeleteModel.type = SettingCellType.SettingSwitchCell.rawValue
    invalidTeamDeleteModel.switchOpen = IMKitConfigCenter.shared.enableDismissTeamDeleteConversation
    invalidTeamDeleteModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableDismissTeamDeleteConversation = isOpen
    }
    model.cellModels.append(invalidTeamDeleteModel)

    let aiUserModel = SettingCellModel()
    aiUserModel.cellName = "开启数字人"
    aiUserModel.type = SettingCellType.SettingSwitchCell.rawValue
    aiUserModel.switchOpen = IMKitConfigCenter.shared.enableAIUser
    aiUserModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableAIUser = isOpen
    }
    model.cellModels.append(aiUserModel)

    let aiStreamMessageModel = SettingCellModel()
    aiStreamMessageModel.cellName = "消息流式输出"
    aiStreamMessageModel.type = SettingCellType.SettingSwitchCell.rawValue
    aiStreamMessageModel.switchOpen = IMKitConfigCenter.shared.enableAIStream
    aiStreamMessageModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableAIStream = isOpen
    }
    model.cellModels.append(aiStreamMessageModel)

    let aiChatModel = SettingCellModel()
    aiChatModel.cellName = "AI 助聊"
    aiChatModel.type = SettingCellType.SettingSwitchCell.rawValue
    aiChatModel.switchOpen = IMKitConfigCenter.shared.enableAIChatHelper
    aiChatModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableAIChatHelper = isOpen
    }
    model.cellModels.append(aiChatModel)

    let sendRichTextMessageModel = SettingCellModel()
    sendRichTextMessageModel.cellName = "允许发送【换行消息】"
    sendRichTextMessageModel.type = SettingCellType.SettingSwitchCell.rawValue
    sendRichTextMessageModel.switchOpen = IMKitConfigCenter.shared.enableRichTextMessage
    sendRichTextMessageModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableRichTextMessage = isOpen
    }
    model.cellModels.append(sendRichTextMessageModel)

    let failedMessageTipModel = SettingCellModel()
    failedMessageTipModel.cellName = "文本安全提示"
    failedMessageTipModel.type = SettingCellType.SettingSwitchCell.rawValue
    failedMessageTipModel.switchOpen = IMKitConfigCenter.shared.enableAntiSpamTipMessage
    failedMessageTipModel.swichChange = { isOpen in
      IMKitConfigCenter.shared.enableAntiSpamTipMessage = isOpen
    }
    model.cellModels.append(failedMessageTipModel)

    recentForwardListMaxCountModel.cellName = "最近转发的会话 id 列表最大长度"
    recentForwardListMaxCountModel.type = SettingCellType.SettingSubtitleCell.rawValue
    recentForwardListMaxCountModel.customInputText = "\(IMKitConfigCenter.shared.recentForwardListMaxCount)"
    model.cellModels.append(recentForwardListMaxCountModel)

    teamManagerCountModel.cellName = "允许添加的管理员人数( -1 表示无限制)"
    teamManagerCountModel.type = SettingCellType.SettingSubtitleCell.rawValue
    teamManagerCountModel.customInputText = "\(IMKitConfigCenter.shared.teamManagerMaxCount)"
    model.cellModels.append(teamManagerCountModel)

    model.setCornerType()
    return model
  }

  func initialConfig() {
    title = "全局配置"
    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
      navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
    } else {
      view.backgroundColor = .funChatBackgroundColor
      navigationView.moreButton.setTitleColor(.funChatThemeColor, for: .normal)
    }
  }

  func setupSubviews() {
    addRightAction("保存", #selector(saveConfig), self)
    navigationView.moreButton.isHidden = false
    navigationView.setMoreButtonTitle("保存")
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveConfig))

    let tipLabel = UILabel()
    tipLabel.translatesAutoresizingMaskIntoConstraints = false
    tipLabel.text = "点击保存生效"
    tipLabel.textColor = .ne_greyText
    tipLabel.font = UIFont.systemFont(ofSize: 14)
    tipLabel.textAlignment = .center
    view.addSubview(tipLabel)
    NSLayoutConstraint.activate([
      tipLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      tipLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      tipLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      tipLabel.heightAnchor.constraint(equalToConstant: 20),
    ])

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: tipLabel.bottomAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  @objc func saveConfig() {
    if let text = recentForwardListMaxCountModel.customInputText, !text.isEmpty,
       let recentForwardListMaxCount = Int(text), recentForwardListMaxCount > 0 {
      IMKitConfigCenter.shared.recentForwardListMaxCount = recentForwardListMaxCount
    }

    if let text = teamManagerCountModel.customInputText, !text.isEmpty,
       let teamManagerMaxCount = Int(text), teamManagerMaxCount >= -1 {
      IMKitConfigCenter.shared.teamManagerMaxCount = teamManagerMaxCount
    }

    NotificationCenter.default.post(
      name: Notification.Name(CHANGE_UI),
      object: nil
    )
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if sectionData.count > section {
      let model = sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    sectionData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      cell.accessibilityIdentifier = "id.\(model.cellName ?? "config\(indexPath.section)\(indexPath.row)")"
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }
}
