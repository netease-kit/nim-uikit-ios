//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class ValidationPageController: NEBaseValidationPageController {
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    pagingViewControllerTopAnchor?.constant = topConstant
  }

  override open func initNav() {
    super.initNav()
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(toSetting)
    )
    clearItem.tintColor = .ne_darkText
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    navigationView.moreButton.titleLabel?.font = .systemFont(ofSize: 16)
  }

  override open func getContentControllers() {
    if contentControllers.count == 0 {
      let addApplicationViewController = AddApplicationViewController()
      contentControllers.append(addApplicationViewController)

      if IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
        let teamJoinActionViewController = TeamJoinActionViewController()
        contentControllers.append(teamJoinActionViewController)
      }
    }
  }

  override open func setupPageContent() {
    super.setupPageContent()
    pagingViewController?.selectedTextColor = .contactBlueDividerLineColor
    pagingViewController?.textColor = .contactNormalTextColor
    pagingViewController?.indicatorColor = .contactBlueDividerLineColor
  }
}
