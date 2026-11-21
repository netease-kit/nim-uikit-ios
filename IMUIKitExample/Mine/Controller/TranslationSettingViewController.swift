// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NETeamUIKit
import NIMSDK
import UIKit

/// 翻译设置页面（Demo 层）
/// 提供翻译目标语言和自动翻译设置
class TranslationSettingViewController: NEBaseViewController, UITableViewDataSource, UITableViewDelegate {
  private let userDefaults = UserDefaults.standard
  private let languageCellType = 901

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
    ("ru", "lang_ru"),
    ("pt", "lang_pt"),
    ("it", "lang_it"),
    ("vi", "lang_vi"),
    ("th", "lang_th"),
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
    tv.estimatedRowHeight = 73
    tv.rowHeight = UITableView.automaticDimension
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
    let subtitleSwitchCellClass: AnyClass = NEStyleManager.instance.isNormalStyle()
      ? TranslationAutoSettingCell.self
      : FunTranslationAutoSettingCell.self
    tableView.register(
      subtitleSwitchCellClass,
      forCellReuseIdentifier: "\(SettingCellType.SettingSubtitleSelectCell.rawValue)"
    )
    let selectCellClass: AnyClass = NEStyleManager.instance.isNormalStyle()
      ? TranslationLanguageSettingCell.self
      : FunTranslationLanguageSettingCell.self
    tableView.register(
      selectCellClass,
      forCellReuseIdentifier: "\(languageCellType)"
    )

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

    // 1. 语言选择行
    let langRow = SettingCellLabelArrowModel()
    langRow.cellName = localizable("translation_item_title")
    langRow.subTitle = localizable("translation_item_subtitle")
    langRow.arrowLabelText = currentLanguageName()
    langRow.type = languageCellType
    langRow.rowHeight = 73
    langRow.cellClick = {
      let langVC = TranslationLanguageViewController()
      weakSelf?.navigationController?.pushViewController(langVC, animated: true)
    }
    section.cellModels.append(langRow)

    // 2. 自动翻译开关
    let autoRow = SettingCellModel()
    autoRow.cellName = localizable("auto_translation")
    autoRow.subTitle = localizable("auto_translation_tip")
    autoRow.type = SettingCellType.SettingSubtitleSelectCell.rawValue
    autoRow.rowHeight = 73
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
    UITableView.automaticDimension
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

private protocol TranslationLanguageValueCell: AnyObject {
  var languageValueLabel: UILabel { get }
}

private extension TranslationLanguageValueCell where Self: NEBaseTeamSettingSelectCell {
  func setupLanguageValueLabel() {
    subTitleLabel.numberOfLines = 0
    subTitleLabel.lineBreakMode = .byWordWrapping
    languageValueLabel.translatesAutoresizingMaskIntoConstraints = false
    languageValueLabel.textColor = .ne_lightText
    languageValueLabel.font = UIFont.systemFont(ofSize: 14)
    languageValueLabel.textAlignment = .right
    contentView.addSubview(languageValueLabel)

    let subtitleRightConstraints = contentView.constraints.filter {
      ($0.firstItem as AnyObject?) === subTitleLabel && $0.firstAttribute == .right
    }
    subtitleRightConstraints.forEach { $0.isActive = false }

    NSLayoutConstraint.activate([
      languageValueLabel.rightAnchor.constraint(equalTo: arrowView.leftAnchor, constant: -6),
      languageValueLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: languageValueLabel.leftAnchor, constant: -8),
      subTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])
  }

  func configureLanguageValue(_ anyModel: Any) {
    if let model = anyModel as? SettingCellLabelArrowModel {
      languageValueLabel.text = model.arrowLabelText
    }
  }
}

private final class TranslationLanguageSettingCell: TeamSettingSelectCell, TranslationLanguageValueCell {
  let languageValueLabel = UILabel()

  override func setupUI() {
    super.setupUI()
    setupLanguageValueLabel()
  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    configureLanguageValue(anyModel)
  }
}

private final class FunTranslationLanguageSettingCell: FunTeamSettingSelectCell, TranslationLanguageValueCell {
  let languageValueLabel = UILabel()

  override func setupUI() {
    super.setupUI()
    setupLanguageValueLabel()
  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    configureLanguageValue(anyModel)
  }
}

private protocol TranslationAutoSubtitleCell: AnyObject {}

private extension TranslationAutoSubtitleCell where Self: NEBaseTeamSettingSubtitleSwitchCell {
  func constrainSubtitleToTitle() {
    subTitleLabel.numberOfLines = 0
    subTitleLabel.lineBreakMode = .byWordWrapping

    let subtitleRightConstraints = contentView.constraints.filter {
      ($0.firstItem as AnyObject?) === subTitleLabel && $0.firstAttribute == .right
    }
    subtitleRightConstraints.forEach { $0.isActive = false }
    NSLayoutConstraint.activate([
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
      subTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])
  }
}

private final class TranslationAutoSettingCell: TeamSettingSubtitleSwitchCell, TranslationAutoSubtitleCell {
  override func setupUI() {
    super.setupUI()
    constrainSubtitleToTitle()
  }
}

private final class FunTranslationAutoSettingCell: FunTeamSettingSubtitleSwitchCell, TranslationAutoSubtitleCell {
  override func setupUI() {
    super.setupUI()
    constrainSubtitleToTitle()
  }
}
