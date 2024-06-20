
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

public protocol TopMessageViewDelegate: AnyObject {
  func didClickCloseButton()
  func didTapTopMessageView()
}

@objcMembers
open class TopMessageView: UIView {
  public weak var delegate: TopMessageViewDelegate?
  var topContentLabelLeftAnchor: NSLayoutConstraint? // 顶部文案左侧约束
  var content: String?

  /// 置顶 icon
  public lazy var topImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  /// 缩略图
  public lazy var thumbImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false

    imageView.addSubview(playIcon)
    NSLayoutConstraint.activate([
      playIcon.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      playIcon.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
      playIcon.widthAnchor.constraint(equalToConstant: 16),
      playIcon.heightAnchor.constraint(equalToConstant: 16),
    ])

    return imageView
  }()

  /// 缩略图播放图片
  public lazy var playIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = NECommonUIKit.coreLoader.loadImage("video_play")
    return imageView
  }()

  /// 置顶文案
  public lazy var topContentLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.topContent"
    return label
  }()

  /// 关闭按钮
  public lazy var closeButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setImage(UIImage.ne_imageNamed(name: "top_close"), for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityIdentifier = "id.topClose"
    button.addTarget(self, action: #selector(didClickCloseButton), for: .touchUpInside)

    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    layer.cornerRadius = 8

    addSubview(topImageView)
    NSLayoutConstraint.activate([
      topImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: chat_content_margin),
      topImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      topImageView.widthAnchor.constraint(equalToConstant: 18),
      topImageView.heightAnchor.constraint(equalToConstant: 18),
    ])

    addSubview(thumbImageView)
    NSLayoutConstraint.activate([
      thumbImageView.leftAnchor.constraint(equalTo: topImageView.rightAnchor, constant: chat_content_margin),
      thumbImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      thumbImageView.widthAnchor.constraint(equalToConstant: 28),
      thumbImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    addSubview(topContentLabel)
    topContentLabelLeftAnchor = topContentLabel.leftAnchor.constraint(equalTo: topImageView.rightAnchor, constant: chat_content_margin)
    topContentLabelLeftAnchor?.isActive = true
    NSLayoutConstraint.activate([
      topContentLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -44),
      topContentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -chat_content_margin),
      closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 30),
      closeButton.heightAnchor.constraint(equalToConstant: 30),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(tapTopMessageView))
    addGestureRecognizer(tap)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 设置置顶文案
  /// - Parameter name: 置顶消息发送者昵称
  /// - Parameter content: 置顶消息内容文案
  /// - Parameter url: 置顶消息 图片缩略图/视频首帧 地址
  /// - Parameter isVideo: 置顶消息是否是视频消息
  /// - Parameter hideClose: 是否隐藏移除置顶按钮
  public func setTopContent(name: String?, content: String?, url: String?, isVideo: Bool, hideClose: Bool) {
    self.content = content
    updateTopName(name: name)

    if let url = url {
      thumbImageView.isHidden = false
      thumbImageView.sd_setImage(with: URL(string: url), placeholderImage: nil)
      playIcon.isHidden = !isVideo
      topContentLabelLeftAnchor?.constant = chat_content_margin + 32
    } else {
      thumbImageView.isHidden = true
      topContentLabelLeftAnchor?.constant = chat_content_margin
    }

    closeButton.isHidden = hideClose
  }

  /// 设置（更新）置顶消息发送者昵称
  /// - Parameter content: 发送者昵称
  public func updateTopName(name: String?) {
    var text = ""

    if let fullName = name, !fullName.isEmpty {
      let cutName = NEFriendUserCache.getCutName(fullName)
      text = cutName + "："
    }

    let attributedString = NSMutableAttributedString(string: text)

    if let content = content {
      let emojiAttr = NEEmotionTool.getAttWithStr(str: content, font: topContentLabel.font)
      attributedString.append(emojiAttr)
    }

    topContentLabel.attributedText = attributedString
  }

  /// 点击关闭按钮
  func didClickCloseButton() {
    delegate?.didClickCloseButton()
  }

  /// 点击置顶视图
  func tapTopMessageView() {
    delegate?.didTapTopMessageView()
  }
}
