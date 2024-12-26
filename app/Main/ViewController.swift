
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

class ViewController: UIViewController {
  lazy var launchIconView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage(named: "launchIcon")
    return imageView
  }()

  lazy var launchIconLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("appName")
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.textColor = UIColor(hexString: "333333")
    return label
  }()

  lazy var copyright: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage(named: "yunxin_brand"), for: .normal)
    button.setTitle(localizable("brand_des"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    button.setTitleColor(UIColor(hexString: "333333"), for: .normal)
    button.layoutButtonImage(style: .left, space: 5.0)
    return button
  }()

  lazy var slogan: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("real_service")
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.textColor = UIColor(hexString: "666666")
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    setupUI()
  }

  func setupUI() {
    view.addSubview(launchIconView)

    NSLayoutConstraint.activate([
      launchIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 145.0),
    ])

    view.addSubview(launchIconLabel)
    NSLayoutConstraint.activate([
      launchIconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconLabel.topAnchor.constraint(equalTo: launchIconView.bottomAnchor, constant: -12.0),
    ])

    view.addSubview(slogan)
    NSLayoutConstraint.activate([
      slogan.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      slogan.topAnchor.constraint(equalTo: launchIconLabel.bottomAnchor, constant: 12.0),

    ])

    view.addSubview(copyright)

    NSLayoutConstraint.activate([
      copyright.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      copyright.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
    ])
  }
}
