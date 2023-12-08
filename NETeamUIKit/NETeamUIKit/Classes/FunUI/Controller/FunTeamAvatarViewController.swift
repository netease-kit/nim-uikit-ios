// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NIMSDK
import UIKit

@objcMembers
open class FunTeamAvatarViewController: NEBaseTeamAvatarViewController {
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    iconUrls = TeamRouter.iconUrlsFun
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func setupUI() {
    super.setupUI()
    headerView.layer.cornerRadius = 6.4

    navigationController?.navigationBar.backgroundColor = .white
    addRightAction(localizable("save"), #selector(savePhoto), self, .funTeamThemeColor)
    navigationView.backgroundColor = .white
    navigationView.moreButton.setTitleColor(.funTeamThemeColor, for: .normal)

    view.backgroundColor = .funTeamBackgroundColor

    NSLayoutConstraint.activate([
      headerBack.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      headerBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      headerBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      headerBack.heightAnchor.constraint(equalToConstant: 128.0),
    ])

    NSLayoutConstraint.activate([
      photoImage.centerXAnchor.constraint(equalTo: headerView.rightAnchor),
      photoImage.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      defaultHeaderBack.leftAnchor.constraint(equalTo: headerBack.leftAnchor),
      defaultHeaderBack.rightAnchor.constraint(equalTo: headerBack.rightAnchor),
      defaultHeaderBack.topAnchor.constraint(
        equalTo: headerBack.bottomAnchor,
        constant: 8.0
      ),
      defaultHeaderBack.heightAnchor.constraint(equalToConstant: 124.0),
    ])

    NSLayoutConstraint.activate([
      tag.leftAnchor.constraint(equalTo: defaultHeaderBack.leftAnchor, constant: 16.0),
      tag.topAnchor.constraint(equalTo: defaultHeaderBack.topAnchor, constant: 16.0),
      tag.heightAnchor.constraint(equalToConstant: 18),
    ])

    iconCollection.register(
      FunTeamDefaultIconCell.self,
      forCellWithReuseIdentifier: "\(FunTeamDefaultIconCell.self)"
    )
    NSLayoutConstraint.activate([
      iconCollection.topAnchor.constraint(equalTo: tag.bottomAnchor, constant: 0),
      iconCollection.leftAnchor.constraint(
        equalTo: defaultHeaderBack.leftAnchor,
        constant: 16
      ),
      iconCollection.rightAnchor.constraint(
        equalTo: defaultHeaderBack.rightAnchor,
        constant: -16
      ),
      iconCollection.heightAnchor.constraint(equalToConstant: 90.0),
    ])
  }

  override open func uploadPhoto() {
    if changePermission() {
      showCustomBottomAlert(self)
    }
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunTeamDefaultIconCell.self)",
      for: indexPath
    ) as? FunTeamDefaultIconCell {
      cell.iconImage.image = coreLoader.loadImage("fun_icon_\(indexPath.row)")

      return cell
    }
    return UICollectionViewCell()
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    let space = (NEConstant.screenWidth - 312.0) / 4.0
    if indexPath.row == 0 {
      return CGSize(width: 56, height: 56)
    }
    return CGSize(width: 56.0 + space, height: 56)
  }
}
