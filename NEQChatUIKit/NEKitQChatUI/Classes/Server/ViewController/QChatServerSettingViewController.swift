
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitCoreIM
import NIMSDK

typealias SaveSuccessBlock = (_ server: QChatServer?) -> Void

public class QChatServerSettingViewController: NEBaseTableViewController,UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate,UINavigationControllerDelegate {
  let viewModel = SettingViewModel()
  var server: QChatServer?

  var headerImageUrl: String?

  var headerImage: NEUserHeaderView?

  lazy var serverNameInput: UITextField = getInput()

  lazy var serverThemeInput: UITextField = getInput()

  var topicInput: UITextField?

  lazy var serverName: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.textColor = .ne_darkText
    return label
  }()

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = false
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    NELog.infoLog(className(), desc: "server id : \(server?.serverId ?? 0)")

    setupUI()
    addRightAction(localizable("save"), #selector(saveClick), self)
  }

  func setupUI() {
    title = localizable("qchat_setting")
    view.backgroundColor = .ne_backcolor
    setupTable()
    tableView.bounces = false
    tableView.tableHeaderView = headerView()
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatDestructiveCell.self,
      forCellReuseIdentifier: "\(QChatDestructiveCell.self)"
    )
    tableView.delegate = self
    tableView.dataSource = self
  }

  func headerView() -> UIView {
    let headerBack = UIView()
    headerBack.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 334)
    headerBack.backgroundColor = .clear

    let cornerView = UIView()
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    headerBack.addSubview(cornerView)
    NSLayoutConstraint.activate([
      cornerView.topAnchor.constraint(equalTo: headerBack.topAnchor, constant: 22),
      cornerView.leftAnchor.constraint(equalTo: headerBack.leftAnchor, constant: 20),
      cornerView.rightAnchor.constraint(equalTo: headerBack.rightAnchor, constant: -20),
      cornerView.heightAnchor.constraint(equalToConstant: 98),
    ])
    cornerView.clipsToBounds = true
    cornerView.layer.cornerRadius = 8
    cornerView.backgroundColor = .white

    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    cornerView.addSubview(header)
    NSLayoutConstraint.activate([
      header.widthAnchor.constraint(equalToConstant: 60),
      header.heightAnchor.constraint(equalToConstant: 60),
      header.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      header.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
    ])
    header.isUserInteractionEnabled = true
    header.clipsToBounds = true
    header.backgroundColor = UIColor.colorWithNumber(number: server?.serverId)
    header.layer.cornerRadius = 30
    headerImage = header
    if let icon = server?.icon {
      header.sd_setImage(with: URL(string: icon), completed: nil)
    } else {
      if let name = server?.name {
        header.setTitle(name)
      }
    }

    let cameraBtn = ExpandButton()
    cornerView.addSubview(cameraBtn)
    cameraBtn.translatesAutoresizingMaskIntoConstraints = false
    cameraBtn.backgroundColor = .ne_backcolor
    NSLayoutConstraint.activate([
      cameraBtn.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 58),
      cameraBtn.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 58),
      cameraBtn.widthAnchor.constraint(equalToConstant: 26),
      cameraBtn.heightAnchor.constraint(equalToConstant: 26),
    ])
    cameraBtn.layer.cornerRadius = 12
    cameraBtn.clipsToBounds = true
    cameraBtn.layer.borderColor = UIColor.white.cgColor
    cameraBtn.layer.borderWidth = 2
    cameraBtn.addTarget(self, action: #selector(cameraClick), for: .touchUpInside)

    let camera = UIImageView()
    camera.translatesAutoresizingMaskIntoConstraints = false
    cornerView.addSubview(camera)
    camera.backgroundColor = .clear
    camera.image = coreLoader.loadImage("camera")
    NSLayoutConstraint.activate([
      camera.centerXAnchor.constraint(equalTo: cameraBtn.centerXAnchor),
      camera.centerYAnchor.constraint(equalTo: cameraBtn.centerYAnchor, constant: -2),
    ])

    cornerView.addSubview(serverName)
    NSLayoutConstraint.activate([
      serverName.leftAnchor.constraint(equalTo: header.rightAnchor, constant: 16),
      serverName.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -16),
      serverName.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 30),
    ])
    serverName.text = server?.name

    let account = UILabel()
    account.translatesAutoresizingMaskIntoConstraints = false
    account.textColor = UIColor.ne_emptyTitleColor
    account.font = UIFont.systemFont(ofSize: 12)
    cornerView.addSubview(account)
    NSLayoutConstraint.activate([
      account.leftAnchor.constraint(equalTo: serverName.leftAnchor),
      account.rightAnchor.constraint(equalTo: serverName.rightAnchor),
      account.topAnchor.constraint(equalTo: serverName.bottomAnchor, constant: 6),
    ])
    account.text = "ID: \(server?.serverId ?? 0)"

    addInputView(headerBack, cornerView)

    return headerBack
  }

  func addInputView(_ back: UIView, _ topView: UIView) {
    let serverNameLabel = getTagLabel()
    back.addSubview(serverNameLabel)
    NSLayoutConstraint.activate([
      serverNameLabel.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 33),
      serverNameLabel.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 16.0),
    ])
    serverNameLabel.text = localizable("qchat_server_name")

    back.addSubview(serverNameInput)
    NSLayoutConstraint.activate([
      serverNameInput.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 20),
      serverNameInput.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -20),
      serverNameInput.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 38),
      serverNameInput.heightAnchor.constraint(equalToConstant: 50),
    ])
    serverNameInput.placeholder = "输入名称"
    serverNameInput.tag = 50
    if let name = server?.name {
      serverNameInput.text = name
    }

    let serverThemeLabel = getTagLabel()
    back.addSubview(serverThemeLabel)
    NSLayoutConstraint.activate([
      serverThemeLabel.leftAnchor.constraint(equalTo: serverNameLabel.leftAnchor),
      serverThemeLabel.topAnchor.constraint(
        equalTo: serverNameInput.bottomAnchor,
        constant: 16
      ),
    ])
    serverThemeLabel.text = localizable("qchat_server_theme")

    back.addSubview(serverThemeInput)
    NSLayoutConstraint.activate([
      serverThemeInput.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 20),
      serverThemeInput.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -20),
      serverThemeInput.topAnchor.constraint(
        equalTo: serverNameInput.bottomAnchor,
        constant: 38
      ),
      serverThemeInput.heightAnchor.constraint(equalToConstant: 50),
    ])
    serverThemeInput.placeholder = localizable("qchat_please_input_topic")
    if let custom = server?.custom, let dic = getDictionaryFromJSONString(custom),
       let topic = dic["topic"] as? String {
      serverThemeInput.text = topic
    }
    serverThemeInput.tag = 64

    let permissionLabel = getTagLabel()
    back.addSubview(permissionLabel)
    NSLayoutConstraint.activate([
      permissionLabel.leftAnchor.constraint(equalTo: serverThemeLabel.leftAnchor),
      permissionLabel.topAnchor.constraint(
        equalTo: serverThemeInput.bottomAnchor,
        constant: 16
      ),
    ])
    permissionLabel.text = localizable("qchat_permisssion")
  }

  func getTagLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor(hexString: "666666")
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .left
    return label
  }

  func getInput() -> UITextField {
    let textField = UITextField()
    textField.backgroundColor = .white
    textField.clipsToBounds = true
    textField.layer.cornerRadius = 8
    textField.font = UIFont.systemFont(ofSize: 16.0)
    textField.translatesAutoresizingMaskIntoConstraints = false
    let leftSpace = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
    textField.leftView = leftSpace
    textField.leftViewMode = .always
    textField.delegate = self
    return textField
  }
    
    // MARK: action
    @objc func cameraClick() {
      // print("camera click")
      showBottomAlert(self)
    }

    @objc func saveClick() {
      print("save click")

      var name = ""

      if let currentName = serverNameInput.text, currentName.count > 0 {
        name = currentName
      } else if let originServerName = server?.name, originServerName.count > 0 {
        name = originServerName
      }

      if name.count <= 0 {
        showToast(localizable("qchat_not_empty_servername"))
        return
      }

      if let icon = headerImageUrl {
        server?.icon = icon
      }

      var serverParam = UpdateServerParam(name: name, icon: headerImageUrl)

      guard let sid = server?.serverId else {
        showToast("服务器id不能为空")
        return
      }
      serverParam.serverId = sid

      if let topic = serverThemeInput.text, topic.count > 0 {
        serverParam.custom = getJSONStringFromDictionary(["topic": topic])
      }
      weak var weakSelf = self

      view.makeToastActivity(.center)
      print("update param : ", serverParam)
      QChatServerProvider.shared.updateServer(serverParam) { error in
        print("update finish : ", error as Any)
        weakSelf?.view.hideToastActivity()
        if let err = error {
          weakSelf?.showToast(err.localizedDescription)
        } else {
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }

    func leaveServer() {
      if let serverid = server?.serverId {
        weak var weakSelf = self
        view.makeToastActivity(.center)
        let className = className()
        viewModel.repo.leaveServer(serverid) { error in
          weakSelf?.view.hideToastActivity()
          if let err = error {
            NELog.errorLog(className, desc: "leave server error : \(err)")
            weakSelf?.view.makeToast(err.localizedDescription)
          } else {
            weakSelf?.navigationController?.popViewController(animated: true)
          }
        }
      }
    }

    func deleteServer() {
      if let serverid = server?.serverId {
        weak var weakSelf = self
        view.makeToastActivity(.center)
        QChatServerProvider.shared.deleteServer(serverid) { error in
          print("delete result : ", error as Any)
          weakSelf?.view.hideToastActivity()
          if let err = error {
            weakSelf?.view.makeToast(err.localizedDescription)
          } else {
            weakSelf?.navigationController?.popViewController(animated: true)
          }
        }
      }
    }
    //MARK: UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
      let l = textField.tag
      let text = "\(textField.text ?? "")\(string)"
      print("count : ", text.count)
      if text.count > l {
        return false
      }
      return true
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      print("count section : ", section)
      if section == 0 {
        return viewModel.permissions.count
      } else if section == 1 {
        return 1
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
        let textCell: QChatTextArrowCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatTextArrowCell.self)",
          for: indexPath
        ) as! QChatTextArrowCell
        let model = viewModel.permissions[indexPath.row]
        textCell.titleLabel.text = model.title
        textCell.backgroundColor = .clear
        textCell.cornerType = model.cornerType
        return textCell
      } else if indexPath.section == 1 {
        let destructiveCell: QChatDestructiveCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatDestructiveCell.self)",
          for: indexPath
        ) as! QChatDestructiveCell

        destructiveCell.redTextLabel
          .text = isMyServer() ? localizable("qchat_delete_server") :
          localizable("qchat_leave_server")
        destructiveCell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
          .union(CornerType.topLeft).union(CornerType.topRight)
        return destructiveCell
      }

      return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if indexPath.section == 0 {
        if indexPath.row == 1 {
          let idGroupController = QChatIdGroupViewController()
          idGroupController.serverid = server?.serverId
          if let owner = server?.owner, owner == IMKitLoginManager.instance.imAccid {
            idGroupController.isOwner = true
          }
          navigationController?.pushViewController(idGroupController, animated: true)

        } else if indexPath.row == 0 {
          let memberCtrl = MemberListViewController()
          memberCtrl.serverId = server?.serverId
          navigationController?.pushViewController(memberCtrl, animated: true)
        }

      } else if indexPath.section == 1 {
        print("click delete")
        weak var weakSelf = self
        if isMyServer() == true {
          showAlert(message: "确定删除当前服务器?") {
            weakSelf?.deleteServer()
          }
        } else {
          showAlert(message: "确定退出当前服务器?") {
            weakSelf?.leaveServer()
          }
        }
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      if indexPath.section == 0 {
        return 48
      } else if indexPath.section == 1 {
        return 40
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          viewForHeaderInSection section: Int) -> UIView? {
      if section == 1 {
        return UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 24))
      }
      return nil
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      if section == 1 {
        return 24
      }
      return 0
    }

    public func tableView(_ tableView: UITableView,
                          heightForFooterInSection section: Int) -> CGFloat {
      0
    }

    func isMyServer() -> Bool {
      if let owner = server?.owner {
        let accid = IMKitLoginManager.instance.imAccid
        if owner == accid {
          return true
        }
      }
      return false
    }
    
    //UINavigationControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController
                                 .InfoKey: Any]) {
      let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
      uploadHeadImage(image: image)
      picker.dismiss(animated: true, completion: nil)
    }

    public func uploadHeadImage(image: UIImage) {
      view.makeToastActivity(.center)
      if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
        let filePath = NSHomeDirectory().appending("/Documents/")
          .appending(IMKitLoginManager.instance.imAccid)
        let succcess = imageData.write(toFile: filePath, atomically: true)
        weak var weakSelf = self
        if succcess {
          NIMSDK.shared().resourceManager
            .upload(filePath, progress: nil) { urlString, error in
              if error == nil {
                // 显示设置的照片
                weakSelf?.headerImage?.image = image
                weakSelf?.headerImageUrl = urlString
                weakSelf?.headerImage?.titleLabel.isHidden = true
                print("upload image success")
              } else {
                print("upload image failed,error = \(error!)")
              }
              weakSelf?.view.hideToastActivity()
            }
        }
      }
    }
}



