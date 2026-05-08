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

/// 翻译设置页面（Demo 层）
/// 提供「翻译目标语言」入口行（右侧显示当前语言）和「自动翻译」开关
class TranslationSettingViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private let userDefaults = UserDefaults.standard

  /// 语言行使用独立 cell 类型标识（右侧显示语言名），不与普通 ArrowCell 复用
  private let langArrowCellType = 900

  // MARK: - 语言映射表（语言码 → i18n key）

  static let languages: [(code: String, nameKey: String)] = [
    ("zh-CHS", "lang_zh_chs"),
    ("zh-CHT", "lang_zh_cht"),
    ("en", "lang_en"),
    ("ja", "lang_ja"),
    ("ko", "lang_ko"),
    ("fr", "lang_fr"),
    ("de", "lang_de"),
    ("es", "lang_es"),
    ("it", "lang_it"),
    ("ru", "lang_ru"),
    ("pt", "lang_pt"),
    ("ar", "lang_ar"),
    ("th", "lang_th"),
    ("vi", "lang_vi"),
    ("id", "lang_id"),
  ]

  private var sectionData = [SettingSectionModel]()

  lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.backgroundColor = .clear
    tv.dataSource = self
    tv.delegate = self
    tv.separatorColor = .clear
    tv.separatorStyle = .none
    tv.estimatedRowHeight = 0
    tv.estimatedSectionHeaderHeight = 0
    tv.estimatedSectionFooterHeight = 0
    if #available(iOS 15.0, *) {
      tv.sectionHeaderTopPadding = 0
    }
    return tv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("translation_setting")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }
    navigationView.moreButton.isHidden = true

    // 注册普通 ArrowCell（自动翻译开关行）和 SwitchCell
    tableView.register(
      CustomTeamArrowSettingCell.self,
      forCellReuseIdentifier: "\(SettingCellType.SettingArrowCell.rawValue)"
    )
    tableView.register(
      CustomTeamSettingSwitchCell.self,
      forCellReuseIdentifier: "\(SettingCellType.SettingSwitchCell.rawValue)"
    )
    // 注册语言行专用 LabelArrow cell（右侧显示语言名）
    let langCellClass: AnyClass = NEStyleManager.instance.isNormalStyle()
      ? TeamSettingLabelArrowCell.self
      : FunTeamSettingLabelArrowCell.self
    tableView.register(langCellClass, forCellReuseIdentifier: "\(langArrowCellType)")

    view.addSubview(tableView)
    let topOffset = topConstant + (NEStyleManager.instance.isNormalStyle() ? 12 : 0)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    buildData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // 从语言选择页返回后刷新语言名
    buildData()
    tableView.reloadData()
  }

  // MARK: - 数据构建

  private func currentLanguageName() -> String {
    let code = IMKitConfigCenter.shared.translationTargetLanguage
    if let pair = TranslationSettingViewController.languages.first(where: { $0.code == code }) {
      return localizable(pair.nameKey)
    }
    return code
  }

  private func buildData() {
    sectionData.removeAll()
    let section = SettingSectionModel()
    weak var weakSelf = self

    // 1. 语言选择行（使用 SettingCellLabelArrowModel，右侧显示当前语言名）
    let langRow = SettingCellLabelArrowModel()
    langRow.cellName = localizable("translation_target_language")
    langRow.arrowLabelText = currentLanguageName()
    langRow.type = langArrowCellType // 使用专属类型，走 LabelArrow cell
    langRow.rowHeight = 52
    langRow.cellClick = {
      let langVC = TranslationLanguageViewController()
      weakSelf?.navigationController?.pushViewController(langVC, animated: true)
    }
    section.cellModels.append(langRow)

    // 2. 自动翻译开关
    let autoRow = SettingCellModel()
    autoRow.cellName = localizable("auto_translation")
    autoRow.type = SettingCellType.SettingSwitchCell.rawValue
    autoRow.rowHeight = 52
    autoRow.switchOpen = IMKitConfigCenter.shared.autoTranslationEnableTime > 0
    autoRow.swichChange = { isOpen in
      if isOpen {
        let now = Date().timeIntervalSince1970
        IMKitConfigCenter.shared.autoTranslationEnableTime = now
        weakSelf?.userDefaults.set(now, forKey: "autoTranslationEnableTime")
      } else {
        IMKitConfigCenter.shared.autoTranslationEnableTime = 0
        weakSelf?.userDefaults.set(0.0, forKey: "autoTranslationEnableTime")
      }
    }
    section.cellModels.append(autoRow)

    section.setCornerType()
    sectionData.append(section)
  }

  // MARK: - UITableViewDataSource

  func numberOfSections(in tableView: UITableView) -> Int { sectionData.count }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sectionData[section].cellModels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)", for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    sectionData[indexPath.section].cellModels[indexPath.row].cellClick?()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    sectionData[indexPath.section].cellModels[indexPath.row].rowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0 : 12
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let v = UIView()
    v.backgroundColor = .clear
    return v
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    section == sectionData.count - 1 ? 12 : 0
  }
}
