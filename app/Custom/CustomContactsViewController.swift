//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactsViewController: ContactsViewController, ContactsViewControllerDelegate {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    delegate = self
    customCells[ContactCellType.ContactCutom.rawValue] = CustomContactTableViewCell.self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    // 通过配置项实现自定义
    configCustom()

    super.viewDidLoad()
    let view = UIView(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: 40))
    view.backgroundColor = .blue
    topView.addSubview(view)
  }

  func configCustom() {
    /// 头像圆角大小
    NEKitContactConfig.shared.ui.avatarCornerRadius = 4.0

    /// 头像类型
    NEKitContactConfig.shared.ui.avatarType = .rectangle

    // 通讯录标题大小
    NEKitContactConfig.shared.ui.titleFont = .systemFont(ofSize: 28)

    /// 通讯录标题颜色
    NEKitContactConfig.shared.ui.titleColor = UIColor.red

    /// 是否隐藏通讯录搜索按钮
    NEKitContactConfig.shared.ui.hiddenSearchBtn = true

    /// 是否把顶部添加好友和搜索按钮都隐藏
    NEKitContactConfig.shared.ui.hiddenRightBtns = false

    /// 通讯录间隔线颜色
    NEKitContactConfig.shared.ui.divideLineColor = UIColor.blue

    /// 检索标题字体颜色
    NEKitContactConfig.shared.ui.indexTitleColor = .green
  }

  @objc private func addItemAction() {
    print("addItemAction")
    topViewHeight = 80
  }

  @objc private func searchItemAction() {
    print("searchItemAction")
    topViewHeight = 0
  }

  public func onDataLoaded() {
    viewModel.contacts[1].contacts.forEach { info in
      info.contactCellType = ContactCellType.ContactCutom.rawValue
    }
  }
}
