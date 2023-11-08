// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import UIKit

@objc
open class FunFindFriendViewController: NEBaseFindFriendViewController {
  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override open func setupUI() {
    view.backgroundColor = UIColor(hexString: "0xEDEDED")

    let searchBack = UIView()
    view.addSubview(searchBack)
    searchBack.backgroundColor = UIColor.white
    searchBack.translatesAutoresizingMaskIntoConstraints = false
    searchBack.clipsToBounds = true
    searchBack.layer.cornerRadius = 4.0
    NSLayoutConstraint.activate([
      searchBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      searchBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      searchBack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10 + topConstant),
      searchBack.heightAnchor.constraint(equalToConstant: 36),
    ])

    let searchImage = UIImageView()
    searchBack.addSubview(searchImage)
    searchImage.image = UIImage.ne_imageNamed(name: "search")
    searchImage.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchImage.centerYAnchor.constraint(equalTo: searchBack.centerYAnchor),
      searchImage.leftAnchor.constraint(equalTo: searchBack.leftAnchor, constant: 18),
      searchImage.widthAnchor.constraint(equalToConstant: 13),
      searchImage.heightAnchor.constraint(equalToConstant: 13),
    ])

    searchBack.addSubview(searchInput)
    searchInput.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchInput.leftAnchor.constraint(equalTo: searchImage.rightAnchor, constant: 5),
      searchInput.rightAnchor.constraint(equalTo: searchBack.rightAnchor, constant: -18),
      searchInput.topAnchor.constraint(equalTo: searchBack.topAnchor),
      searchInput.bottomAnchor.constraint(equalTo: searchBack.bottomAnchor),
    ])
    searchInput.textColor = UIColor(hexString: "0x333333")
    searchInput.placeholder = localizable("input_userId")
    searchInput.font = UIFont.systemFont(ofSize: 14.0)
    searchInput.returnKeyType = .search
    searchInput.delegate = self
    searchInput.clearButtonMode = .always

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
    ])

    emptyView.setEmptyImage(name: "fun_user_empty")
  }
}
