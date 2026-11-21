
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
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
    navigationView.setBackButtonTitle(commonLocalizable("cancel"))
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
      cell.iconImageView.image = teamUIKitLoader.loadImage("icon_\(indexPath.row)")
      cell.iconImageView.accessibilityIdentifier = "id.default\(indexPath.row + 1)"
      return cell
    }
    return UICollectionViewCell()
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateCandidateIconSpacing()
  }

  /// 5 个候选头像两端对齐：固定 48pt，剩余宽度均分为 4 段间距。
  private func updateCandidateIconSpacing() {
    let width = iconsCollectionView.bounds.width
    guard width > 0,
          let layout = iconsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
    let itemWidth: CGFloat = 48
    let spacing = max(0, (width - itemWidth * 5) / 4)
    let target = CGSize(width: itemWidth, height: itemWidth)
    guard layout.itemSize != target || abs(layout.minimumLineSpacing - spacing) > 0.5 else { return }
    layout.itemSize = target
    layout.minimumLineSpacing = spacing
    layout.sectionInset = .zero
    layout.invalidateLayout()
  }

  override open func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    // 候选头像固定尺寸，间距由 layout 动态计算，保证 5 个候选在容器内两端对齐。
    return CGSize(width: 48, height: 48)
  }
}
