
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

    headerBack.layer.cornerRadius = 8.0

    NSLayoutConstraint.activate([
      headerBack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.0 + NEConstant.navigationAndStatusHeight),
      headerBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      headerBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      headerBack.heightAnchor.constraint(equalToConstant: 128.0),
    ])

    NSLayoutConstraint.activate([
      photoImage.rightAnchor.constraint(equalTo: headerView.rightAnchor),
      photoImage.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
    ])

    let gesture = UITapGestureRecognizer()
    headerView.addGestureRecognizer(gesture)
    gesture.addTarget(self, action: #selector(uploadPhoto))

    defaultHeaderBack.layer.cornerRadius = 8.0
    NSLayoutConstraint.activate([
      defaultHeaderBack.leftAnchor.constraint(equalTo: headerBack.leftAnchor),
      defaultHeaderBack.rightAnchor.constraint(equalTo: headerBack.rightAnchor),
      defaultHeaderBack.topAnchor.constraint(
        equalTo: headerBack.bottomAnchor,
        constant: 12.0
      ),
      defaultHeaderBack.heightAnchor.constraint(equalToConstant: 114.0),
    ])

    NSLayoutConstraint.activate([
      tag.leftAnchor.constraint(equalTo: defaultHeaderBack.leftAnchor, constant: 16.0),
      tag.topAnchor.constraint(equalTo: defaultHeaderBack.topAnchor, constant: 15.0),
    ])

    iconCollection.register(
      TeamDefaultIconCell.self,
      forCellWithReuseIdentifier: "\(TeamDefaultIconCell.self)"
    )
    NSLayoutConstraint.activate([
      iconCollection.topAnchor.constraint(equalTo: tag.bottomAnchor, constant: 16.0),
      iconCollection.leftAnchor.constraint(
        equalTo: defaultHeaderBack.leftAnchor,
        constant: 18
      ),
      iconCollection.rightAnchor.constraint(
        equalTo: defaultHeaderBack.rightAnchor,
        constant: -18.0
      ),
      iconCollection.heightAnchor.constraint(equalToConstant: 48.0),
    ])
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(TeamDefaultIconCell.self)",
      for: indexPath
    ) as? TeamDefaultIconCell {
      cell.iconImage.image = coreLoader.loadImage("icon_\(indexPath.row)")
      cell.iconImage.accessibilityIdentifier = "id.default\(indexPath.row + 1)"
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
