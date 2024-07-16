// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NECoreKit
import UIKit

@objc
open class FunFindFriendViewController: NEBaseFindFriendViewController {
  override open func setupUI() {
    view.backgroundColor = UIColor(hexString: "0xEDEDED")

    let searchBackView = UIView()
    view.addSubview(searchBackView)
    searchBackView.backgroundColor = UIColor.white
    searchBackView.translatesAutoresizingMaskIntoConstraints = false
    searchBackView.clipsToBounds = true
    searchBackView.layer.cornerRadius = 4.0
    searchBackViewTopAnchor = searchBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10 + topConstant)
    searchBackViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      searchBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBackView.heightAnchor.constraint(equalToConstant: 36),
    ])

    let searchImageView = UIImageView()
    searchBackView.addSubview(searchImageView)
    searchImageView.image = UIImage.ne_imageNamed(name: "search")
    searchImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchImageView.centerYAnchor.constraint(equalTo: searchBackView.centerYAnchor),
      searchImageView.leftAnchor.constraint(equalTo: searchBackView.leftAnchor, constant: 18),
      searchImageView.widthAnchor.constraint(equalToConstant: 13),
      searchImageView.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBackView.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImageView.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBackView.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBackView.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBackView.bottomAnchor),
    ])
    searchInput.textColor = UIColor(hexString: "0x333333")
    searchInput.placeholder = localizable("input_userId")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always
    searchInput.accessibilityIdentifier = "id.addFriendAccount"
    if let clearButton = searchInput.value(forKey: "_clearButton") as? UIButton {
      clearButton.accessibilityIdentifier = "id.clear"
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textFieldChange),
      name: UITextField.textDidChangeNotification,
      object: nil
    )

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyView.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: 74),
      emptyView.widthAnchor.constraint(equalToConstant: 200),
      emptyView.heightAnchor.constraint(equalToConstant: 200),
    ])

    emptyView.setEmptyImage(name: "fun_user_empty")
  }
}
