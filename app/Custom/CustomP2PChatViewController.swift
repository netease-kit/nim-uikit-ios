//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatUIKit
import NIMSDK
class CustomP2PChatViewController: P2PChatViewController {
  override func viewDidLoad() {
//      NEKitChatConfig.shared.ui.avatarType = .rectangle
//      NEKitChatConfig.shared.ui.avatarCornerRadius = 8.0
//      NEKitChatConfig.shared.ui.signalBgColor = UIColor.ne_backcolor
//      NEKitChatConfig.shared.ui.selfMessageBg = UIColor.ne_greenText
//      NEKitChatConfig.shared.ui.receiveMessageBg = UIColor.ne_greenText
//      NEKitChatConfig.shared.ui.timeTextColor = UIColor.ne_redText
//      NEKitChatConfig.shared.ui.timeTextSize = 18
//      NEKitChatConfig.shared.ui.userNickColor = UIColor.ne_redText
//      NEKitChatConfig.shared.ui.userNickTextSize = 8.0
//      NEKitChatConfig.shared.ui.messageTextColor = UIColor.ne_redColor
//      NEKitChatConfig.shared.ui.messageTextSize = UIFont.systemFont(ofSize: 12)
//      NEKitChatConfig.shared.ui.rightBubbleBg = UIImage(named: "copy_right")
//      NEKitChatConfig.shared.ui.leftBubbleBg = UIImage(named: "copy_right")
//      NEKitChatConfig.shared.ui.showP2pMessageStatus = false
//      NEKitChatConfig.shared.ui.showTeamMessageStatus = false
//    NEKitChatConfig.shared.ui.showTitleBar = false
//      NEKitChatConfig.shared.ui.showTitleBarRightIcon = false
//      NEKitChatConfig.shared.ui.titleBarRightRes = UIImage(named: "copy_right")
//      NEKitChatConfig.shared.ui.titleBarRightClick = {[weak self] in
//          self?.showToast("dfnaskfnas")
//      }
//    NEKitChatConfig.shared.ui.chatViewBackground = UIColor.ne_redText

    /*
     // 聊天面板外部扩展示例
     // 新增未知类型
     let itemNew = NEMoreItemModel()
     itemNew.customImage = UIImage(named: "mine_collection")
     itemNew.customDelegate = self
     itemNew.action = #selector(testLog)
     itemNew.title = "新增"
     NEChatUIKitClient.instance.moreAction.append(itemNew)

     // 覆盖已有类型
     // 遍历 NEChatUIKitClient.instance.moreAction， 根据type 覆盖已有类型
     for (i, item) in NEChatUIKitClient.instance.moreAction.enumerated() {
       if item.type == .rtc {
         let itemReplace = NEChatUIKitClient.instance.moreAction[i]
         itemReplace.customImage = UIImage(named: "mine_setting")
         itemReplace.customDelegate = self
         itemReplace.action = #selector(testLog)
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
        @objc func testLog() {
          print("聊天面板外部扩展示例")
        }

        */

    // 输入框上区域扩展视图示例
    /*
     inputTopExtendHeight = 20
     let topCustom = UIView()
     topCustom.translatesAutoresizingMaskIntoConstraints = false
     topCustom.backgroundColor = UIColor.yellow
     inputTopExtendView.addSubview(topCustom)
     NSLayoutConstraint.activate([
         topCustom.leftAnchor.constraint(equalTo: inputTopExtendView.leftAnchor),
         topCustom.rightAnchor.constraint(equalTo: inputTopExtendView.rightAnchor),
         topCustom.topAnchor.constraint(equalTo: inputTopExtendView.topAnchor),
         topCustom.bottomAnchor.constraint(equalTo: inputTopExtendView.bottomAnchor)
     ])
      */

    // 聊天页顶部导航栏下方扩展视图示例
    /*
     navigationBarBottomExtendHeight = 20
     let bottomCustom = UIView()
     bottomCustom.translatesAutoresizingMaskIntoConstraints = false
     bottomCustom.backgroundColor = UIColor.yellow
     navigationBarBottomExtendView.addSubview(bottomCustom)
     NSLayoutConstraint.activate([
       bottomCustom.leftAnchor.constraint(equalTo: navigationBarBottomExtendView.leftAnchor),
       bottomCustom.rightAnchor.constraint(equalTo: navigationBarBottomExtendView.rightAnchor),
       bottomCustom.topAnchor.constraint(equalTo: navigationBarBottomExtendView.topAnchor),
       bottomCustom.bottomAnchor.constraint(equalTo: navigationBarBottomExtendView.bottomAnchor),
     ]) */

    // 自定义消息以及外部扩展 覆盖cell UI 样式示例
    // 注册自定义消息的解析器
    /*
     NIMCustomObject.registerCustomDecoder(CustomAttachmentDecoder())
     NEChatUIKitClient.instance.regsiterCustomCell(["20": CustomChatCell.self])

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
      */

    super.viewDidLoad()

    // 聊天页输入框左右间距自定义
    /*
     menuView.textviewLeftConstraint?.constant = 100
     menuView.textviewRightConstraint?.constant = -100
      */

    // 自定义底部工具条(未点击更多状态)
    /*
      customBottomBar()
     */

    // 长按消息功能弹窗过滤列表（过滤列表中的能力会在整个页面中禁用）
    /*
     operationCellFilter = [.delete, .copy]
      */

    // Do any additional setup after loading the view.
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

  @objc func testLog() {
    print("聊天面板外部扩展示例")
  }

  func customBottomBar() {
    let subviews = menuView.stackView.subviews
    subviews.forEach { view in
      view.removeFromSuperview()
      menuView.stackView.removeArrangedSubview(view)
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
      menuView.stackView.addArrangedSubview(button)
    }
  }

  @objc func buttonEvent(_ btn: UIButton) {
    if btn.tag == 0 { // 表情
      layoutInputView(offset: bottomExanpndHeight)
      menuView.addEmojiView()
    } else if btn.tag == 1 { // 语音
      layoutInputView(offset: bottomExanpndHeight)
      menuView.addRecordView()
    } else if btn.tag == 2 { // 照片
      goPhotoAlbumWithVideo(self)
    } else if btn.tag == 3 { // 更多
      layoutInputView(offset: bottomExanpndHeight)
      menuView.addMoreActionView()
    }
  }

  @objc func sendCustomButton() {
    let attachment = CustomAttachment()
    attachment.customType = 20
    attachment.cellHeight = 50
    let message = NIMMessage()
    let object = NIMCustomObject()
    object.attachment = attachment
    message.messageObject = object

    NIMSDK.shared().chatManager.send(message, to: viewmodel.session) { error in
      print("send custom message error : ", error?.localizedDescription as Any)
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
