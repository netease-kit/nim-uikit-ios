// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit
import NIMSDK

@objcMembers
open class FunContactsSelectedViewController: NEBaseContactsSelectedViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    customCells = [ContactCellType.ContactPerson.rawValue: FunContactSelectedCell.self]
    view.backgroundColor = .funContactBackgroundColor
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()
    emptyView.setEmptyImage(name: "fun_user_empty")
    collectionBackView.backgroundColor = .white
    collection.register(
      FunContactUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(FunContactUnCheckCell.self))"
    )
    tableView.rowHeight = 64
  }

  override open func setupNavRightItem() {
    super.setupNavRightItem()
    customNavigationView.moreButton.backgroundColor = .funContactThemeColor
    sureBtn.backgroundColor = .funContactThemeColor
  }

  override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.textColor = NEKitContactConfig.shared.ui.indexTitleColor ?? .ne_greyText
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
