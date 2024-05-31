// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

/// 人员选择页面 - 通用版
@objcMembers
open class FunContactSelectedViewController: NEBaseContactSelectedViewController {
  override init(filterUsers: Set<String>? = nil) {
    super.init(filterUsers: filterUsers)
    customCells = [ContactCellType.ContactPerson.rawValue: FunContactSelectedCell.self]
    view.backgroundColor = .funContactBackgroundColor
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    collectionBackViewTopMargin = 12
    super.setupUI()
    emptyView.setEmptyImage(name: "fun_user_empty")
    collectionBackView.backgroundColor = .white
    collectionView.register(
      FunContactUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(FunContactUnCheckCell.self))"
    )
    tableView.rowHeight = 64
  }

  override open func setupNavRightItem() {
    super.setupNavRightItem()
    navigationView.setBackButtonTitle(localizable("close"))
    navigationView.backButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.moreButton.backgroundColor = .funContactThemeColor
    sureButton.backgroundColor = .funContactThemeColor
  }

  override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.textColor = NEKitContactConfig.shared.ui.contactProperties.indexTitleColor ?? .ne_greyText
    sectionView.line.isHidden = true
    sectionView.titleLabel.text = viewModel.contacts[section].initial
    return sectionView
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let contactInfo = selectArray[indexPath.row]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(FunContactUnCheckCell.self))",
      for: indexPath
    ) as? FunContactUnCheckCell
    cell?.configure(contactInfo)
    return cell ?? UICollectionViewCell()
  }
}
