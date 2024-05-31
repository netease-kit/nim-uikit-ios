// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEConversationUIKit

open class CustomConversationController: ConversationController, NEBaseConversationControllerDelegate {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    delegate = self

    // 自定义cell, [ConversationListModel.customType: 需要注册的自定义cell]
    cellRegisterDic[1] = CustomConversationListCell.self
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func viewDidLoad() {
    // 通过配置项实现自定义，该方式不需要继承自 ChatViewController
    customByConfig()

    // 通过重写实现自定义，该方式需要继承自 ChatViewController
//      customByOverread()

    super.viewDidLoad()
  }

  /// 通过配置项实现自定义(这种方式不需要继承就可以实现 UI 自定义)
  open func customByConfig() {
    /*
     UI 属性自定义
     */

    /// 头像圆角大小
    NEKitConversationConfig.shared.ui.conversationProperties.avatarCornerRadius = 4.0

    /// 头像类型
    NEKitConversationConfig.shared.ui.conversationProperties.avatarType = .rectangle

    /// 是否展示界面顶部的标题栏
    NEKitConversationConfig.shared.ui.showTitleBar = true

    /// 是否展示标题栏次最右侧图标
    NEKitConversationConfig.shared.ui.showTitleBarRight2Icon = true

    /// 是否展示标题栏最右侧图标
    NEKitConversationConfig.shared.ui.showTitleBarRightIcon = true

    // 自定义会话列表标题、图标
    NEKitConversationConfig.shared.ui.titleBarTitle = "消息"
    NEKitConversationConfig.shared.ui.titleBarTitleColor = .purple
    NEKitConversationConfig.shared.ui.titleBarLeftRes = UIImage()

    // 未被置顶的会话项的背景色
    NEKitConversationConfig.shared.ui.conversationProperties.itemBackground = .gray

    // 置顶的会话项的背景色
    NEKitConversationConfig.shared.ui.conversationProperties.itemStickTopBackground = .orange

    // 主标题字体大小
    NEKitConversationConfig.shared.ui.conversationProperties.itemTitleSize = 24

    // 主标题字体大小
    NEKitConversationConfig.shared.ui.conversationProperties.itemTitleSize = 24

    // 副标题字体大小
    NEKitConversationConfig.shared.ui.conversationProperties.itemContentSize = 18

    // 主标题字体颜色
    NEKitConversationConfig.shared.ui.conversationProperties.itemTitleColor = UIColor.red

    // 副标题字体颜色
    NEKitConversationConfig.shared.ui.conversationProperties.itemContentColor = UIColor.blue

    /// 时间字体颜色
    NEKitConversationConfig.shared.ui.conversationProperties.itemDateColor = UIColor.green

    /// 时间字体大小
    NEKitConversationConfig.shared.ui.conversationProperties.itemDateSize = 14

    /// 会话列表 cell 左划置顶按钮文案内容
    NEKitConversationConfig.shared.ui.stickTopButtonTitle = "左侧"
    /// 会话列表 cell 左划取消置顶按钮文案内容（会话置顶后生效）
    NEKitConversationConfig.shared.ui.stickTopButtonCancelTitle = "左侧1"
    /// 会话列表 cell 左划置顶按钮背景颜色
    NEKitConversationConfig.shared.ui.stickTopButtonBackgroundColor = UIColor.brown
    /// 会话列表 cell 左划置顶按钮点击事件
    NEKitConversationConfig.shared.ui.stickTopButtonClick = { model, indexPath in
      self.showToast("会话列表 cell 左划置顶按钮点击事件")
    }

    /// 会话列表 cell 左划删除按钮文案内容
    NEKitConversationConfig.shared.ui.deleteButtonTitle = "右侧"
    /// 会话列表 cell 左划删除按钮背景颜色
    NEKitConversationConfig.shared.ui.deleteButtonBackgroundColor = UIColor.purple
    /// 会话列表 cell 左划删除按钮点击事件
    NEKitConversationConfig.shared.ui.deleteButtonClick = { model, indexPath in
      self.showToast("会话列表 cell 左划删除按钮点击事件")
    }

    /// 标题栏左侧按钮点击事件
    NEKitConversationConfig.shared.ui.titleBarLeftClick = {
      self.showSingleAlert(message: "titleBarLeftClick") {}
    }

    /// 标题栏最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    NEKitConversationConfig.shared.ui.titleBarRightClick = {
      self.showToast("didClickAddBtn")
    }

    /// 标题栏次最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    NEKitConversationConfig.shared.ui.titleBarRight2Click = {
      self.showToast("didClickSearchBtn")
    }

    /// 会话列表点击事件
    NEKitConversationConfig.shared.ui.itemClick = { model, indexPath in
      self.showToast(model?.conversation?.name ?? "会话列表点击事件")
    }

    /*
     布局自定义
     */
    /// 自定义界面UI接口，回调中会传入会话列表界面的UI布局，您可以进行UI元素调整。
    NEKitConversationConfig.shared.ui.customController = { viewController in
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

  /// 通过重写实现自定义布局(这种方式需要继承，拿到父类属性)
  open func customByOverread() {
    // 实现协议（重写tabbar点击事件）
    navigationView.delegate = self

    // 自定义会话列表标题、图标、间距
    navigationView.brandBtn.setTitle("消息", for: .normal)
    navigationView.brandBtn.setImage(nil, for: .normal)
    navigationView.brandBtn.layoutButtonImage(style: .left, space: 0)

    // 自定义添加按钮图标
    navigationView.addBtn.setImage(UIImage.ne_imageNamed(name: "noNeed_notify"), for: .normal)

    // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
    customTopView.button.setTitle("通过重写方式添加", for: .normal)
    bodyTopView.addSubview(customTopView)
    bodyTopViewHeight = 80

    // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
    customBottomView.button.setTitle("通过重写方式添加", for: .normal)
    bodyBottomView.addSubview(customBottomView)
    bodyBottomViewHeight = 60

    // 自定义占位图文案、背景图片
    emptyView.setEmptyImage(image: UIImage())
    emptyView.setText("")
  }

  // 通过继承方式重写次最右侧按钮点击事件, 这种方式会覆盖配置项中的点击事件
  override open func searchAction() {
    bodyTopViewHeight = 80
    bodyBottomViewHeight = 80
  }

  // 通过继承方式重写最右侧按钮点击事件, 这种方式会覆盖配置项中的点击事件
  override open func didClickAddBtn() {
    bodyTopViewHeight = 0
    bodyBottomViewHeight = 0
  }

  override open func deleteActionHandler(action: UITableViewRowAction?, indexPath: IndexPath) {
    showSingleAlert(message: "override deleteActionHandler") {}
  }

  override open func topActionHandler(action: UITableViewRowAction?, indexPath: IndexPath, isTop: Bool) {
    showSingleAlert(message: "override topActionHandler") {
      super.topActionHandler(action: action, indexPath: indexPath, isTop: isTop)
    }
  }

  //  可自行处理数据
  public func onDataLoaded() {
    for model in viewModel.conversationListData {
      model.customType = 1
    }
    for model in viewModel.stickTopConversations {
      model.customType = 1
    }
    tableView.reloadData()
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
