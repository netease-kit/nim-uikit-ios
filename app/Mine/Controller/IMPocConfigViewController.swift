//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit

class IMPocConfigViewController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource {
  var cellClassDic =
    [SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self, SettingCellType.SettingArrowCell.rawValue: ArrowTitleCustomTeamSettingSwitchCell.self, SettingCellType.SettingSubtitleCell.rawValue: CustomSettingInputCell.self, SettingCellType.SettingSubtitleCustomCell.rawValue: CustomSettingTextviewCell.self]

  var sectionData = [SettingSectionModel]()

  lazy var contentTableView: UITableView = {
    let tableView = UITableView()
    tableView.separatorColor = .clear
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 12.0
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  var configModel: IMPocConfigModel

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    configModel = IMPocConfigManager.instance.getConfig()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    configModel = IMPocConfigManager.instance.getConfig()
    super.init(coder: coder)
  }

  /// 是否是自动解析
  var isCustomJsonParse = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "私有云环境配置"
    setupCellData()
    setupUI()
  }

  open func setupUI() {
    navigationView.moreButton.isHidden = true

    view.addSubview(contentTableView)
    NSLayoutConstraint.activate([
      contentTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      contentTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      contentTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.statusBarHeight + NEConstant.navigationHeight),
      contentTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentTableView.tableFooterView = getFooterView()

    for (key, value) in cellClassDic {
      contentTableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  let twoSectionModel = SettingSectionModel()

  let customSectionModel = SettingSectionModel()

  let autoConfig = CustomSettingCellModel()

  func setupCellData() {
    let oneSectionModel = SettingSectionModel()
    sectionData.append(oneSectionModel)

    let usePrivateConfigModel = SettingCellModel()
    usePrivateConfigModel.cellName = "私有化环境配置生效"
    usePrivateConfigModel.type = SettingCellType.SettingSwitchCell.rawValue
    weak var weakSelf = self
    usePrivateConfigModel.switchOpen = configModel.enableCustomConfig.boolValue
    usePrivateConfigModel.swichChange = { isOpen in
      weakSelf?.configModel.enableCustomConfig = NSNumber(booleanLiteral: isOpen)
    }
    oneSectionModel.cellModels.append(usePrivateConfigModel)
    oneSectionModel.setCornerType()

    let configType = SettingCellModel()
    configType.cellName = "配置方式"
    configType.subTitle = "手动填写"
    configType.type = SettingCellType.SettingArrowCell.rawValue
    twoSectionModel.cellModels.append(configType)

    let appKey = CustomSettingCellModel()
    appKey.cellName = "AppKey"
    appKey.type = SettingCellType.SettingSubtitleCell.rawValue
    appKey.inputKey = #keyPath(NIMSDKOption.appKey)
    if let appKeyValue = configModel.configMap[appKey.inputKey] as? String {
      appKey.customInputText = appKeyValue
    }
    twoSectionModel.cellModels.append(appKey)

    let module = CustomSettingCellModel()
    module.cellName = "Module"
    module.type = SettingCellType.SettingSubtitleCell.rawValue
    module.inputKey = #keyPath(NIMServerSetting.module)
    if let moduleValue = configModel.configMap[module.inputKey] as? String {
      module.customInputText = moduleValue
    }
    twoSectionModel.cellModels.append(module)

    let linkModel = CustomSettingCellModel()
    linkModel.cellName = "服务器Link地址"
    linkModel.type = SettingCellType.SettingSubtitleCell.rawValue
    linkModel.inputKey = #keyPath(NIMServerSetting.linkAddress)
    if let linkValue = configModel.configMap[linkModel.inputKey] as? String {
      linkModel.customInputText = linkValue
    }
    twoSectionModel.cellModels.append(linkModel)

    let lbsModel = CustomSettingCellModel()
    lbsModel.cellName = "LBS服务器地址"
    lbsModel.type = SettingCellType.SettingSubtitleCell.rawValue
    lbsModel.inputKey = #keyPath(NIMServerSetting.lbsAddress)
    if let lbsValue = configModel.configMap[lbsModel.inputKey] as? String {
      lbsModel.customInputText = lbsValue
    }
    twoSectionModel.cellModels.append(lbsModel)

    let nosToLBSModel = CustomSettingCellModel()
    nosToLBSModel.cellName = "NOS上传LBS服务器地址"
    nosToLBSModel.type = SettingCellType.SettingSubtitleCell.rawValue
    nosToLBSModel.inputKey = #keyPath(NIMServerSetting.nosLbsAddress)
    if let nosLbsAddress = configModel.configMap[nosToLBSModel.inputKey] as? String {
      nosToLBSModel.customInputText = nosLbsAddress
    }
    twoSectionModel.cellModels.append(nosToLBSModel)

    let nosToLBSLinkModel = CustomSettingCellModel()
    nosToLBSLinkModel.cellName = "NOS上传LBS服务器默认Link服务器地址"
    nosToLBSLinkModel.type = SettingCellType.SettingSubtitleCell.rawValue
    nosToLBSLinkModel.inputKey = #keyPath(NIMServerSetting.nosUploadAddress)
    if let nosUploadAddress = configModel.configMap[nosToLBSLinkModel.inputKey] as? String {
      nosToLBSLinkModel.customInputText = nosUploadAddress
    }
    twoSectionModel.cellModels.append(nosToLBSLinkModel)

    let nosSplicingModel = CustomSettingCellModel()
    nosSplicingModel.cellName = "NOS拼接下载地址"
    nosSplicingModel.type = SettingCellType.SettingSubtitleCell.rawValue
    nosSplicingModel.inputKey = #keyPath(NIMServerSetting.nosDownloadAddress)
    if let nosDownloadAddress = configModel.configMap[nosSplicingModel.inputKey] as? String {
      nosSplicingModel.customInputText = nosDownloadAddress
    }
    twoSectionModel.cellModels.append(nosSplicingModel)

    let nosUpladModel = CustomSettingCellModel()
    nosUpladModel.cellName = "NOS上传服务器主机地址"
    nosUpladModel.type = SettingCellType.SettingSubtitleCell.rawValue
    nosUpladModel.inputKey = #keyPath(NIMServerSetting.nosUploadHost)
    if let nosUploadHost = configModel.configMap[nosUpladModel.inputKey] as? String {
      nosUpladModel.customInputText = nosUploadHost
    }
    twoSectionModel.cellModels.append(nosUpladModel)

    twoSectionModel.setCornerType()

    let autoconfigType = CustomSettingCellModel()
    autoconfigType.cellName = "配置方式"
    autoconfigType.subTitle = "一键自动解析"
    autoconfigType.type = SettingCellType.SettingArrowCell.rawValue
    autoconfigType.rowHeight = 49.0
    customSectionModel.cellModels.append(autoconfigType)

    autoConfig.cellName = "填写私有化配置内容"
    autoConfig.type = SettingCellType.SettingSubtitleCustomCell.rawValue
    autoConfig.rowHeight = 200
    autoConfig.customInputText = configModel.customJson

    customSectionModel.cellModels.append(autoConfig)

    customSectionModel.setCornerType()

    sectionData.append(customSectionModel)
  }

  func didSave() {
    for model in twoSectionModel.cellModels {
      if let customModel = model as? CustomSettingCellModel, customModel.inputKey.count > 0 {
        if let customText = customModel.customInputText, customText.count > 0 {
          configModel.configMap[customModel.inputKey] = customText
        } else {
          configModel.configMap.removeObject(forKey: customModel.inputKey)
        }
      }
    }

    if let custom = autoConfig.customInputText, custom.count > 0 {
      configModel.customJson = custom
    } else {
      configModel.customJson = nil
    }

    showToast("保存成功，请重新启动应用登录")
    IMPocConfigManager.instance.saveConfig(model: configModel)
    navigationController?.popViewController(animated: true)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if sectionData.count > section {
      let model = sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if indexPath.section == 1 {
      if indexPath.row == 0 {
        print("height for row : ", model.rowHeight)
      }
    }
    return model.rowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    10
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == 0 {
      return 40
    }
    return 0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .clear
    return headerView
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      if indexPath.row == 0 {
        changeParseModel()
      }
    }
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let footerView = UIView()
    footerView.backgroundColor = .clear
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 16)
    footerView.addSubview(label)

    if NEStyleManager.instance.isNormalStyle() {
      NSLayoutConstraint.activate([
        label.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 36),
        label.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: -36),
        label.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        label.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 20),
        label.rightAnchor.constraint(equalTo: footerView.rightAnchor, constant: -20),
        label.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
      ])
    }

    label.text = "配置私有化参数"
    return footerView
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    sectionData.count
  }

  func autoParse() {
    if sectionData.count == 2 {
      sectionData.remove(at: 1)
      sectionData.append(customSectionModel)
    }
    isCustomJsonParse = true
    contentTableView.reloadData()
  }

  func customParse() {
    if sectionData.count == 2 {
      sectionData.remove(at: 1)
      sectionData.append(twoSectionModel)
    }
    isCustomJsonParse = false
    contentTableView.reloadData()
  }

  open func changeParseModel() {
    if NEStyleManager.instance.isNormalStyle() {
      let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      let autoAction = UIAlertAction(title: "一键自动解析", style: .default) { [weak self] _ in
        self?.autoParse()
      }
      let customAction = UIAlertAction(title: "手动填写", style: .default) { [weak self] _ in
        self?.customParse()
      }
      let cancelAction = UIAlertAction(title: commonLocalizable("cancel"), style: .cancel, handler: nil)
      actionSheet.addAction(autoAction)
      actionSheet.addAction(customAction)
      actionSheet.addAction(cancelAction)
      present(actionSheet, animated: true, completion: nil)
    } else {
      let neAutoAction = NECustomAlertAction(title: "一键自动解析") { [weak self] in
        self?.autoParse()
      }
      let neCustomAction = NECustomAlertAction(title: "手动填写") { [weak self] in
        self?.customParse()
      }
      showCustomActionSheet([neAutoAction, neCustomAction])
    }
  }

  open func getFooterView() -> UIView {
    let back = UIView()
    back.backgroundColor = .clear
    back.frame = CGRectMake(0, 0, view.frame.width, 60)
    let button = ExpandButton()
    back.addSubview(button)
    button.setTitle(localizable("save"), for: .normal)
    button.setTitleColor(.white, for: .normal)
    if NEStyleManager.instance.isNormalStyle() {
      button.backgroundColor = UIColor.ne_normalTheme
      button.frame = CGRectMake(20, 10, view.frame.width - 40, 40)
    } else {
      button.frame = CGRectMake(0, 10, view.frame.width, 40)
      button.backgroundColor = UIColor.ne_funTheme
    }
    button.addTarget(self, action: #selector(didSave), for: .touchUpInside)
    return back
  }
}
