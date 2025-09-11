// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactViewController: ContactViewController, NEBaseContactViewControllerDelegate {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    /// 是否在通讯录界面显示头部模块
    ContactUIConfig.shared.showHeader = false

    /// 通讯录列表头部模块的数据回调
    ContactUIConfig.shared.headerData = { viewController, headerData in
      headerData[0].name = "收到的验证消息"
    }

    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    delegate = self
    cellRegisterDic[ContactCellType.ContactCutom.rawValue] = CustomContactTableViewCell.self
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    // 通过重写实现自定义，该方式需要继承自 ChatViewController
    //      customByOverread()

    super.viewDidLoad()
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
  override open func searchAction() {
    bodyTopViewHeight = 80
    bodyBottomViewHeight = 80
  }

  // 通过继承方式重写最右侧按钮点击事件, 这种方式会覆盖配置项中的点击事件
  override open func didClickAddBtn() {
    bodyTopViewHeight = 0
    bodyBottomViewHeight = 0
  }

  //  父类加载完数据后会调用此方法，可在此对数据进行二次处理
  open func onDataLoaded() {
    for info in viewModel.contactSections[1].contacts {
      info.contactCellType = ContactCellType.ContactCutom
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
