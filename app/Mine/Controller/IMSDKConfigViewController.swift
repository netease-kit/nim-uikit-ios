//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit

class IMSDKConfigViewController: NEBaseViewController, UITableViewDelegate, UITableViewDataSource {
  public var cellClassDic =
    [SettingCellType.SettingSwitchCell.rawValue: CustomTeamSettingSwitchCell.self, SettingCellType.SettingArrowCell.rawValue: CustomTeamArrowSettingCell.self, SettingCellType.SettingSubtitleCell.rawValue: CustomSettingInputCell.self, SettingCellType.SettingSubtitleCustomCell.rawValue: CustomSettingTextviewCell.self]

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

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  var configModel: IMSDKConfigModel

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    configModel = IMSDKConfigManager.instance.getConfig()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    configModel = IMSDKConfigManager.instance.getConfig()
    super.init(coder: coder)
  }

  /// 是否是自动解析
  public var isCustomJsonParse = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "私有云环境配置"
    setupCellData()
    setupUI()
  }

  public func setupUI() {
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
    view.backgroundColor = navigationView.backgroundColor
    navigationView.moreButton.isHidden = true
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
    usePrivateConfigModel.swichChange = { isOpen in
    }
    oneSectionModel.cellModels.append(usePrivateConfigModel)
    oneSectionModel.setCornerType()

    sectionData.append(twoSectionModel)

    let configType = SettingCellModel()
    configType.cellName = "配置方式"
    configType.type = SettingCellType.SettingArrowCell.rawValue
    twoSectionModel.cellModels.append(configType)

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
    autoconfigType.type = SettingCellType.SettingArrowCell.rawValue
    autoconfigType.rowHeight = 49.0
    customSectionModel.cellModels.append(autoconfigType)

    autoConfig.cellName = "填写私有化配置内容"
    autoConfig.type = SettingCellType.SettingSubtitleCustomCell.rawValue
    autoConfig.rowHeight = 200
    autoConfig.customInputText = configModel.customJson

    customSectionModel.cellModels.append(autoConfig)

    customSectionModel.setCornerType()
  }

  func didSave() {
    for sectionModel in sectionData {
      for model in sectionModel.cellModels {
        if let customModel = model as? CustomSettingCellModel, customModel.inputKey.count > 0 {
          if let customText = customModel.customInputText, customText.count > 0 {
            configModel.configMap[customModel.inputKey] = customText
          } else {
            configModel.configMap.removeValue(forKey: customModel.inputKey)
          }
        }
      }
    }
    if let custom = autoConfig.customInputText, custom.count > 0 {
      configModel.customJson = custom
    } else {
      configModel.customJson = nil
    }
    UIApplication.shared.keyWindow?.ne_makeToast("保存成功")
    IMSDKConfigManager.instance.saveConfig(model: configModel)
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

    label.text = "配置私有化参数配置"
    return footerView
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    sectionData.count
  }

  public func changeParseModel() {
    if isCustomJsonParse == false {
      if sectionData.count == 2 {
        sectionData.remove(at: 1)
        sectionData.append(customSectionModel)
      }
    } else {
      if sectionData.count == 2 {
        sectionData.remove(at: 1)
        sectionData.append(twoSectionModel)
      }
    }
    contentTableView.reloadData()
    isCustomJsonParse = !isCustomJsonParse
  }

  public func getFooterView() -> UIView {
    let back = UIView()
    back.backgroundColor = .clear
    back.frame = CGRectMake(0, 0, view.frame.width, 60)
    let button = ExpandButton()
    back.addSubview(button)
    button.setTitle("保存", for: .normal)
    button.setTitleColor(.white, for: .normal)
    if NEStyleManager.instance.isNormalStyle() {
      button.backgroundColor = UIColor.ne_blueText
      button.frame = CGRectMake(20, 10, view.frame.width - 40, 40)
    } else {
      button.frame = CGRectMake(0, 10, view.frame.width, 40)
      button.backgroundColor = UIColor.ne_funTheme
    }
    button.addTarget(self, action: #selector(didSave), for: .touchUpInside)
    return back
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
