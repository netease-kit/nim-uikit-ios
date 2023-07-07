//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEConversationUIKit

open class CustomConversationController: ConversationController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    listCtrl = CustomConversationListViewController()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    // 通过配置项实现自定义
    configCustom()

    // 实现协议（重写tabbar点击事件）
    navView.delegate = self

    // 自定义会话列表标题、图标、间距
    navView.brandBtn.setTitle("消息", for: .normal)
    navView.brandBtn.setImage(nil, for: .normal)
    navView.brandBtn.layoutButtonImage(style: .left, space: 0)

    // 自定义tabbar图标
    navView.addBtn.setImage(UIImage.ne_imageNamed(name: "noNeed_notify"), for: .normal)

    // 顶部topView中添加自定义view（需要设置topView的高度）
    let view = CustomTopView(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 40))
    view.backgroundColor = .blue
//    listCtrl.topViewHeight = 40
    listCtrl.topView.addSubview(view)

    // 自定义占位图文案、背景图片
    listCtrl.emptyView.setEmptyImage(image: UIImage())
    listCtrl.emptyView.settingContent(content: "")

    viewmodel.repo.clearAllUnreadCount()

    super.viewDidLoad()
  }

  open func configCustom() {
    /// 头像圆角大小
    NEKitConversationConfig.shared.ui.avatarCornerRadius = 4.0

    /// 头像类型
    NEKitConversationConfig.shared.ui.avatarType = .rectangle

    /// 是否隐藏导航栏
//        NEKitConversationConfig.shared.ui.hiddenNav = true

    /// 是否隐藏搜索按钮
    NEKitConversationConfig.shared.ui.hiddenSearchBtn = true

//        / 是否把顶部添加按钮和搜索按钮都隐藏
//        NEKitConversationConfig.shared.ui.hiddenRightBtns = true

    // 主标题字体大小
    NEKitConversationConfig.shared.ui.titleFont = .systemFont(ofSize: 24)

    // 副标题字体大小
    NEKitConversationConfig.shared.ui.subTitleFont = .systemFont(ofSize: 18)

    // 主标题字体颜色
    NEKitConversationConfig.shared.ui.titleColor = UIColor.red

    // 副标题字体颜色
    NEKitConversationConfig.shared.ui.subTitleColor = UIColor.blue

    /// 时间字体颜色
    NEKitConversationConfig.shared.ui.timeColor = UIColor.green

    /// 时间字体大小
    NEKitConversationConfig.shared.ui.timeFont = UIFont.systemFont(ofSize: 14)

    /// 会话列表 cell 左划置顶按钮文案内容
    NEKitConversationConfig.shared.ui.stickTopBottonTitle = "文案"
    /// 会话列表 cell 左划取消置顶按钮文案内容
    NEKitConversationConfig.shared.ui.stickTopBottonCancelTitle = "文案1"
    /// 会话列表 cell 左划置顶按钮文案颜色
    NEKitConversationConfig.shared.ui.stickTopBottonColor = UIColor.yellow

    /// 会话列表 cell 左划删除按钮文案内容
    NEKitConversationConfig.shared.ui.deleteBottonTitle = "文案2"
    /// 会话列表 cell 左划删除按钮文案颜色
    NEKitConversationConfig.shared.ui.deleteBottonColor = UIColor.gray
  }

  // 重写搜索按钮点击事件
  override open func searchAction() {
    listCtrl.topViewHeight = 80
  }

  // 重写添加按钮点击事件
  override open func didClickAddBtn() {
    showSingleAlert(message: "override didClickAddBtn") {
      self.listCtrl.topViewHeight = 0
    }
  }
}
