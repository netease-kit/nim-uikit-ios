//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatUIKit
import NEContactUIKit
import NEConversationUIKit

/// 自定义配置项示例类
public class CustomConfig {
  public static let shared = CustomConfig()

  /// 通过配置项实现 UI 自定义，该方式不需要继承自 ChatViewController
  open func configChatUIKit() {
    ChatUIConfig.shared.messageProperties.avatarType = .cycle
    ChatUIConfig.shared.messageProperties.avatarCornerRadius = 8.0
    ChatUIConfig.shared.messageProperties.signalBgColor = UIColor.yellow
    ChatUIConfig.shared.messageProperties.selfMessageBg = UIColor.ne_greenText
    ChatUIConfig.shared.messageProperties.receiveMessageBg = UIColor.ne_greenText
    ChatUIConfig.shared.messageProperties.timeTextColor = UIColor.ne_darkText
    ChatUIConfig.shared.messageProperties.timeTextSize = 18
    ChatUIConfig.shared.messageProperties.userNickColor = UIColor.ne_redText
    ChatUIConfig.shared.messageProperties.userNickTextSize = 8.0
    ChatUIConfig.shared.messageProperties.messageTextColor = UIColor.ne_redColor
    ChatUIConfig.shared.messageProperties.messageTextSize = 12
    ChatUIConfig.shared.messageProperties.rightBubbleBg = UIImage(named: "copy_right")
    ChatUIConfig.shared.messageProperties.leftBubbleBg = UIImage(named: "copy_right")
    ChatUIConfig.shared.messageProperties.showP2pMessageStatus = false
    ChatUIConfig.shared.messageProperties.showTeamMessageStatus = false
    //    ChatUIConfig.shared.messageProperties.showTitleBar = false
    //    ChatUIConfig.shared.messageProperties.showTitleBarRightIcon = false
    ChatUIConfig.shared.messageProperties.titleBarRightRes = UIImage(named: "copy_right")
    ChatUIConfig.shared.messageProperties.titleBarRightClick = { viewController in
      viewController.showToast("标题栏右侧图标的点击事件")
    }
    ChatUIConfig.shared.messageProperties.chatViewBackground = UIColor.ne_redText

    ChatUIConfig.shared.messageItemClick = { viewController, cell, model in
      viewController.showToast("点击了消息: \(String(describing: model?.message?.text))")
    }

    /// 文本输入框下方 tab 按钮定制
    ChatUIConfig.shared.chatInputBar = { [weak self] viewController, item in
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
    ChatUIConfig.shared.chatInputMenu = { viewController, menuList in
      // 新增未知类型
      let itemNew = NEMoreItemModel()
      itemNew.customImage = UIImage(named: "mine_collection")
      itemNew.action = { viewController, item in
        viewController.showToast("【更多】区域功能自定义点击事件")
      }
      itemNew.title = "新增"
      menuList.append(itemNew)

      // 覆盖已有类型
      // 遍历 menuList， 根据type 覆盖已有类型
      for item in menuList {
        if item.type == .rtc {
          item.customImage = UIImage(named: "mine_setting")
          itemNew.action = { viewController, item in
            viewController.showToast("【更多】区域功能自定义点击事件")
          }
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
    ChatUIConfig.shared.chatPopMenu = { viewController, menuList, model in
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
    ChatUIConfig.shared.popMenuClick = { viewController, item in
      switch item.type {
      case .copy:
        // 更改【复制】类型按钮的点击事件
        viewController.showToast("自定义点击事件")
      default:
        break
      }
    }

    /// 消息列表的视图控制器回调，回调中会返回消息列表的视图控制器
    ChatUIConfig.shared.customController = { viewController in
      // 更改导航栏背景色
      viewController.navigationView.backgroundColor = .gray

      // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
      self.customTopView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyTopView.backgroundColor = .purple
      viewController.bodyTopView.addSubview(self.customTopView)
      viewController.bodyTopViewHeight = 80

      // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
      self.customBottomView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyBottomView.backgroundColor = .purple
      viewController.bodyBottomView.addSubview(self.customBottomView)
      viewController.bodyBottomViewHeight = 60
    }

    /// 消息列表发送消息前的回调
    /// 回调参数：消息参数（包含消息和发送参数）和消息列表的视图控制器
    /// 返回值/回调值：（修改后的）消息参数，若消息参数为 nil，则表示拦截该消息不发送
    /// beforeSend 与 beforeSendCompletion 只能二设一，同时设置时优先使用 beforeSend
    ChatKitClient.shared.beforeSend = { viewController, param in
      param.message.text = (param.message.text ?? "") + "[拦截1]"
      return param
    }

    ChatKitClient.shared.beforeSendCompletion = { viewController, param, completion in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: {
        param.message.text = (param.message.text ?? "") + "[拦截2]"
        completion(param)
      }))
    }

    /// 本端发送消息后的回调，为 sendMessage 接口callback，可在回调中获取消息反垃圾结果
    /// - Parameter completion: sendMessage 接口调用回调
    ChatKitClient.shared.sendMessageCallback = { viewController, result, error, progress in
      if let antispamResult = result?.antispamResult {
        viewController.showToast("反垃圾结果：\(antispamResult)")
      }
    }
  }

  /// 通过配置项实现自定义，该方式不需要继承自 ContactViewController
  open func configContactUIKit() {
    /*
     UI 属性自定义
     */

    /// 头像圆角大小
    ContactUIConfig.shared.contactProperties.avatarCornerRadius = 4.0

    /// 头像类型
    ContactUIConfig.shared.contactProperties.avatarType = .cycle

    // 标题栏文案
    ContactUIConfig.shared.title = "好友列表"

    /// 标题栏文案颜色
    ContactUIConfig.shared.titleColor = .purple

    // 通讯录好友标题大小
    ContactUIConfig.shared.contactProperties.itemTitleSize = 28

    /// 通讯录好友标题颜色
    ContactUIConfig.shared.contactProperties.itemTitleColor = UIColor.red

    /// 是否展示标题栏
    ContactUIConfig.shared.showTitleBar = true

    /// 通讯录列表头部模块 cell 点击事件
    ContactUIConfig.shared.headerItemClick = { viewController, info, indexPath in
      viewController.showToast("点击了头部模块中的第 \(indexPath.row) 个")
    }

    /// 通讯录列表好友 cell 点击事件
    ContactUIConfig.shared.friendItemClick = { viewController, info, indexPath in
      viewController.showToast("点击了好友列表中的: \(info.user?.showName() ?? "")")
    }

    /// 是否展示标题栏的次最右侧图标
    ContactUIConfig.shared.showTitleBarRight2Icon = true

    /// 是否展示标题栏的最右侧图标
    ContactUIConfig.shared.showTitleBarRightIcon = true

    /// 标题栏的最右侧图标
    ContactUIConfig.shared.titleBarRightRes = UIImage(named: "person")

    /// 标题栏的次最右侧图标
    ContactUIConfig.shared.titleBarRight2Res = UIImage(named: "contact")

    /// 标题栏最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    ContactUIConfig.shared.titleBarRightClick = { viewController in
      print("addItemAction")
    }

    /// 标题栏次最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    ContactUIConfig.shared.titleBarRight2Click = { viewController in
      print("searchItemAction")
    }

    /// 通讯录间隔线颜色
    ContactUIConfig.shared.contactProperties.divideLineColor = UIColor.blue

    /// 检索标题字体颜色
    ContactUIConfig.shared.contactProperties.indexTitleColor = .green

    /*
     布局自定义
     */
    /// 自定义界面UI接口，回调中会传入会话列表界面的UI布局，您可以进行UI元素调整。
    ContactUIConfig.shared.customController = { viewController in
      // 更改导航栏背景色
      viewController.navigationView.backgroundColor = .gray

      // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
      self.customTopView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyTopView.backgroundColor = .purple
      viewController.bodyTopView.addSubview(self.customTopView)
      viewController.bodyTopViewHeight = 80

      // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
      self.customBottomView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyBottomView.backgroundColor = .purple
      viewController.bodyBottomView.addSubview(self.customBottomView)
      viewController.bodyBottomViewHeight = 60
    }
  }

  /// 通过配置项实现自定义，该方式不需要继承自 ConversationController
  open func configConversationUIKit() {
    /*
     UI 属性自定义
     */

    /// 头像圆角大小
    ConversationUIConfig.shared.conversationProperties.avatarCornerRadius = 4.0

    /// 头像类型
    ConversationUIConfig.shared.conversationProperties.avatarType = .cycle

    /// 是否展示界面顶部的标题栏
    ConversationUIConfig.shared.showTitleBar = true

    /// 是否展示标题栏次最右侧图标
    ConversationUIConfig.shared.showTitleBarRight2Icon = true

    /// 是否展示标题栏最右侧图标
    ConversationUIConfig.shared.showTitleBarRightIcon = true

    // 自定义会话列表标题、图标
    ConversationUIConfig.shared.titleBarTitle = "消息"
    ConversationUIConfig.shared.titleBarTitleColor = .purple
    ConversationUIConfig.shared.titleBarLeftRes = UIImage()

    // 未被置顶的会话项的背景色
    ConversationUIConfig.shared.conversationProperties.itemBackground = .gray

    // 置顶的会话项的背景色
    ConversationUIConfig.shared.conversationProperties.itemStickTopBackground = .orange

    // 主标题字体大小
    ConversationUIConfig.shared.conversationProperties.itemTitleSize = 24

    // 主标题字体大小
    ConversationUIConfig.shared.conversationProperties.itemTitleSize = 24

    // 副标题字体大小
    ConversationUIConfig.shared.conversationProperties.itemContentSize = 18

    // 主标题字体颜色
    ConversationUIConfig.shared.conversationProperties.itemTitleColor = UIColor.red

    // 副标题字体颜色
    ConversationUIConfig.shared.conversationProperties.itemContentColor = UIColor.blue

    /// 时间字体颜色
    ConversationUIConfig.shared.conversationProperties.itemDateColor = UIColor.green

    /// 时间字体大小
    ConversationUIConfig.shared.conversationProperties.itemDateSize = 14

    /// 会话列表 cell 左划置顶按钮文案内容
    ConversationUIConfig.shared.stickTopButtonTitle = "左侧"
    /// 会话列表 cell 左划取消置顶按钮文案内容（会话置顶后生效）
    ConversationUIConfig.shared.stickTopButtonCancelTitle = "左侧1"
    /// 会话列表 cell 左划置顶按钮背景颜色
    ConversationUIConfig.shared.stickTopButtonBackgroundColor = UIColor.brown
    /// 会话列表 cell 左划置顶按钮点击事件
    ConversationUIConfig.shared.stickTopButtonClick = { viewController, model, indexPath in
      viewController.showToast("会话列表 cell 左划置顶按钮点击事件")
    }

    /// 会话列表 cell 左划删除按钮文案内容
    ConversationUIConfig.shared.deleteButtonTitle = "右侧"
    /// 会话列表 cell 左划删除按钮背景颜色
    ConversationUIConfig.shared.deleteButtonBackgroundColor = UIColor.purple
    /// 会话列表 cell 左划删除按钮点击事件
    ConversationUIConfig.shared.deleteButtonClick = { viewController, model, indexPath in
      viewController.showToast("会话列表 cell 左划删除按钮点击事件")
    }

    /// 标题栏左侧按钮点击事件
    ConversationUIConfig.shared.titleBarLeftClick = { viewController in
      viewController.showSingleAlert(message: "titleBarLeftClick") {}
    }

    /// 标题栏最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    ConversationUIConfig.shared.titleBarRightClick = { viewController in
      viewController.showToast("didClickAddBtn")
    }

    /// 标题栏次最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    ConversationUIConfig.shared.titleBarRight2Click = { viewController in
      viewController.showToast("didClickSearchBtn")
    }

    /// 会话列表点击事件
    ConversationUIConfig.shared.itemClick = { viewController, model, indexPath in
      viewController.showToast(model?.conversation?.name ?? "会话列表点击事件")
    }

    /*
     布局自定义
     */
    /// 自定义界面UI接口，回调中会传入会话列表界面的UI布局，您可以进行UI元素调整。
    ConversationUIConfig.shared.customController = { viewController in
      // 更改导航栏背景色
      viewController.navigationView.backgroundColor = .gray

      // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
      self.customTopView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyTopView.backgroundColor = .purple
      viewController.bodyTopView.addSubview(self.customTopView)
      viewController.bodyTopViewHeight = 80

      // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
      self.customBottomView.button.setTitle("通过配置项添加", for: .normal)
      viewController.bodyBottomView.backgroundColor = .purple
      viewController.bodyBottomView.addSubview(self.customBottomView)
      viewController.bodyBottomViewHeight = 60
    }
  }

  /// 通过布局自定义实现顶部警告
  open func loadSecurityWarningView() {
    ConversationUIConfig.shared.customController = { [weak self] viewController in
      guard let self = self else {
        return
      }

      // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
      self.securityWarningView.warningLabel.text = localizable("security_warning")
      viewController.bodyTopView.addSubview(self.securityWarningView)
      NSLayoutConstraint.activate([
        self.securityWarningView.topAnchor.constraint(equalTo: viewController.bodyTopView.topAnchor),
        self.securityWarningView.leftAnchor.constraint(equalTo: viewController.bodyTopView.leftAnchor),
        self.securityWarningView.rightAnchor.constraint(equalTo: viewController.bodyTopView.rightAnchor),
        self.securityWarningView.heightAnchor.constraint(equalToConstant: 56),
      ])
      viewController.bodyTopViewHeight = 56
    }
  }

  @objc func customClick(_ button: UIButton) {
    button.neViewContainingController()?.showToast("文本输入框下方 tab 按钮自定义点击事件")
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

  public lazy var securityWarningView: NESecurityWarningView = {
    let view = NESecurityWarningView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
}
