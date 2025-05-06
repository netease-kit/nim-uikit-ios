// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NIMSDK
import UIKit

class CustomP2PChatViewController: P2PChatViewController {
  override func viewDidLoad() {
    // 自定义消息cell绑定需要放在 super.viewDidLoad() 之前
    NEChatUIKitClient.instance.regsiterCustomCell(["\(customMessageType)": CustomChatCell.self])

    // 通过配置项实现自定义
    customByConfig()

    // 通过重写实现自定义
//    customByOverread()

    super.viewDidLoad()

    // 自定义消息以及外部扩展 覆盖cell UI 样式示例
    customMessage()
  }

  /// 通过配置项实现 UI 自定义
  func customByConfig() {
//    NEKitChatConfig.shared.ui.messageProperties.avatarType = .rectangle
//    NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius = 8.0
//    NEKitChatConfig.shared.ui.messageProperties.signalBgColor = UIColor.ne_backcolor
//    NEKitChatConfig.shared.ui.messageProperties.selfMessageBg = UIColor.ne_greenText
//    NEKitChatConfig.shared.ui.messageProperties.receiveMessageBg = UIColor.ne_greenText
//    NEKitChatConfig.shared.ui.messageProperties.timeTextColor = UIColor.ne_redText
//    NEKitChatConfig.shared.ui.messageProperties.timeTextSize = 18
//    NEKitChatConfig.shared.ui.messageProperties.userNickColor = UIColor.ne_redText
//    NEKitChatConfig.shared.ui.messageProperties.userNickTextSize = 8.0
//    NEKitChatConfig.shared.ui.messageProperties.messageTextColor = UIColor.ne_redColor
//    NEKitChatConfig.shared.ui.messageProperties.messageTextSize = 12
//    NEKitChatConfig.shared.ui.messageProperties.rightBubbleBg = UIImage(named: "copy_right")
//    NEKitChatConfig.shared.ui.messageProperties.leftBubbleBg = UIImage(named: "copy_right")
//    NEKitChatConfig.shared.ui.messageProperties.showP2pMessageStatus = false
//    NEKitChatConfig.shared.ui.messageProperties.showTeamMessageStatus = false
//    NEKitChatConfig.shared.ui.messageProperties.showTitleBar = false
//    NEKitChatConfig.shared.ui.messageProperties.showTitleBarRightIcon = false
//    NEKitChatConfig.shared.ui.messageProperties.titleBarRightRes = UIImage(named: "copy_right")
//    NEKitChatConfig.shared.ui.messageProperties.titleBarRightClick = { [weak self] in
//      self?.showToast("标题栏右侧图标的点击事件")
//    }
//    NEKitChatConfig.shared.ui.messageProperties.chatViewBackground = UIColor.ne_redText

    NEKitChatConfig.shared.ui.messageItemClick = { [weak self] cell, model in
      self?.showToast("点击了消息: \(String(describing: model?.message?.text))")
    }

    /// 文本输入框下方 tab 按钮定制
    NEKitChatConfig.shared.ui.chatInputBar = { [weak self] item in
      // 修改
      let takePicBtn = item[2]
      takePicBtn.setImage(nil, for: .normal)
      takePicBtn.setTitle("拍照", for: .normal)
      takePicBtn.setTitleColor(.blue, for: .normal)
      takePicBtn.removeTarget(takePicBtn.superview, action: nil, for: .allEvents)
      takePicBtn.addTarget(self, action: #selector(self?.customClick), for: .touchUpInside)

      // 新增
      let button = UIButton(type: .custom)
      button.setTitle("新增", for: .normal)
      button.setTitleColor(.blue, for: .normal)
      button.addTarget(self, action: #selector(self?.customClick), for: .touchUpInside)
      item.append(button)
    }

    /// 【更多】区域功能列表自定义示例
    NEKitChatConfig.shared.ui.chatInputMenu = { [weak self] menuList in
      // 新增未知类型
      let itemNew = NEMoreItemModel()
      itemNew.customImage = UIImage(named: "mine_collection")
      itemNew.customDelegate = self
      itemNew.action = #selector(self?.customClick)
      itemNew.title = "新增"
      menuList.append(itemNew)

      // 覆盖已有类型
      // 遍历 menuList， 根据type 覆盖已有类型
      for item in menuList {
        if item.type == .rtc {
          item.customImage = UIImage(named: "mine_setting")
          item.customDelegate = self
          item.action = #selector(self?.customClick)
          item.type = .rtc
          item.title = "覆盖"
        }
      }

      // 移除已有类型
      // 遍历 menuList， 根据type 移除已有类型
      for (i, item) in menuList.enumerated() {
        if item.type == .file {
          menuList.remove(at: i)
        }
      }
    }

    /// 消息长按弹出菜单自定义
    NEKitChatConfig.shared.ui.chatPopMenu = { menuList, model in
      // 遍历 menuList， 根据 type 覆盖已有类型
      // 将所有文本消息的【复制】替换成【粘贴】
      if model?.type == .text {
        for item in menuList {
          if item.type == .copy {
            item.text = "粘贴"
          }
        }
      }
    }

    /// 消息长按弹出菜单点击事件回调，根据按钮类型进行区分
    NEKitChatConfig.shared.ui.popMenuClick = { [weak self] item in
      switch item.type {
      case .copy:
        // 更改【复制】类型按钮的点击事件
        self?.customClick()
      default:
        break
      }
    }

    /// 消息列表的视图控制器回调，回调中会返回消息列表的视图控制器
    NEKitChatConfig.shared.ui.customController = { viewController in
      // 更改导航栏背景色
      viewController.navigationView.backgroundColor = .gray

      // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
      self.customTopView.btn.setTitle("通过配置项添加", for: .normal)
      viewController.bodyTopView.backgroundColor = .purple
      viewController.bodyTopView.addSubview(self.customTopView)
      viewController.bodyTopViewHeight = 80

      // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
      self.customBottomView.btn.setTitle("通过配置项添加", for: .normal)
      viewController.bodyBottomView.backgroundColor = .purple
      viewController.bodyBottomView.addSubview(self.customBottomView)
      viewController.bodyBottomViewHeight = 60
    }
  }

  /// 通过重写实现自定义
  func customByOverread() {
    // 聊天页顶部导航栏下方扩展视图示例
    customTopView.btn.setTitle("通过重写方式添加", for: .normal)
    bodyTopView.addSubview(customTopView)
    bodyTopView.backgroundColor = .yellow
    bodyTopViewHeight = 80

    // 输入框上区域扩展视图示例
    customBottomView.btn.setTitle("通过重写方式添加", for: .normal)
    bodyBottomView.addSubview(customBottomView)
    bodyBottomView.backgroundColor = .yellow
    bodyBottomViewHeight = 60

    // 聊天页输入框左右间距自定义
    chatInputView.textviewLeftConstraint?.constant = 100
    chatInputView.textviewRightConstraint?.constant = -100

    // 自定义底部工具条(未点击更多状态)
    customBottomBar()

    // 长按消息功能弹窗过滤列表（过滤列表中的能力会在整个页面中禁用）
    operationCellFilter = [.delete, .copy]

    /// 【更多】区域功能列表自定义示例

    // 新增未知类型
    let itemNew = NEMoreItemModel()
    itemNew.customImage = UIImage(named: "mine_collection")
    itemNew.customDelegate = self
    itemNew.action = #selector(customClick)
    itemNew.title = "新增"
    NEChatUIKitClient.instance.moreAction.append(itemNew)

    // 覆盖已有类型
    // 遍历 NEChatUIKitClient.instance.moreAction， 根据type 覆盖已有类型
    for (i, item) in NEChatUIKitClient.instance.moreAction.enumerated() {
      if item.type == .rtc {
        let itemReplace = NEChatUIKitClient.instance.moreAction[i]
        itemReplace.customImage = UIImage(named: "mine_setting")
        itemReplace.customDelegate = self
        itemReplace.action = #selector(customClick)
        itemReplace.type = .rtc
        itemReplace.title = "覆盖"
      }
    }

    // 移除已有类型
    // 遍历 NEChatUIKitClient.instance.moreAction， 根据type 移除已有类型
    for (i, item) in NEChatUIKitClient.instance.moreAction.enumerated() {
      if item.type == .file {
        NEChatUIKitClient.instance.moreAction.remove(at: i)
      }
    }
  }

  /// 自定义消息以及外部扩展 覆盖cell UI 样式示例
  func customMessage() {
    // 注册自定义消息的解析器
    NIMCustomObject.registerCustomDecoder(CustomAttachmentDecoder())

    // 测试自定义消息发送按钮
    let testBtn = UIButton()
    testBtn.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(testBtn)
    NSLayoutConstraint.activate([
      testBtn.widthAnchor.constraint(equalToConstant: 100),
      testBtn.heightAnchor.constraint(equalToConstant: 40),
      testBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      testBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    testBtn.backgroundColor = UIColor.red
    testBtn.addTarget(self, action: #selector(sendCustomButton), for: .touchUpInside)
  }

  // 自定义标题
  //    override func getSessionInfo(session: NIMSession) {
  //        super.getSessionInfo(session: session)
  //        title = "小易助手"
  //    }

  // 长按消息功能弹窗列表自定义（可针对不同 type 消息自定义长按功能项）
  //    override func setOperationItems(items: inout [OperationItem], model: MessageContentModel?) {
  //        if model?.type == .rtcCallRecord {
  //            items.append(OperationItem.deleteItem())
  //        }
  //    }

  @objc func customClick() {
    showToast("自定义点击事件")
  }

  func customBottomBar() {
    let subviews = chatInputView.stackView.subviews
    for view in subviews {
      view.removeFromSuperview()
      chatInputView.stackView.removeArrangedSubview(view)
    }

    let titles = ["表情", "语音", "照片", "更多"]
    for i in 0 ..< titles.count {
      let button = UIButton(type: .custom)
      let title = titles[i]
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
      button.tag = i
      button.setTitle(title, for: .normal)
      button.setTitleColor(.blue, for: .normal)
      chatInputView.stackView.addArrangedSubview(button)
    }
  }

  @objc func buttonEvent(_ btn: UIButton) {
    if btn.tag == 0 { // 表情
      layoutInputView(offset: bottomExanpndHeight)
      chatInputView.addEmojiView()
    } else if btn.tag == 1 { // 语音
      layoutInputView(offset: bottomExanpndHeight)
      chatInputView.addRecordView()
    } else if btn.tag == 2 { // 照片
      goPhotoAlbumWithVideo(self)
    } else if btn.tag == 3 { // 更多
      layoutInputView(offset: bottomExanpndHeight)
      chatInputView.addMoreActionView()
    }
  }

  @objc func sendCustomButton() {
    // type 字段必填，用于识别和解析自定义消息
    let data = ["type": customMessageType]
    let neAttach = NECustomAttachment(customType: customMessageType, cellHeight: 50, data: data)
    let attachment = CustomAttachment(neAttach)
    let message = NIMMessage()
    let object = NIMCustomObject()
    object.attachment = attachment
    message.messageObject = object

      NIMSDK.shared().chatManager.send(message, to: viewmodel.session) { error in
        print("send custom message error : ", error?.localizedDescription as Any)
      }
  }

  // MARK: lazy load

  public lazy var customTopView: CustomView = {
    let view = CustomView(frame: CGRect(x: 0, y: 10, width: NEConstant.screenWidth, height: 40))
    view.backgroundColor = .blue
    return view
  }()

  public lazy var customBottomView: CustomView = {
    let view = CustomView(frame: CGRect(x: 0, y: 10, width: NEConstant.screenWidth, height: 40))
    view.backgroundColor = .green
    return view
  }()
}
