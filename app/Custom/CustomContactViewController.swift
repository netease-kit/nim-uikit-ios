// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactViewController: ContactViewController, NEBaseContactViewControllerDelegate {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    /// 是否在通讯录界面显示头部模块
    NEKitContactConfig.shared.ui.showHeader = false

    /// 通讯录列表头部模块的数据回调
    NEKitContactConfig.shared.ui.headerData = { headerData in
      headerData[0].name = "收到的验证消息"
    }

    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    delegate = self
    cellRegisterDic[ContactCellType.ContactCutom.rawValue] = CustomContactTableViewCell.self
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func viewDidLoad() {
    // 通过配置项实现自定义，该方式不需要继承自 ChatViewController
    customByConfig()

    // 通过重写实现自定义，该方式需要继承自 ChatViewController
    //      customByOverread()

    super.viewDidLoad()
  }

  /// 通过配置项实现自定义，该方式不需要继承自 ChatViewController
  func customByConfig() {
    /*
     UI 属性自定义
     */

    /// 头像圆角大小
    NEKitContactConfig.shared.ui.contactProperties.avatarCornerRadius = 4.0

    /// 头像类型
    NEKitContactConfig.shared.ui.contactProperties.avatarType = .rectangle

    // 标题栏文案
    NEKitContactConfig.shared.ui.title = "好友列表"

    /// 标题栏文案颜色
    NEKitContactConfig.shared.ui.titleColor = .purple

    // 通讯录好友标题大小
    NEKitContactConfig.shared.ui.contactProperties.itemTitleSize = 28

    /// 通讯录好友标题颜色
    NEKitContactConfig.shared.ui.contactProperties.itemTitleColor = UIColor.red

    /// 是否展示标题栏
    NEKitContactConfig.shared.ui.showTitleBar = true

    /// 通讯录列表头部模块 cell 点击事件
    NEKitContactConfig.shared.ui.headerItemClick = { info, indexPath in
      self.showToast("点击了头部模块中的第 \(indexPath.row) 个")
    }

    /// 通讯录列表好友 cell 点击事件
    NEKitContactConfig.shared.ui.friendItemClick = { info, indexPath in
      self.showToast("点击了好友列表中的: \(info.user?.showName() ?? "")")
    }

    /// 是否展示标题栏的次最右侧图标
    NEKitContactConfig.shared.ui.showTitleBarRight2Icon = true

    /// 是否展示标题栏的最右侧图标
    NEKitContactConfig.shared.ui.showTitleBarRightIcon = true

    /// 标题栏的最右侧图标
    NEKitContactConfig.shared.ui.titleBarRightRes = UIImage(named: "person")

    /// 标题栏的次最右侧图标
    NEKitContactConfig.shared.ui.titleBarRight2Res = UIImage(named: "contact")

    /// 标题栏最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    NEKitContactConfig.shared.ui.titleBarRightClick = {
      print("addItemAction")
    }

    /// 标题栏次最右侧按钮点击事件，如果已经通过继承方式重写该点击事件, 则本方式会被覆盖
    NEKitContactConfig.shared.ui.titleBarRight2Click = {
      print("searchItemAction")
    }

    /// 通讯录间隔线颜色
    NEKitContactConfig.shared.ui.contactProperties.divideLineColor = UIColor.blue

    /// 检索标题字体颜色
    NEKitContactConfig.shared.ui.contactProperties.indexTitleColor = .green

    /*
     布局自定义
     */
    /// 自定义界面UI接口，回调中会传入会话列表界面的UI布局，您可以进行UI元素调整。
    NEKitContactConfig.shared.ui.customController = { viewController in
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

  /// 通过重写实现自定义布局(这种方式需要继承，从而拿到父类属性)
  func customByOverread() {
    // 顶部bodyTopView中添加自定义view（需要设置bodyTopView的高度）
    customTopView.button.setTitle("通过重写方式添加", for: .normal)
    bodyTopView.addSubview(customTopView)
    bodyTopViewHeight = 80

    // 底部bodyBottomView中添加自定义view（需要设置bodyBottomView的高度）
    customBottomView.button.setTitle("通过重写方式添加", for: .normal)
    bodyBottomView.addSubview(customBottomView)
    bodyBottomViewHeight = 60
  }

  // 通过继承方式重写次最右侧按钮点击事件, 这种方式会覆盖配置项中的点击事件
  override public func searchAction() {
    bodyTopViewHeight = 80
    bodyBottomViewHeight = 80
  }

  // 通过继承方式重写最右侧按钮点击事件, 这种方式会覆盖配置项中的点击事件
  override public func didClickAddBtn() {
    bodyTopViewHeight = 0
    bodyBottomViewHeight = 0
  }

  //  父类加载完数据后会调用此方法，可在此对数据进行二次处理
  public func onDataLoaded() {
    for info in viewModel.contacts[1].contacts {
      info.contactCellType = ContactCellType.ContactCutom.rawValue
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
