
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class FunForwardSessionCell: NEBaseForwardSessionCell {
  override func setupUI() {
    super.setupUI()
    sessionHeaderView.layer.cornerRadius = 4
  }
}

@objcMembers
open class FunForwardAlertViewController: NEBaseForwardAlertViewController {
  override open func setupUI() {
    super.setupUI()
    tipLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    oneSessionHeadView.layer.cornerRadius = 4.0
    sureButton.setTitleColor(.funChatThemeColor, for: .normal)
    sessionCollectionView.register(
      FunForwardSessionCell.self,
      forCellWithReuseIdentifier: "\(FunForwardSessionCell.self)"
    )
  }

  override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunForwardSessionCell.self)",
      for: indexPath
    ) as? FunForwardSessionCell {
      return setCellModel(cell: cell, indexPath: indexPath)
    }
    return UICollectionViewCell()
  }
}
