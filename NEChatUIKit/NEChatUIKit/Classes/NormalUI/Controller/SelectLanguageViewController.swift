//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class SelectLanguageViewController: NEBaseSelectLanguageViewController {
  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override open func setupLanguageUI() {
    super.setupLanguageUI()
    viewModel.setupData(false)

    // 隐藏导航栏后自定义顶部样式
    let backButton = UIButton(type: .custom)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    backButton.accessibilityIdentifier = "id.cancel"
    backButton.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    backButton.setImage(UIImage.ne_imageNamed(name: "arrowDown"), for: .normal)
    backButton.titleLabel?.textColor = .ne_greyText
    backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
    view.addSubview(backButton)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        backButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        backButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        backButton.widthAnchor.constraint(equalToConstant: 50),
        backButton.heightAnchor.constraint(equalToConstant: 50),
      ])
    } else {
      NSLayoutConstraint.activate([
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        backButton.topAnchor.constraint(equalTo: view.topAnchor),
        backButton.widthAnchor.constraint(equalToConstant: 50),
        backButton.heightAnchor.constraint(equalToConstant: 50),
      ])
    }

    let navTitleLabel = UILabel()
    navTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    navTitleLabel.text = chatLocalizable("language_title")
    navTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    navTitleLabel.textAlignment = .center
    navTitleLabel.textColor = .ne_darkText
    view.addSubview(navTitleLabel)
    NSLayoutConstraint.activate([
      navTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      navTitleLabel.topAnchor.constraint(equalTo: view.topAnchor),
      navTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
      navTitleLabel.heightAnchor.constraint(equalToConstant: 50),
    ])

    view.addSubview(languageTableView)
    NSLayoutConstraint.activate([
      languageTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      languageTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      languageTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      languageTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    languageTableView.backgroundColor = .clear

    languageTableView.register(LanguageCell.self, forCellReuseIdentifier: "\(NEBaseLanguageCell.self)")
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
