
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol BrowserToolsBarDelegate: NSObjectProtocol {
  func didCloseClick()
  func didSaveClick()
}

@objcMembers
open class BrowserToolsBar: UIView {
  public weak var delegate: BrowserToolsBarDelegate?

  public lazy var saveButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("save_btn"), for: .normal)
    return button
  }()

  public lazy var closeButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("close_btn"), for: .normal)
    return button
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    backgroundColor = .clear
    addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      closeButton.heightAnchor.constraint(equalToConstant: 28),
      closeButton.widthAnchor.constraint(equalToConstant: 28),
    ])
    closeButton.addTarget(self, action: #selector(closeClick), for: .touchUpInside)

    addSubview(saveButton)
    NSLayoutConstraint.activate([
      saveButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
      saveButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      saveButton.heightAnchor.constraint(equalToConstant: 28),
      saveButton.widthAnchor.constraint(equalToConstant: 28),
    ])
    saveButton.addTarget(self, action: #selector(saveClick), for: .touchUpInside)
  }

  open func saveClick() {
    delegate?.didSaveClick()
  }

  open func closeClick() {
    delegate?.didCloseClick()
  }
}
