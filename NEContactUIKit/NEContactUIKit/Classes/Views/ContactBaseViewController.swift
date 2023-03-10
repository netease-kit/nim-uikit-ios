
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ContactBaseViewController: UIViewController {
  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: "",
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    view.backgroundColor = .white
    edgesForExtendedLayout = []

    setupBackUI()
  }

  private func setupBackUI() {
    navigationController?.navigationBar.tintColor = .white
    let backItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "backArrow"),
      style: .plain,
      target: self,
      action: #selector(backToPrevious)
    )
    backItem.tintColor = UIColor(hexString: "333333")
    navigationItem.leftBarButtonItem = backItem
  }

  func backToPrevious() {
    navigationController?.popViewController(animated: true)
  }
  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
