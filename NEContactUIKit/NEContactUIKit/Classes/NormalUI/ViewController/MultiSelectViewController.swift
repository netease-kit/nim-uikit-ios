// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 转发 - 选择页面 - 协同版
@objcMembers
open class MultiSelectViewController: NEBaseMultiSelectViewController {
  override init(filterUsers: Set<String>? = nil) {
    super.init(filterUsers: filterUsers)

    searchTextField.backgroundColor = .searchTextFeildBackColor

    sureButton.contentHorizontalAlignment = .right
    sureButton.setTitleColor(.disableButtonTitleColor, for: .disabled)

    recentTableView.rowHeight = 56
    recentTableView.register(SelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    friendTableView.rowHeight = 56
    friendTableView.register(SelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    teamTableView.rowHeight = 56
    teamTableView.register(SelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    selectedCollectionView.register(SelectedCell.self, forCellWithReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedCell.self))")

    recentCollectionView.register(RecentSelectCell.self, forCellWithReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedCell.self))")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 获取已选视图控制器-协同版
  /// - Parameter selectedArray: 已选列表
  /// - Returns: 已选页面的视图控制器
  override open func getMultiSelectedViewController(_ selectedArray: [MultiSelectModel]) -> NEBaseMultiSelectedViewController {
    MultiSelectedViewController(selectedArray: selectedArray)
  }

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == currentTableView {
      let info = viewModel.sessions[indexPath.row]
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))",
        for: indexPath
      ) as! SelectCell
      cell.showSelect(isMultiSelect)
      cell.setModel(info)
      cell.searchText = searchText
      return cell
    }

    return UITableViewCell()
  }
}
