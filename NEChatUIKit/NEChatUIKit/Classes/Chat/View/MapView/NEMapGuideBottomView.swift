// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol NEMapGuideBottomViewDelegate: NSObjectProtocol {
  func didClickGuide()
}

@objcMembers
open class NEMapGuideBottomView: UIView {
  public weak var delegate: NEMapGuideBottomViewDelegate?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupSubviews() {
    backgroundColor = .white
    addSubview(guideBtn)
    addSubview(title)
    addSubview(subtitle)

    NSLayoutConstraint.activate([
      guideBtn.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      guideBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      guideBtn.widthAnchor.constraint(equalToConstant: 40),
      guideBtn.heightAnchor.constraint(equalToConstant: 40),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: rightAnchor, constant: -52),
      title.topAnchor.constraint(equalTo: topAnchor, constant: 16),
    ])

    NSLayoutConstraint.activate([
      subtitle.leftAnchor.constraint(equalTo: title.leftAnchor),
      subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
      subtitle.rightAnchor.constraint(equalTo: rightAnchor, constant: -52),
    ])
  }

  lazy var guideBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "chat_map_path"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "chat_map_path"), for: .highlighted)
    button.addTarget(self, action: #selector(guideBtnClick), for: .touchUpInside)
    return button
  }()

  lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16)
    label.textColor = UIColor.ne_darkText
    label.text = ""
    return label
  }()

  lazy var subtitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor.ne_emptyTitleColor
    label.text = ""

    return label
  }()

  func guideBtnClick() {
    if let delegate = delegate {
      delegate.didClickGuide()
    }
  }
}
