
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NIMSDK
import UIKit

@objcMembers
open class TeamAvatarViewController: NEBaseTeamAvatarViewController {
  override open func setupUI() {
    super.setupUI()
    headerView.layer.cornerRadius = 40

    addRightAction(localizable("save"), #selector(savePhoto), self)

    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationView.setBackButtonTitle(localizable("cancel"))
    navigationView.backButton.setTitleColor(.ne_greyText, for: .normal)
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor

    headerBackView.layer.cornerRadius = 8.0

    NSLayoutConstraint.activate([
      headerBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.0 + NEConstant.navigationAndStatusHeight),
      headerBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      headerBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      headerBackView.heightAnchor.constraint(equalToConstant: 128.0),
    ])

    NSLayoutConstraint.activate([
      photoImageView.rightAnchor.constraint(equalTo: headerView.rightAnchor),
      photoImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
    ])

    let gesture = UITapGestureRecognizer()
    headerView.addGestureRecognizer(gesture)
    gesture.addTarget(self, action: #selector(uploadPhoto))

    defaultHeaderBackView.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      defaultHeaderBackView.leftAnchor.constraint(equalTo: headerBackView.leftAnchor),
      defaultHeaderBackView.rightAnchor.constraint(equalTo: headerBackView.rightAnchor),
      defaultHeaderBackView.topAnchor.constraint(
        equalTo: headerBackView.bottomAnchor,
        constant: 12.0
      ),
      defaultHeaderBackView.heightAnchor.constraint(equalToConstant: 114.0),
    ])

    NSLayoutConstraint.activate([
      tagLabel.leftAnchor.constraint(equalTo: defaultHeaderBackView.leftAnchor, constant: 16.0),
      tagLabel.topAnchor.constraint(equalTo: defaultHeaderBackView.topAnchor, constant: 15.0),
    ])

    iconsCollectionView.register(
      TeamDefaultIconCell.self,
      forCellWithReuseIdentifier: "\(TeamDefaultIconCell.self)"
    )
    NSLayoutConstraint.activate([
      iconsCollectionView.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 16.0),
      iconsCollectionView.leftAnchor.constraint(
        equalTo: defaultHeaderBackView.leftAnchor,
        constant: 18
      ),
      iconsCollectionView.rightAnchor.constraint(
        equalTo: defaultHeaderBackView.rightAnchor,
        constant: -18.0
      ),
      iconsCollectionView.heightAnchor.constraint(equalToConstant: 48.0),
    ])
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(TeamDefaultIconCell.self)",
      for: indexPath
    ) as? TeamDefaultIconCell {
      cell.iconImageView.image = coreLoader.loadImage("icon_\(indexPath.row)")
      cell.iconImageView.accessibilityIdentifier = "id.default\(indexPath.row + 1)"
      return cell
    }
    return UICollectionViewCell()
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    let space = (NEConstant.screenWidth - 297.0) / 4.0
    if indexPath.row == 0 {
      return CGSize(width: 48, height: 48)
    }
    return CGSize(width: 48.0 + space, height: 48)
  }
}
