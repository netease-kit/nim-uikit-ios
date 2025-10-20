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

  override open func viewDidLoad() {
    // 通过重写实现自定义，该方式需要继承自 ChatViewController
//      customByOverread()

    super.viewDidLoad()
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

  override open func deleteActionHandler(indexPath: IndexPath) {
    showSingleAlert(message: "override deleteActionHandler") {}
  }

  override open func topActionHandler(indexPath: IndexPath, isTop: Bool) {
    showSingleAlert(message: "override topActionHandler") {
      super.topActionHandler(indexPath: indexPath, isTop: isTop)
    }
  }

  //  可自行处理数据
  open func onDataLoaded() {
    for model in viewModel.conversationListData {
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
