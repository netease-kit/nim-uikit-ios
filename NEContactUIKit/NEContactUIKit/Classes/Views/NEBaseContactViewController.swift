
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseContactViewController: UIViewController, UIGestureRecognizerDelegate {
  var topConstant: CGFloat = 0
  public let navigationView = NENavigationView()

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: "",
      frame: CGRect.zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view

  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    view.backgroundColor = .white
    edgesForExtendedLayout = []
    navigationController?.interactivePopGestureRecognizer?.delegate = self

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
      setupBackUI()
      topConstant = 0
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      navigationView.translatesAutoresizingMaskIntoConstraints = false
      navigationView.addBackButtonTarget(target: self, selector: #selector(backToPrevious))
      navigationView.moreButton.isHidden = true
      view.addSubview(navigationView)
      NSLayoutConstraint.activate([
        navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        navigationView.topAnchor.constraint(equalTo: view.topAnchor),
        navigationView.heightAnchor.constraint(equalToConstant: topConstant),
      ])
    }
  }

  open func setupBackUI() {
    navigationController?.navigationBar.tintColor = .white
    let backItem = UIBarButtonItem(
      image: UIImage.ne_imageNamed(name: "backArrow"),
      style: .plain,
      target: self,
      action: #selector(backToPrevious)
    )
    backItem.accessibilityIdentifier = "id.backArrow"
    backItem.tintColor = UIColor(hexString: "333333")
    navigationItem.leftBarButtonItem = backItem
  }

  open func backToPrevious() {
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
