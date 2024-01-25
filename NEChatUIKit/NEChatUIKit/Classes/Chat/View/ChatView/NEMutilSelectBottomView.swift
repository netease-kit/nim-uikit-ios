//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

public protocol NEMutilSelectBottomViewDelegate: NSObjectProtocol {
  func didClickSingleForwardButton()
  func didClickMultiForwardButton()
  func didClickDeleteButton()
}

open class NEMutilSelectBottomView: UIView {
  public weak var delegate: NEMutilSelectBottomViewDelegate?
  public var buttonTopAnchor: NSLayoutConstraint?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupSubview()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func setupSubview() {
    // 逐条转发
    addSubview(singleForwardButton)
    buttonTopAnchor = singleForwardButton.topAnchor.constraint(equalTo: topAnchor, constant: 12)
    NSLayoutConstraint.activate([
      buttonTopAnchor!,
      singleForwardButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      singleForwardButton.widthAnchor.constraint(equalToConstant: 48),
      singleForwardButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    addSubview(singleForwardLabel)
    NSLayoutConstraint.activate([
      singleForwardLabel.topAnchor.constraint(equalTo: singleForwardButton.bottomAnchor, constant: 3),
      singleForwardLabel.centerXAnchor.constraint(equalTo: singleForwardButton.centerXAnchor),
      singleForwardLabel.widthAnchor.constraint(equalToConstant: 48),
      singleForwardLabel.heightAnchor.constraint(equalToConstant: 12),
    ])

    // 合并转发
    addSubview(multiForwardButton)
    NSLayoutConstraint.activate([
      multiForwardButton.centerYAnchor.constraint(equalTo: singleForwardButton.centerYAnchor),
      multiForwardButton.rightAnchor.constraint(equalTo: singleForwardButton.leftAnchor, constant: -52),
      multiForwardButton.widthAnchor.constraint(equalToConstant: 48),
      multiForwardButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    addSubview(multiForwardLabel)
    NSLayoutConstraint.activate([
      multiForwardLabel.centerYAnchor.constraint(equalTo: singleForwardLabel.centerYAnchor),
      multiForwardLabel.centerXAnchor.constraint(equalTo: multiForwardButton.centerXAnchor),
      multiForwardLabel.widthAnchor.constraint(equalToConstant: 48),
      multiForwardLabel.heightAnchor.constraint(equalToConstant: 12),
    ])

    // 删除
    addSubview(deleteButton)
    NSLayoutConstraint.activate([
      deleteButton.centerYAnchor.constraint(equalTo: singleForwardButton.centerYAnchor),
      deleteButton.leftAnchor.constraint(equalTo: singleForwardButton.rightAnchor, constant: 52),
      deleteButton.widthAnchor.constraint(equalToConstant: 48),
      deleteButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    addSubview(deleteLabel)
    NSLayoutConstraint.activate([
      deleteLabel.centerYAnchor.constraint(equalTo: singleForwardLabel.centerYAnchor),
      deleteLabel.centerXAnchor.constraint(equalTo: deleteButton.centerXAnchor),
      deleteLabel.widthAnchor.constraint(equalToConstant: 48),
      deleteLabel.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  public lazy var singleForwardButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "select_singleForward"), for: .normal)
    button.setImage(.ne_imageNamed(name: "unselect_singleForward"), for: .disabled)
    button.addTarget(self, action: #selector(singleForwardButtonAction), for: .touchUpInside)
    return button
  }()

  public lazy var singleForwardLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("select_per_item")
    label.textColor = .ne_greyText
    label.font = .systemFont(ofSize: 11)
    label.textAlignment = .center
    return label
  }()

  public lazy var multiForwardButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "select_multiForward"), for: .normal)
    button.setImage(.ne_imageNamed(name: "unselect_multiForward"), for: .disabled)
    button.addTarget(self, action: #selector(multiForwardButtonAction), for: .touchUpInside)
    return button
  }()

  public lazy var multiForwardLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("select_multi")
    label.textColor = .ne_greyText
    label.font = .systemFont(ofSize: 11)
    label.textAlignment = .center
    return label
  }()

  public lazy var deleteButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(.ne_imageNamed(name: "select_delete"), for: .normal)
    button.setImage(.ne_imageNamed(name: "unselect_delete"), for: .disabled)
    button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
    return button
  }()

  public lazy var deleteLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("operation_delete")
    label.textColor = .ne_greyText
    label.font = .systemFont(ofSize: 11)
    label.textAlignment = .center
    return label
  }()

  func setEnable(_ enable: Bool) {
    multiForwardButton.isEnabled = enable
    singleForwardButton.isEnabled = enable
    deleteButton.isEnabled = enable
    multiForwardLabel.isEnabled = enable
    singleForwardLabel.isEnabled = enable
    deleteLabel.isEnabled = enable
  }

  func setLabelColor(color: UIColor) {
    multiForwardLabel.textColor = color
    singleForwardLabel.textColor = color
    deleteLabel.textColor = color
  }

  @objc func multiForwardButtonAction() {
    delegate?.didClickMultiForwardButton()
  }

  @objc func singleForwardButtonAction() {
    delegate?.didClickSingleForwardButton()
  }

  @objc func deleteButtonAction() {
    delegate?.didClickDeleteButton()
  }
}
