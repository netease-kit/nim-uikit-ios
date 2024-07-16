
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamAvatarViewController: NEBaseViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  public typealias SaveCompletion = () -> Void
  public var block: SaveCompletion?
  public var team: V2NIMTeam?
  public let repo = TeamRepo.shared

  /// 头像背景
  public let headerBackView = UIView()
  /// 相机提示图片
  public let photoImageView = UIImageView()
  /// 缺省背景
  public let defaultHeaderBackView = UIView()

  public let tagLabel = UILabel()

  public var iconUrls = TeamRouter.iconUrls

  public var viewModel = TeamAvatarViewModel()

  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.clipsToBounds = true
    header.isUserInteractionEnabled = true
    header.accessibilityIdentifier = "id.icon"
    return header
  }()

  public var headerUrl = ""

  /// 群头像点击按钮
  public lazy var clickButton: UIButton = {
    let clickButton = UIButton(type: .custom)
    clickButton.translatesAutoresizingMaskIntoConstraints = false
    clickButton.backgroundColor = .clear
    return clickButton
  }()

  public lazy var iconsCollectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 0
    flowLayout.minimumInteritemSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = false
    collectionView.clipsToBounds = false
    collectionView.isScrollEnabled = false
    return collectionView
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    weak var weakSelf = self
    viewModel.getCurrentUserTeamMember(team?.teamId) { error in
      weakSelf?.setupUI()
      if let err = error {
        weakSelf?.view.makeToast(err.localizedDescription)
      }
    }
  }

  /// UI 初始化
  open func setupUI() {
    title = localizable("modify_headImage")
    addRightAction(localizable("save"), #selector(savePhoto), self)
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(savePhoto))

    view.backgroundColor = .ne_lightBackgroundColor

    headerBackView.backgroundColor = .white
    headerBackView.clipsToBounds = true
    headerBackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBackView)

    /// 当前头像视图背景
    headerBackView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.centerXAnchor.constraint(equalTo: headerBackView.centerXAnchor),
      headerView.centerYAnchor.constraint(equalTo: headerBackView.centerYAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 80.0),
      headerView.widthAnchor.constraint(equalToConstant: 80.0),
    ])
    if let url = team?.avatar, !url.isEmpty {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerUrl = url
    }

    photoImageView.translatesAutoresizingMaskIntoConstraints = false
    photoImageView.image = coreLoader.loadImage("photo")
    photoImageView.accessibilityIdentifier = "id.camera"
    headerBackView.addSubview(photoImageView)

    headerBackView.addSubview(clickButton)
    clickButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
    NSLayoutConstraint.activate([
      clickButton.leftAnchor.constraint(equalTo: headerView.leftAnchor),
      clickButton.topAnchor.constraint(equalTo: headerView.topAnchor),
      clickButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
      clickButton.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: 10),
    ])

    defaultHeaderBackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(defaultHeaderBackView)
    defaultHeaderBackView.clipsToBounds = true
    defaultHeaderBackView.backgroundColor = .white

    tagLabel.translatesAutoresizingMaskIntoConstraints = false
    tagLabel.text = localizable("default_icon")
    tagLabel.font = NEConstant.defaultTextFont(16.0)
    tagLabel.textColor = NEConstant.hexRGB(0x333333)
    defaultHeaderBackView.addSubview(tagLabel)

    defaultHeaderBackView.addSubview(iconsCollectionView)

    for index in 0 ..< iconUrls.count {
      let url = iconUrls[index]
      if url == headerUrl {
        let indexPath = IndexPath(row: index, section: 0)
        iconsCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .right)
      }
    }

    /// 判断权限决定是否展示保存按钮
    if getChangePermission() == false {
      rightNavButton.isHidden = true
      navigationView.moreButton.isHidden = true
      photoImageView.isHidden = true
      defaultHeaderBackView.isHidden = true
    }
  }

  /// 获取当前是否有修改权限
  func getChangePermission() -> Bool {
    if let ownerId = team?.ownerAccountId, IMKitClient.instance.isMe(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .TEAM_UPDATE_INFO_MODE_ALL {
      return true
    }
    if let member = viewModel.currentTeamMember, member.memberRole == .TEAM_MEMBER_ROLE_MANAGER {
      return true
    }
    return false
  }

  open func uploadPhoto() {
    if getChangePermission() {
      showBottomAlert(self)
    }
  }

  /// 保存相册
  open func savePhoto() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }

    if let tid = team?.teamId {
      view.makeToastActivity(.center)
      weak var weakSelf = self
      weakSelf?.viewModel.updateTeamAvatar(headerUrl, tid, nil) { error in
        NEALog.infoLog(ModuleName + " " + self.className(), desc: #function + "CALLBACK " + (error?.localizedDescription ?? "no error"))
        weakSelf?.view.hideToastActivity()
        if let err = error {
          if err.code == protocolSendFailed {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else if error?.code == noPermissionOperationCode {
            weakSelf?.showToast(localizable("no_permission_tip"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          if let completion = weakSelf?.block {
            completion()
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  open func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {
    5
  }

  open func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    UICollectionViewCell()
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    .zero
  }

  open func collectionView(_ collectionView: UICollectionView,
                           didSelectItemAt indexPath: IndexPath) {
    if iconUrls.count > indexPath.row {
      headerUrl = iconUrls[indexPath.row]
      headerView.sd_setImage(with: URL(string: headerUrl), completed: nil)
    }
  }

  open func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController
                                    .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    picker.dismiss(animated: true, completion: nil)
  }

  /// 上传头像
  /// - Parameter image: 头像
  open func uploadHeadImage(image: UIImage) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData?,
       var filePath = NEPathUtils.getDirectoryForDocuments(dir: "\(imkitDir)image/") {
      filePath += "\(team?.teamId ?? "team")_avatar.jpg"
      let succcess = imageData.write(toFile: filePath, atomically: true)
      if succcess {
        let fileTask = viewModel.createTask(filePath)
        viewModel.uploadImageFile(fileTask, nil) { urlString, error in
          if error == nil {
            // 显示设置的照片
            weakSelf?.headerView.image = image
            if let url = urlString {
              weakSelf?.headerUrl = url
            }
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
