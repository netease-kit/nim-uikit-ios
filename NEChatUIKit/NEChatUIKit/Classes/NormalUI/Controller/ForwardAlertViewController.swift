
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

@objcMembers
open class ForwardUserCell: NEBaseForwardUserCell {
  override func setupUI() {
    super.setupUI()
    userHeader.layer.cornerRadius = 16
  }
}

@objcMembers
open class ForwardAlertViewController: NEBaseForwardAlertViewController {
  override open func setupUI() {
    super.setupUI()
    oneUserHead.layer.cornerRadius = 16.0
    userCollection.register(
      ForwardUserCell.self,
      forCellWithReuseIdentifier: "\(ForwardUserCell.self)"
    )
  }

  override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(ForwardUserCell.self)",
      for: indexPath
    ) as? ForwardUserCell {
      return setCellModel(cell: cell, indexPath: indexPath)
    }
    return UICollectionViewCell()
  }
}
