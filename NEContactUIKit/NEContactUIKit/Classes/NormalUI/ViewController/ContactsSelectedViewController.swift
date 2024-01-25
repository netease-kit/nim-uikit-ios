// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class ContactsSelectedViewController: NEBaseContactsSelectedViewController {
  override init(filterUsers: Set<String>? = nil) {
    super.init(filterUsers: filterUsers)
    customCells = [ContactCellType.ContactPerson.rawValue: ContactSelectedCell.self]
    view.backgroundColor = .ne_backcolor
    navigationView.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()

    collection.register(
      ContactUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(ContactUnCheckCell.self))"
    )
    tableView.rowHeight = 52
  }

  override open func setupNavRightItem() {
    super.setupNavRightItem()
    navigationView.moreButton.backgroundColor = .white
    navigationView.moreButton.setTitleColor(UIColor(hexString: "337EFF"), for: .normal)
    sureBtn.backgroundColor = .white
    sureBtn.setTitleColor(UIColor(hexString: "337EFF"), for: .normal)
  }

  override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let sectionView: ContactSectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(NSStringFromClass(ContactSectionView.self))"
      ) as! ContactSectionView
    sectionView.titleLabel.text = viewModel.contacts[section].initial
    return sectionView
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let contactInfo = selectArray[indexPath.row]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(ContactUnCheckCell.self))",
      for: indexPath
    ) as? ContactUnCheckCell
    cell?.configure(contactInfo)
    return cell ?? UICollectionViewCell()
  }
}
