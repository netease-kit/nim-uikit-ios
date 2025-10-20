//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

open class ChatNavigationView: NENavigationView {
  public lazy var earImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = .ne_imageNamed(name: "op_earpiece")
    imageView.isHidden = true
    return imageView
  }()

  override open func setupUI() {
    super.setupUI()
    titleBarView.addSubview(earImageView)
    NSLayoutConstraint.activate([
      earImageView.leftAnchor.constraint(equalTo: navTitle.rightAnchor),
      earImageView.centerYAnchor.constraint(equalTo: navTitle.centerYAnchor),
    ])
  }

  open func setHandsetMode(_ ear: Bool) {
    earImageView.isHidden = ear
  }
}
