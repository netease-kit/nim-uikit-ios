// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

/// 转发 - 选择页面 - 通用版
@objcMembers
open class FunMultiSelectViewController: NEBaseMultiSelectViewController {
  override init(filterUsers: Set<String>? = nil) {
    super.init(filterUsers: filterUsers)
    themeColor = .funContactThemeColor
    titleText = localizable("select")
    sureButtonText = commonLocalizable("complete")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .ne_backcolor

    sureButton.setTitleColor(.white, for: .normal)
    sureButton.backgroundColor = .funContactThemeDisableColor
    sureButton.contentHorizontalAlignment = .center

    searchTextField.font = UIFont.systemFont(ofSize: 16)
    searchTextField.backgroundColor = .white
    searchTextField.addTarget(self, action: #selector(searchTextFieldBeginEdit), for: .editingDidBegin)
    setSearchTextFieldLeftView()

    recentTableView.rowHeight = 64
    recentTableView.register(FunSelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    friendTableView.rowHeight = 64
    friendTableView.register(FunSelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    teamTableView.rowHeight = 64
    teamTableView.register(FunSelectCell.self, forCellReuseIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))")

    selectedCollectionView.register(FunSelectedCell.self, forCellWithReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedCell.self))")

    recentLabel.textColor = .black
    recentCollectionView.register(FunRecentSelectCell.self, forCellWithReuseIdentifier: "\(NSStringFromClass(NEBaseSelectedCell.self))")

    emptyView.setEmptyImage(name: "fun_user_empty")
  }

  /// 设置搜索框 leftView
  func setSearchTextFieldLeftView() {
    if !searchTextField.isFirstResponder, searchTextField.text?.isEmpty == true {
      let leftImageView = UIImageView(image: UIImage.ne_imageNamed(name: "funSearch"))
      searchTextField.leftView = leftImageView
      searchTextField.leftViewRectX = (NEConstant.screenWidth) / 2 - 50
    } else {
      searchTextField.leftView = nil
      searchTextField.leftViewRectX = nil
    }
    searchTextField.layoutIfNeeded()
  }

  /// 监听搜索框开始编辑
  func searchTextFieldBeginEdit() {
    setSearchTextFieldLeftView()
  }

  /// 获取已选视图控制器 - 通用版
  /// - Parameter selectedArray: 已选列表
  /// - Returns: 已选页面的视图控制器
  override open func getMultiSelectedViewController(_ selectedArray: [MultiSelectModel]) -> NEBaseMultiSelectedViewController {
    FunMultiSelectedViewController(selectedArray: selectedArray)
  }

  // MARK: - UITableViewDataSource

  override open func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == currentTableView {
      let info = viewModel.sessions[indexPath.row]
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(NSStringFromClass(NEBaseSelectCell.self))",
        for: indexPath
      ) as! FunSelectCell
      cell.showSelect(isMultiSelect)
      cell.setModel(info)
      cell.searchText = searchText
      return cell
    }

    return UITableViewCell()
  }

  /// 重写 tableView 点击事件，更新搜索框 leftView 位置
  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    super.tableView(tableView, didSelectRowAt: indexPath)
    setSearchTextFieldLeftView()
  }

  // MARK: - UIScrollViewDelegate

  /// 重写 tableView 开始滚动事件，更新搜索框 leftView 位置
  override public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    super.scrollViewWillBeginDragging(scrollView)
    setSearchTextFieldLeftView()
  }

  // MARK: Collection View DataSource And Delegateoverride

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == recentCollectionView {
      return CGSize(width: 72, height: 84)
    } else if collectionView == selectedCollectionView {
      return CGSize(width: 41, height: selectedContentViewHeight)
    } else {
      return CGSize.zero
    }
  }

  /// 重写【完成】按钮设置
  override func refreshSelectCount() {
    super.refreshSelectCount()
    sureButton.backgroundColor = selectedArray.count > 0 ? .funContactThemeColor : .funContactThemeDisableColor
  }
}
