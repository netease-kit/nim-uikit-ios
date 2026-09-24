// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol NEConversationGroupBarDelegate: NSObjectProtocol {
  func conversationGroupBar(_ bar: NEConversationGroupBar, didSelect group: NEConversationGroupModel)
  func conversationGroupBarDidTapManager(_ bar: NEConversationGroupBar)
}

final class NEConversationGroupBar: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  weak var delegate: NEConversationGroupBarDelegate?
  private var groups = [NEConversationGroupModel]()
  private var selectedId: String?
  private var style = NEConversationGroupUIStyle.normal

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 6
    layout.minimumLineSpacing = 6
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.showsHorizontalScrollIndicator = false
    view.dataSource = self
    view.delegate = self
    view.register(GroupCell.self, forCellWithReuseIdentifier: "GroupCell")
    return view
  }()

  private lazy var managerButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(managerAction), for: .touchUpInside)
    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = backgroundColor(for: style)
    addSubview(collectionView)
    addSubview(managerButton)
    NSLayoutConstraint.activate([
      collectionView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
      collectionView.rightAnchor.constraint(equalTo: managerButton.leftAnchor, constant: -8),
      managerButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      managerButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      managerButton.widthAnchor.constraint(equalToConstant: 32),
      managerButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configure(groups: [NEConversationGroupModel], selectedId: String?, style: NEConversationGroupUIStyle = .normal) {
    self.groups = groups
    self.selectedId = selectedId
    self.style = style
    backgroundColor = backgroundColor(for: style)
    collectionView.backgroundColor = backgroundColor(for: style)
    managerButton.setImage(UIImage.ne_imageNamed(name: style.managerImageName), for: .normal)
    collectionView.reloadData()
  }

  private func backgroundColor(for style: NEConversationGroupUIStyle) -> UIColor {
    style.contentBackgroundColor
  }

  @objc private func managerAction() {
    delegate?.conversationGroupBarDidTapManager(self)
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    groups.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
    let group = groups[indexPath.item]
    cell.configure(group.displayName, selected: group.groupId == selectedId, style: style)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate?.conversationGroupBar(self, didSelect: groups[indexPath.item])
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let text = groups[indexPath.item].displayName
    let width = ceil((text as NSString).size(
      withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .medium)]
    ).width)
    return CGSize(width: max(width + 16, 44), height: 36)
  }
}

private final class GroupCell: UICollectionViewCell {
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 15, weight: .medium)
    label.textAlignment = .center
    label.lineBreakMode = .byClipping
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configure(_ title: String, selected: Bool, style: NEConversationGroupUIStyle) {
    titleLabel.text = title
    titleLabel.textColor = selected ? style.primaryColor : style.titleTextColor
    contentView.backgroundColor = selected ? style.selectedBackgroundColor : .clear
    contentView.layer.cornerRadius = 4
  }
}
