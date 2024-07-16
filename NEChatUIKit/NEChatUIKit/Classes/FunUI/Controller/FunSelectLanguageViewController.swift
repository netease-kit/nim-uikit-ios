//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunSelectLanguageViewController: NEBaseSelectLanguageViewController {
  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override open func setupLanguageUI() {
    super.setupLanguageUI()

    view.backgroundColor = .funChatBackgroundColor

    viewModel.setupData(true)
    let funBackButton = UIButton(type: .custom)
    funBackButton.translatesAutoresizingMaskIntoConstraints = false
    funBackButton.accessibilityIdentifier = "id.cancel"
    funBackButton.setImage(UIImage.ne_imageNamed(name: "arrowDown"), for: .normal)
    funBackButton.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    view.addSubview(funBackButton)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        funBackButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        funBackButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        funBackButton.widthAnchor.constraint(equalToConstant: 50),
        funBackButton.heightAnchor.constraint(equalToConstant: 50),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        funBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        funBackButton.topAnchor.constraint(equalTo: view.topAnchor),
        funBackButton.widthAnchor.constraint(equalToConstant: 50),
        funBackButton.heightAnchor.constraint(equalToConstant: 50),
      ])
    }

    let funNavTitleLabel = UILabel()
    funNavTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    funNavTitleLabel.text = chatLocalizable("language_title")
    funNavTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    funNavTitleLabel.textAlignment = .center
    funNavTitleLabel.textColor = .ne_darkText
    view.addSubview(funNavTitleLabel)
    NSLayoutConstraint.activate([
      funNavTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      funNavTitleLabel.topAnchor.constraint(equalTo: view.topAnchor),
      funNavTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
      funNavTitleLabel.heightAnchor.constraint(equalToConstant: 50),
    ])

    view.addSubview(languageTableView)
    NSLayoutConstraint.activate([
      languageTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      languageTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      languageTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 58),
      languageTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    languageTableView.register(FunLanguageCell.self, forCellReuseIdentifier: "\(NEBaseLanguageCell.self)")
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
