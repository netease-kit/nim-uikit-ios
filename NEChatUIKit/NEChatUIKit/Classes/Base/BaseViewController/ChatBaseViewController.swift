
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit

@objc open class ChatBaseViewController: UIViewController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupBackUI()
  }

  private func setupBackUI() {
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
  }

  @objc func backEvent() {
    navigationController?.popViewController(animated: true)
  }
}
