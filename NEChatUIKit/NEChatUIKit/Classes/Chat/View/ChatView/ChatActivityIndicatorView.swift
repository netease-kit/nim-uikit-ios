
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public enum ChatSendMessageStatus: Int {
  case successed = 0
  case sending
  case failed
}

@objcMembers
open class ChatActivityIndicatorView: UIView {
  public var messageStatus: ChatSendMessageStatus? {
    didSet {
      failButton.isHidden = true
      activityView.isHidden = true
      activityView.stopAnimating()

      switch messageStatus {
      case .sending:
        isHidden = false
        activityView.isHidden = false
        failButton.isHidden = true
        activityView.startAnimating()
      case .failed:
        isHidden = false
        activityView.isHidden = true
        failButton.isHidden = false
      case .successed:
        isHidden = true
      default:
        print("default")
      }
    }
  }

  public lazy var failButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentMode = .scaleAspectFit
    button.setImage(UIImage.ne_imageNamed(name: "sendMessage_failed"), for: .normal)
    button.accessibilityIdentifier = "id.sendMessageFailed"
    return button
  }()

  private lazy var activityView: UIActivityIndicatorView = {
    let activityView = UIActivityIndicatorView()
    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.color = .gray
    return activityView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    backgroundColor = .clear
    addSubview(failButton)
    addSubview(activityView)
    NSLayoutConstraint.activate([
      failButton.topAnchor.constraint(equalTo: topAnchor),
      failButton.leftAnchor.constraint(equalTo: leftAnchor),
      failButton.bottomAnchor.constraint(equalTo: bottomAnchor),
      failButton.rightAnchor.constraint(equalTo: rightAnchor),
    ])

    NSLayoutConstraint.activate([
      activityView.topAnchor.constraint(equalTo: topAnchor),
      activityView.leftAnchor.constraint(equalTo: leftAnchor),
      activityView.bottomAnchor.constraint(equalTo: bottomAnchor),
      activityView.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }
}
