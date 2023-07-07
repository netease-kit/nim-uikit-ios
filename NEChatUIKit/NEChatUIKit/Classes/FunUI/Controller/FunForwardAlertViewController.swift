
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NECommonUIKit

@objcMembers
public class FunForwardUserCell: NEBaseForwardUserCell {
  override func setupUI() {
    super.setupUI()
    userHeader.layer.cornerRadius = 4
  }
}

@objcMembers
public class FunForwardAlertViewController: NEBaseForwardAlertViewController {
  override public func setupUI() {
    super.setupUI()
    tip.font = .systemFont(ofSize: 16, weight: .semibold)
    oneUserHead.layer.cornerRadius = 4.0
    sureBtn.setTitleColor(.funChatThemeColor, for: .normal)
    userCollection.register(
      FunForwardUserCell.self,
      forCellWithReuseIdentifier: "\(FunForwardUserCell.self)"
    )
  }

  override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunForwardUserCell.self)",
      for: indexPath
    ) as? FunForwardUserCell {
      return setCellModel(cell: cell, indexPath: indexPath)
    }
    return UICollectionViewCell()
  }
}
