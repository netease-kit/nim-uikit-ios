//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunContactSelectedPageController: NEBaseContactSelectedPageController {
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    pagingViewControllerTopAnchor?.constant = topConstant
  }

  override open func getContentControllers(_ filterUsers: Set<String>? = nil) -> [NEBaseFusionContactSelectedController]? {
    if childrenControllers.count == 0 {
      let userSelectController = FunFusionContactSelectedController(filterIds: filterUsers, type: .FusionContactTypeUser)
      userSelectController.delegate = self
      userSelectController.limit = limit
      let aiUserSelectController = FunFusionContactSelectedController(filterIds: filterUsers, type: .FusionContactTypeAIUser)
      aiUserSelectController.delegate = self
      aiUserSelectController.limit = limit
      childrenControllers.append(userSelectController)
      childrenControllers.append(aiUserSelectController)
    }
    return childrenControllers
  }

  override open func setupPageContent() {
    collectionBackViewTopMargin = 12
    super.setupPageContent()
    let pagingViewController = NEPagingViewController(viewControllers: contentControllers)
    addChild(pagingViewController)
    view.addSubview(pagingViewController.view)
    pagingViewController.view.backgroundColor = .white
    pagingViewControllerTopAnchor = pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    pagingViewControllerTopAnchor?.isActive = true
    pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
      pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    pagingViewController.selectedTextColor = .funContactGreenDividerLineColor
    pagingViewController.textColor = .funContactNormalTextColor
    pagingViewController.indicatorColor = .funContactGreenDividerLineColor
    pagingViewController.indicatorOptions = NEPagingIndicatorOptions.visible(
      height: 2,
      zIndex: Int.max,
      spacing: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    )
    pagingViewController.borderOptions = NEPagingBorderOptions.visible(height: 1, zIndex: Int.max, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    pagingViewController.didMove(toParent: self)
    selectCollectionView.register(FunFusionContactUnCheckCell.self, forCellWithReuseIdentifier: "\(NSStringFromClass(FunFusionContactUnCheckCell.self))")
  }

  override open func setupNavSureItem() {
    super.setupNavSureItem()
    navigationView.setBackButtonTitle(localizable("close"))
    navigationView.backButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.moreButton.backgroundColor = .funContactThemeColor
    selectedSureButton.backgroundColor = .funContactThemeColor
    view.backgroundColor = .ne_backcolor
    navigationView.backgroundColor = .ne_backcolor
    selectCollectionBackView.backgroundColor = .white
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let contactInfo = selectArray[indexPath.row]
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(NSStringFromClass(FunFusionContactUnCheckCell.self))",
      for: indexPath
    ) as? FunFusionContactUnCheckCell
    cell?.configure(contactInfo)
    return cell ?? UICollectionViewCell()
  }
}
