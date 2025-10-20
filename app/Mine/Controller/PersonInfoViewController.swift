// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreIM2Kit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit

@objcMembers
public class PersonInfoViewController: NEBaseViewController,
  UINavigationControllerDelegate, PersonInfoViewModelDelegate, UITableViewDelegate,
  UITableViewDataSource, UIImagePickerControllerDelegate, NEContactListener {
  public var cellClassDic = [
    SettingCellType.SettingSubtitleCell.rawValue: CustomTeamSettingSubtitleCell.self,
    SettingCellType.SettingHeaderCell.rawValue: CustomTeamSettingHeaderCell.self,
    SettingCellType.SettingSubtitleCustomCell.rawValue: CustomTeamSettingRightCustomCell.self,
  ]
  private var viewModel = PersonInfoViewModel()
  private var className = "PersonInfoViewController"

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  private lazy var pickerView: BirthdayDatePickerView = {
    let picker = BirthdayDatePickerView()
    picker.translatesAutoresizingMaskIntoConstraints = false
    return picker
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    initialConfig()
    setupSubviews()
    viewModel.getData { [weak self] in
      self?.tableView.reloadData()
    }
  }

  func initialConfig() {
    title = localizable("person_info")

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }

    navigationView.moreButton.isHidden = true
    viewModel.delegate = self
  }

  func setupSubviews() {
    view.addSubview(tableView)
    if NEStyleManager.instance.isNormalStyle() {
      topConstant += 12
    }
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  func showAlert(firstContent: String, secondContent: String,
                 selectValue: @escaping ((_ value: NSInteger) -> Void)) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.modalPresentationStyle = .popover

    let first = UIAlertAction(title: firstContent, style: .default) { action in
      selectValue(0)
    }
    first.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    first.accessibilityIdentifier = "id.action1"

    let second = UIAlertAction(title: secondContent, style: .default) { action in
      selectValue(1)
    }
    second.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    second.accessibilityIdentifier = "id.action2"

    let cancel = UIAlertAction(title: commonLocalizable("cancel"),
                               style: .cancel)

    cancel.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    cancel.accessibilityIdentifier = "id.action3"

    alert.addAction(first)
    alert.addAction(second)
    alert.addAction(cancel)
    fixAlertOnIpad(alert)
    present(alert, animated: true, completion: nil)
  }

  func showCustomAlert(firstContent: String, secondContent: String,
                       selectValue: @escaping ((_ value: NSInteger) -> Void)) {
    let first = NECustomAlertAction(title: firstContent) {
      selectValue(0)
    }

    let second = NECustomAlertAction(title: secondContent) {
      selectValue(1)
    }

    showCustomActionSheet([first, second])
  }

  func showDatePicker() {
    view.addSubview(pickerView)
    pickerView.timeCallBack = { [weak self] time in
      if let t = time {
        self?.viewModel.updateSelfBirthday(t) { error in
          if let err = error {
            if err.code == protocolSendFailed {
              self?.showToast(commonLocalizable("network_error"))
            } else {
              self?.showToast(localizable("setting_birthday_failure"))
            }
          }
        }
      }
    }
    NSLayoutConstraint.activate([
      pickerView.leftAnchor.constraint(equalTo: view.leftAnchor),
      pickerView.rightAnchor.constraint(equalTo: view.rightAnchor),
      pickerView.topAnchor.constraint(equalTo: view.topAnchor),
      pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: UIImagePickerControllerDelegate

  open func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController
                                    .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    dismiss(animated: true, completion: nil)
  }

  open func uploadHeadImage(image: UIImage) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData?,
       var filePath = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)image/") {
      filePath += "\(IMKitClient.instance.account())_avatar.jpg"
      let succcess = imageData.write(toFile: filePath, atomically: true)
      if succcess {
        let fileTask = ResourceRepo.shared.createUploadFileTask(filePath)
        ResourceRepo.shared.uploadFile(fileTask, nil) { [weak self] urlString, error in
          if error == nil {
            self?.viewModel.updateSelfAvatar(urlString ?? "") { [weak self] error in
              if error != nil {
                self?.showToast(localizable("setting_head_failure"))
              }
            }
          } else {
            NEALog.errorLog(
              weakSelf?.className ?? "",
              desc: "CALLBACK upload image failed,error = \(error!)"
            )
          }
          self?.view.hideToastActivity()
        }
      }
    }
  }

  // MARK: PersonInfoViewModelDelegate

  func didClickHeadImage() {
    if NEStyleManager.instance.isNormalStyle() {
      if let callback = ChatUIConfig.shared.chatInputPhotoClick {
        let chatVC = self
        let takingPicturesAction = UIAlertAction(title: commonLocalizable("take_picture"),
                                                 style: .default) { [weak self] action in
          self?.goCamera(chatVC, true)
        }

        let photoAction = UIAlertAction(title: commonLocalizable("select_from_album"), style: .default) { _ in
          // 自定义图片选择器
          let vc = self
          callback(self, .image, avatarImageCountLimit) { [weak self] models, isOriginal in
            for model in models {
              if model.asset.mediaType == .video {
                vc.showToast(commonLocalizable("only_support_choose_image"))
                return
              }
              if model.asset.mediaType == .image, models.count > avatarImageCountLimit {
                vc.showToast(String(format: commonLocalizable("image_count_over_limit"), avatarImageCountLimit))
                return
              }
              self?.uploadHeadImage(image: model.image)
            }
          }
        }

        let cancelAction = UIAlertAction(title: commonLocalizable("cancel"), style: .cancel) { _ in }

        showActionSheet([takingPicturesAction, photoAction, cancelAction])
      } else {
        showBottomAlert(self)
      }
    } else {
      if let callback = ChatUIConfig.shared.chatInputPhotoClick {
        let chatVC = self
        let takingPicturesAction = NECustomAlertAction(title: commonLocalizable("take_picture")) { [weak self] in
          self?.goCamera(chatVC, true)
        }

        let photoAction = NECustomAlertAction(title: commonLocalizable("select_from_album")) {
          // 自定义图片选择器
          let vc = self
          callback(self, .image, avatarImageCountLimit) { [weak self] models, isOriginal in
            for model in models {
              if model.asset.mediaType == .video {
                vc.showToast(commonLocalizable("only_support_choose_image"))
                return
              }
              if model.asset.mediaType == .image, models.count > avatarImageCountLimit {
                vc.showToast(String(format: commonLocalizable("image_count_over_limit"), avatarImageCountLimit))
                return
              }
              self?.uploadHeadImage(image: model.image)
            }
          }
        }

        showCustomActionSheet([takingPicturesAction, photoAction])
      } else {
        showCustomBottomAlert(self)
      }
    }
  }

  func didClickNickName(name: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .nickName)
    ctrl.contentText = name
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfNickName(editText) { [weak self] error in
        if let err = error {
          if err.code == antiErrorCode {
            self?.showToastInWindow(localizable("anti_error"))
            return
          }
          self?.showToastInWindow(localizable("setting_nickname_failure"))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didClickGender() {
    var gender = V2NIMGender.GENDER_UNKNOWN
    weak var weakSelf = self
    let block: ((_ value: NSInteger) -> Void) = {
      value in
      gender = value == 0 ? .GENDER_MALE : .GENDER_FEMALE

      weakSelf?.viewModel.updateSelfSex(gender) { [weak self] error in
        if let err = error {
          if err.code == antiErrorCode {
            self?.showToastInWindow(localizable("anti_error"))
            return
          }
          if error?.code == protocolSendFailed {
            self?.showToast(commonLocalizable("network_error"))
          } else {
            self?.showToast(localizable("change_gender_failure"))
          }
        }
      }
    }
    if NEStyleManager.instance.isNormalStyle() {
      showAlert(firstContent: localizable("male"),
                secondContent: localizable("female"),
                selectValue: block)
    } else {
      showCustomAlert(firstContent: localizable("male"),
                      secondContent: localizable("female"),
                      selectValue: block)
    }
  }

  func didClickBirthday(birth: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let selectDate = formatter.date(from: birth) {
      pickerView.picker.setDate(selectDate, animated: true)
    }
    showDatePicker()
  }

  func didClickMobile(mobile: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .cellphone)
    ctrl.contentText = mobile
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfMobile(editText) { [weak self] error in
        if let err = error {
          if err.code == antiErrorCode {
            self?.showToastInWindow(localizable("anti_error"))
            return
          }
          self?.showToastInWindow(localizable("change_phone_failure"))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^\w+@\w+\.[a-zA-Z]{2,}"#
    return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
  }

  func didClickEmail(email: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .email)
    ctrl.contentText = email
    weak var weakSelf = self
    ctrl.callBack = { editText in
      if editText.count > 0, weakSelf?.isValidEmail(editText) == false {
        weakSelf?.showToastInWindow(localizable("change_email_failure"))
        return
      }

      weakSelf?.viewModel.updateSelfEmail(editText) { [weak self] error in
        if let err = error {
          if err.code == antiErrorCode {
            self?.showToastInWindow(localizable("anti_error"))
            return
          }
          self?.showToastInWindow(localizable("change_email_failure"))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didClickSign(sign: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .specialSign)
    ctrl.contentText = sign
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfSign(editText) { [weak self] error in
        if let err = error {
          if err.code == antiErrorCode {
            self?.showToastInWindow(localizable("anti_error"))
            return
          }
          self?.showToastInWindow(localizable("change_sign_failure"))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didCopyAccount(account: String) {
    showToast(commonLocalizable("copy_success"))
    UIPasteboard.general.string = account
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  open func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionData.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }

  // MARK: - NEContactListener

  /// 好友信息缓存更新（包含好友信息和用户信息）
  /// - Parameter changeType: 操作类型
  /// - Parameter contacts: 好友列表
  open func onContactChange(_ changeType: NEContactChangeType, _ contacts: [NEUserWithFriend]) {
    for contact in contacts {
      if contact.user?.accountId == IMKitClient.instance.account() {
        viewModel.userInfo = contact
        viewModel.refreshData()
        tableView.reloadData()
      }
    }
  }
}
