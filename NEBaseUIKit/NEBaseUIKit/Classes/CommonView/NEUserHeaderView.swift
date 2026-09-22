
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEUserHeaderView: UIImageView {
  private var avatarRequestIdentifier = UUID()

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
    let requestIdentifier = UUID()
    avatarRequestIdentifier = requestIdentifier
    if let avatar = headUrl, !avatar.isEmpty {
      setTitle("")
      DispatchQueue.main.async { [weak self] in
        guard let self, self.avatarRequestIdentifier == requestIdentifier else {
          return
        }
        self.sd_setImage(with: URL(string: avatar), completed: nil)
      }
      backgroundColor = .clear
    } else {
      setTitle(name.isEmpty ? uid : name)
      DispatchQueue.main.async { [weak self] in
        guard let self, self.avatarRequestIdentifier == requestIdentifier else {
          return
        }
        self.sd_setImage(with: nil, completed: nil)
      }
      backgroundColor = UIColor.colorWithString(string: uid)
    }
  }

  open func configStaticImage(_ image: UIImage?) {
    let requestIdentifier = UUID()
    avatarRequestIdentifier = requestIdentifier
    let applyImage = { [weak self] in
      guard let self, self.avatarRequestIdentifier == requestIdentifier else {
        return
      }
      self.sd_cancelCurrentImageLoad()
      self.setTitle("")
      self.image = image
      self.backgroundColor = .clear
    }
    if Thread.isMainThread {
      applyImage()
    } else {
      DispatchQueue.main.async(execute: applyImage)
    }
  }

  open func setTitle(_ name: String) {
    titleLabel.text = name
      .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
  }
}
