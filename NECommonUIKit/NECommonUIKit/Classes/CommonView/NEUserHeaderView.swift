
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEUserHeaderView: UIImageView {
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.accessibilityIdentifier = "id.noAvatar"
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    accessibilityIdentifier = "id.avatar"
    contentMode = .scaleAspectFill
    isUserInteractionEnabled = true
    clipsToBounds = false
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])
    backgroundColor = .clear
  }

  open func configHeadData(headUrl: String?, name: String, uid: String) {
    if let avatar = headUrl, !avatar.isEmpty {
      setTitle("")
      sd_setImage(with: URL(string: avatar), completed: nil)
      backgroundColor = .clear
    } else {
      setTitle(name.count > 0 ? name : uid)
      sd_setImage(with: nil, completed: nil)
      backgroundColor = UIColor.colorWithString(string: uid)
    }
  }

  open func setTitle(_ name: String) {
    titleLabel.text = name
      .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
  }
}
