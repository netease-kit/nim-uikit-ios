// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEChatUIKit
import NIMSDK
import UIKit

class CustomP2PChatViewController: P2PChatViewController {
  let customMessageType = 20
  override func viewDidLoad() {
    // 自定义消息cell绑定需要放在 super.viewDidLoad() 之前
    NEChatUIKitClient.instance.regsiterCustomCell(["\(customMessageType)": CustomChatCell.self])

    // 通过重写实现自定义，该方式需要继承自 ChatViewController
    customByOverread()

    super.viewDidLoad()

    // 自定义消息以及外部扩展 覆盖cell UI 样式示例
    customMessage()
  }

  /// 通过重写实现自定义布局(这种方式需要继承，从而拿到父类属性)
  func customByOverread() {
    // 聊天页顶部导航栏下方扩展视图示例
    customTopView.button.setTitle("通过重写方式添加", for: .normal)
    bodyTopView.addSubview(customTopView)
    bodyTopView.backgroundColor = .yellow
    bodyTopViewHeight = 80

    // 输入框上区域扩展视图示例
    customBottomView.button.setTitle("通过重写方式添加", for: .normal)
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
    itemNew.action = { viewController, item in
      viewController.showToast("【更多】区域功能自定义点击事件")
    }
    itemNew.title = "新增"
    NEChatUIKitClient.instance.moreAction.append(itemNew)

    // 覆盖已有类型
    // 遍历 NEChatUIKitClient.instance.moreAction， 根据type 覆盖已有类型
    for (i, item) in NEChatUIKitClient.instance.moreAction.enumerated() {
      if item.type == .rtc {
        let itemReplace = NEChatUIKitClient.instance.moreAction[i]
        itemReplace.customImage = UIImage(named: "mine_setting")
        itemReplace.action = { viewController, item in
          viewController.showToast("【更多】区域功能自定义点击事件")
        }
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
    // 测试自定义消息发送按钮
    let testButton = UIButton()
    testButton.translatesAutoresizingMaskIntoConstraints = false
    testButton.setTitle("发送自定义消息", for: .normal)
    testButton.titleLabel?.font = .systemFont(ofSize: 12)
    view.addSubview(testButton)
    NSLayoutConstraint.activate([
      testButton.widthAnchor.constraint(equalToConstant: 120),
      testButton.heightAnchor.constraint(equalToConstant: 40),
      testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    testButton.backgroundColor = UIColor.red
    testButton.addTarget(self, action: #selector(sendCustomButton), for: .touchUpInside)
  }

  // 自定义标题
  override func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    super.getSessionInfo(sessionId: sessionId) {
      self.title = "小易助手"
      completion()
    }
  }

  // 长按消息功能弹窗列表自定义（可针对不同 type 消息自定义长按功能项）
  override func setOperationItems(items: inout [OperationItem], model: MessageContentModel?) {
    if model?.type == .rtcCallRecord {
      items.append(OperationItem.replayItem())
    }
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
      layoutInputView(offset: bottomExanpndHeight, true)
      chatInputView.addEmojiView()
    } else if btn.tag == 1 { // 语音
      layoutInputView(offset: bottomExanpndHeight, true)
      chatInputView.addRecordView()
    } else if btn.tag == 2 { // 照片
      goPhotoAlbumWithVideo(self)
    } else if btn.tag == 3 { // 更多
      layoutInputView(offset: bottomExanpndHeight, true)
      chatInputView.addMoreActionView()
    }
  }

  @objc func sendCustomButton() {
    // type 自定义消息类型，该字段必须指定，且不可为 101、102（UIKit 内部已使用），否则解析为【未知消息体】
    // customHeight 自定义消息的高度
    let dataDic: [String: Any] = ["type": customMessageType, "customHeight": 100]
    let dataJson = NECommonUtil.getJSONStringFromDictionary(dataDic)
    let customMessage = MessageUtils.customMessage(text: "this is a custom message, create time:\(Date.timeIntervalSinceReferenceDate)",
                                                   rawAttachment: dataJson)

    ChatRepo.shared.sendMessage(message: customMessage, conversationId: ChatRepo.conversationId) { result, error, pro in
      if let err = error {
        print("send custom message error : ", err.localizedDescription)
      }
    }
  }

  /// 获取消息模型，可在此处对消息体进行修改
  /// - Parameter model: 模型
  override func getMessageModel(model: any MessageModel) {
    super.getMessageModel(model: model)

    // 例如设置自定义消息高度
    if model.type == .custom {
      if model.customType == customMessageType {
        // 设置气泡宽高，不设置则不展示气泡
        model.contentSize = CGSize(width: 20, height: 20)
        // 设置 cell 高度
        model.height = 50
      }
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
