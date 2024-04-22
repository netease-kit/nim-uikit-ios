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
    super.init(coder: coder)
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
      headerBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight),
      headerBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      headerBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
      headerBackView.heightAnchor.constraint(equalToConstant: 128.0),
    ])

    NSLayoutConstraint.activate([
      photoImageView.rightAnchor.constraint(equalTo: headerView.rightAnchor),
      photoImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      defaultHeaderBackView.leftAnchor.constraint(equalTo: headerBackView.leftAnchor),
      defaultHeaderBackView.rightAnchor.constraint(equalTo: headerBackView.rightAnchor),
      defaultHeaderBackView.topAnchor.constraint(
        equalTo: headerBackView.bottomAnchor,
        constant: 8.0
      ),
      defaultHeaderBackView.heightAnchor.constraint(equalToConstant: 124.0),
    ])

    NSLayoutConstraint.activate([
      tagLabel.leftAnchor.constraint(equalTo: defaultHeaderBackView.leftAnchor, constant: 16.0),
      tagLabel.topAnchor.constraint(equalTo: defaultHeaderBackView.topAnchor, constant: 16.0),
      tagLabel.heightAnchor.constraint(equalToConstant: 18),
    ])

    iconsCollectionView.register(
      FunTeamDefaultIconCell.self,
      forCellWithReuseIdentifier: "\(FunTeamDefaultIconCell.self)"
    )
    NSLayoutConstraint.activate([
      iconsCollectionView.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 0),
      iconsCollectionView.leftAnchor.constraint(
        equalTo: defaultHeaderBackView.leftAnchor,
        constant: 16
      ),
      iconsCollectionView.rightAnchor.constraint(
        equalTo: defaultHeaderBackView.rightAnchor,
        constant: -16
      ),
      iconsCollectionView.heightAnchor.constraint(equalToConstant: 90.0),
    ])
  }

  override open func uploadPhoto() {
    if getChangePermission() {
      showCustomBottomAlert(self)
    }
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(FunTeamDefaultIconCell.self)",
      for: indexPath
    ) as? FunTeamDefaultIconCell {
      cell.iconImageView.image = coreLoader.loadImage("fun_icon_\(indexPath.row)")
      cell.iconImageView.accessibilityIdentifier = "id.default\(indexPath.row + 1)"

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
