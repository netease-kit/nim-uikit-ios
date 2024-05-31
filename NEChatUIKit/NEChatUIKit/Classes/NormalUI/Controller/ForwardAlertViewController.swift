
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class ForwardSessionCell: NEBaseForwardSessionCell {
  override func setupUI() {
    super.setupUI()
    sessionHeaderView.layer.cornerRadius = 16
  }
}

@objcMembers
open class ForwardAlertViewController: NEBaseForwardAlertViewController {
  override open func setupUI() {
    super.setupUI()
    oneSessionHeadView.layer.cornerRadius = 16.0
    sessionCollectionView.register(
      ForwardSessionCell.self,
      forCellWithReuseIdentifier: "\(ForwardSessionCell.self)"
    )
  }

  override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(ForwardSessionCell.self)",
      for: indexPath
    ) as? ForwardSessionCell {
      return setCellModel(cell: cell, indexPath: indexPath)
    }
    return UICollectionViewCell()
  }
}
