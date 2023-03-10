
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonUIKit

class ViewController: UIViewController {
  lazy var launchIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage(named: "launchIcon")
    return imageView
  }()

  lazy var launchIconLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = NSLocalizedString("appName", comment: "")
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.textColor = UIColor(hexString: "333333")
    return label
  }()

  lazy var copyright: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setImage(UIImage(named: "yunxin_brand"), for: .normal)
    btn.setTitle(NSLocalizedString("brand_des", comment: ""), for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    btn.setTitleColor(UIColor(hexString: "333333"), for: .normal)
    btn.layoutButtonImage(style: .left, space: 5.0)
    return btn
  }()

  lazy var slogan: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = NSLocalizedString("real_service", comment: "")
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
    view.addSubview(launchIcon)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIcon.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 145.0
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        launchIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 145.0),
      ])
    }

    view.addSubview(launchIconLabel)
    NSLayoutConstraint.activate([
      launchIconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      launchIconLabel.topAnchor.constraint(equalTo: launchIcon.bottomAnchor, constant: -12.0),
    ])

    view.addSubview(slogan)
    NSLayoutConstraint.activate([
      slogan.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      slogan.topAnchor.constraint(equalTo: launchIconLabel.bottomAnchor, constant: 12.0),

    ])

    view.addSubview(copyright)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        copyright.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        copyright.bottomAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.bottomAnchor,
          constant: -48
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        copyright.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        copyright.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48),
      ])
    }
  }
}
