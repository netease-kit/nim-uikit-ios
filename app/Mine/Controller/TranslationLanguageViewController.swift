// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit
import YXLogin

/// 翻译目标语言选择页（Demo 层）
/// 展示 15 种语言，右上角「保存」确认，退出返回放弃
class TranslationLanguageViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private static let cellId = "TranslationLangCell"
  private let userDefaults = UserDefaults.standard

  /// 当前选中的语言码（未保存前为临时值）
  private var selectedCode: String

  init() {
    selectedCode = IMKitConfigCenter.shared.translationTargetLanguage
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.backgroundColor = .clear
    tv.dataSource = self
    tv.delegate = self
    tv.rowHeight = 52
    tv.separatorColor = .ne_greyLine
    tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    tv.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellId)
    return tv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("translation_target_language")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }

    // 右上角「保存」按钮（与 LanguageViewController 对齐，清除默认图标，使用文字）
    navigationView.moreButton.setImage(nil, for: .normal)
    navigationView.setMoreButtonTitle(localizable("save"))
    if NEStyleManager.instance.isNormalStyle() {
      navigationView.moreButton.setTitleColor(.ne_normalTheme, for: .normal)
    } else {
      navigationView.setMoreButtonWidth(NEAppLanguageUtil.getCurrentLanguage() == .english ? 80 : 34)
      navigationView.moreButton.setTitleColor(.ne_funTheme, for: .normal)
    }
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveAction))

    view.addSubview(tableView)
    let topOffset = topConstant + (NEStyleManager.instance.isNormalStyle() ? 12 : 0)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func saveAction() {
    // 持久化 + 更新 IMKitConfigCenter
    IMKitConfigCenter.shared.translationTargetLanguage = selectedCode
    userDefaults.set(selectedCode, forKey: "translationTargetLanguage")
    navigationController?.popViewController(animated: true)
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    TranslationSettingViewController.languages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellId, for: indexPath)
    let pair = TranslationSettingViewController.languages[indexPath.row]
    cell.textLabel?.text = localizable(pair.nameKey)
    cell.textLabel?.font = .systemFont(ofSize: 16)

    if NEStyleManager.instance.isNormalStyle() {
      cell.backgroundColor = .white
      cell.textLabel?.textColor = .ne_darkText
      cell.accessoryType = (pair.code == selectedCode) ? .checkmark : .none
      cell.tintColor = UIColor(hexString: "0x337EFF")
    } else {
      cell.backgroundColor = .funChatBackgroundColor
      cell.textLabel?.textColor = .ne_darkText
      cell.accessoryType = (pair.code == selectedCode) ? .checkmark : .none
      cell.tintColor = UIColor(hexString: "0x58BE6B")
    }
    cell.selectionStyle = .none
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let newCode = TranslationSettingViewController.languages[indexPath.row].code
    guard newCode != selectedCode else { return }
    selectedCode = newCode
    tableView.reloadData()
  }
}
