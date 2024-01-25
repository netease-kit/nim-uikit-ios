
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
      failBtn.isHidden = true
      activity.isHidden = true
      activity.stopAnimating()

      switch messageStatus {
      case .sending:
        self.isHidden = false
        activity.isHidden = false
        failBtn.isHidden = true
        activity.startAnimating()
      case .failed:
        self.isHidden = false
        activity.isHidden = true
        failBtn.isHidden = false
      case .successed:
        self.isHidden = true

      default:
        print("default")
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    backgroundColor = .clear
    addSubview(failBtn)
    addSubview(activity)
    NSLayoutConstraint.activate([
      failBtn.topAnchor.constraint(equalTo: topAnchor),
      failBtn.leftAnchor.constraint(equalTo: leftAnchor),
      failBtn.bottomAnchor.constraint(equalTo: bottomAnchor),
      failBtn.rightAnchor.constraint(equalTo: rightAnchor),
    ])

    NSLayoutConstraint.activate([
      activity.topAnchor.constraint(equalTo: topAnchor),
      activity.leftAnchor.constraint(equalTo: leftAnchor),
      activity.bottomAnchor.constraint(equalTo: bottomAnchor),
      activity.rightAnchor.constraint(equalTo: rightAnchor),
    ])
  }

  // MARK: lazy Method

  public lazy var failBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.imageView?.contentMode = .center
    button.setBackgroundImage(UIImage.ne_imageNamed(name: "sendMessage_failed"), for: .normal)
    button.accessibilityIdentifier = "id.sendMessageFailed"
    return button
  }()

  private lazy var activity: UIActivityIndicatorView = {
    let activity = UIActivityIndicatorView()
    activity.translatesAutoresizingMaskIntoConstraints = false
    activity.color = .gray
    return activity
  }()
}
