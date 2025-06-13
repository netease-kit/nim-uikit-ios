
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

public
protocol AIChatTableViewCellDelegate: NSObjectProtocol {
  func didClickEditButton(_ text: String?)
}

@objcMembers
open class AIChatTableViewCell: UITableViewCell {
  public weak var delegate: AIChatTableViewCellDelegate?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonUI()
  }

  public lazy var backView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.layer.cornerRadius = 12

    view.addSubview(tagLabel)
    NSLayoutConstraint.activate([
      tagLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_content_margin),
      tagLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      tagLabel.widthAnchor.constraint(equalToConstant: 60),
      tagLabel.heightAnchor.constraint(equalToConstant: 24),
    ])

    view.addSubview(editButton)
    NSLayoutConstraint.activate([
      editButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      editButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      editButton.widthAnchor.constraint(equalToConstant: 24),
      editButton.heightAnchor.constraint(equalToConstant: 24),
    ])

    view.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: tagLabel.rightAnchor, constant: 10),
      contentLabel.rightAnchor.constraint(equalTo: editButton.leftAnchor, constant: -chat_content_margin),
      contentLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      contentLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -chat_content_margin),
    ])
    return view
  }()

  public lazy var tagLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 12)
    label.textAlignment = .center
    label.layer.cornerRadius = 6
    label.layer.masksToBounds = true
    return label
  }()

  public lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 14)
    label.numberOfLines = 2
    return label
  }()

  public lazy var editButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "ai_edit"), for: .normal)
    button.addTarget(self, action: #selector(editButtonAction), for: .touchUpInside)
    return button
  }()

  open func commonUI() {
    contentView.addSubview(backView)
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      backView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
    ])
  }

  open func editButtonAction() {
    delegate?.didClickEditButton(contentLabel.text)
  }

  open func setModel(_ model: AIChatCellModel) {
    tagLabel.text = model.tagTitle
    tagLabel.textColor = model.tagTitleColor
    tagLabel.backgroundColor = model.tagTitleBackgroundColor
    contentLabel.text = model.contentTitle
  }
}
