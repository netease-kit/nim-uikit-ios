
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import SDWebImage
import UIKit

@objcMembers
open class NEUserHeaderView: UIImageView {
  private var avatarRequestIdentifier = UUID()
  private var didSetupUI = false
  private var avatarUID: String?
  private var avatarURL: String?
  private var avatarLoading = false

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
    setupUI()
  }

  func setupUI() {
    guard !didSetupUI else { return }
    didSetupUI = true
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
    if !NEAdaptiveDeviceGate.isFoldableDevice {
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

      return
    }
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.configHeadData(headUrl: headUrl, name: name, uid: uid)
      }
      return
    }
    let avatar = headUrl.flatMap { $0.isEmpty ? nil : $0 }
    let sameAvatar = avatarUID == uid && avatarURL == avatar
    if sameAvatar && avatar != nil && (image != nil || avatarLoading) {
      // A read-state refresh must not clear a loaded image or restart its request.
      setTitle("")
      backgroundColor = .clear
      return
    }
    let requestIdentifier = UUID()
    avatarRequestIdentifier = requestIdentifier
    avatarUID = uid
    avatarURL = avatar
    avatarLoading = false
    sd_cancelCurrentImageLoad()
    image = nil
    if let avatar {
      setTitle("")
      backgroundColor = .clear
      avatarLoading = true
      // Auto assignment would run before a completed-block identity check. Only the
      // current binding may write the image, including callbacks queued before cancel.
      sd_setImage(with: URL(string: avatar), placeholderImage: nil,
                  options: [.avoidAutoSetImage]) { [weak self] image, _, _, _ in
        guard let self, self.avatarRequestIdentifier == requestIdentifier else { return }
        self.avatarLoading = false
        self.image = image
      }
    } else {
      setTitle(name.isEmpty ? uid : name)
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
      self.avatarUID = nil
      self.avatarURL = nil
      self.avatarLoading = false
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
