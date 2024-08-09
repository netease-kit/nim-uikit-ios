
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
  public var team: NIMTeam?
  public let repo = TeamRepo.shared

  public let headerBack = UIView()
  public let photoImage = UIImageView()
  public let defaultHeaderBack = UIView()
  public let tag = UILabel()
  public var iconUrls = TeamRouter.iconUrls

  public var viewmodel = TeamAvatarViewModel()

  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.clipsToBounds = true
    header.isUserInteractionEnabled = true
    header.accessibilityIdentifier = "id.icon"
    return header
  }()

  public var headerUrl = ""

  public lazy var iconCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .horizontal
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    collection.showsVerticalScrollIndicator = false
    collection.clipsToBounds = false
    collection.isScrollEnabled = false
    return collection
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.getCurrentUserTeamMember(team?.teamId)
    setupUI()
  }

  open func setupUI() {
    title = localizable("modify_headImage")
    addRightAction(localizable("save"), #selector(savePhoto), self)
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(savePhoto))

    view.backgroundColor = .ne_lightBackgroundColor

    headerBack.backgroundColor = .white
    headerBack.clipsToBounds = true
    headerBack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBack)

    headerBack.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.centerXAnchor.constraint(equalTo: headerBack.centerXAnchor),
      headerView.centerYAnchor.constraint(equalTo: headerBack.centerYAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 80.0),
      headerView.widthAnchor.constraint(equalToConstant: 80.0),
    ])
    if let url = team?.avatarUrl, !url.isEmpty {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerUrl = url
    }

    photoImage.translatesAutoresizingMaskIntoConstraints = false
    photoImage.image = coreLoader.loadImage("photo")
    photoImage.accessibilityIdentifier = "id.camera"
    headerBack.addSubview(photoImage)

    let gesture = UITapGestureRecognizer()
    headerView.addGestureRecognizer(gesture)
    gesture.addTarget(self, action: #selector(uploadPhoto))

    defaultHeaderBack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(defaultHeaderBack)
    defaultHeaderBack.clipsToBounds = true
    defaultHeaderBack.backgroundColor = .white

    tag.translatesAutoresizingMaskIntoConstraints = false
    tag.text = localizable("default_icon")
    tag.font = NEConstant.defaultTextFont(16.0)
    tag.textColor = NEConstant.hexRGB(0x333333)
    defaultHeaderBack.addSubview(tag)

    defaultHeaderBack.addSubview(iconCollection)

    for index in 0 ..< iconUrls.count {
      let url = iconUrls[index]
      if url == headerUrl {
        let indexPath = IndexPath(row: index, section: 0)
        iconCollection.selectItem(at: indexPath, animated: false, scrollPosition: .right)
      }
    }

    if changePermission() == false {
      rightNavBtn.isHidden = true
      navigationView.moreButton.isHidden = true
      photoImage.isHidden = true
      defaultHeaderBack.isHidden = true
    }
  }

  func changePermission() -> Bool {
    if let type = team?.type, type == .normal {
      return true
    }
    if let ownerId = team?.owner, IMKitClient.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    if let member = viewmodel.currentTeamMember, member.type == .manager {
      return true
    }
    return false
  }

  // MARK: objc 方法

  open func uploadPhoto() {
    if changePermission() {
      showBottomAlert(self)
    }
  }

  open func savePhoto() {
    print("save photo")
    if let tid = team?.teamId {
      view.makeToastActivity(.center)
      weak var weakSelf = self
      weakSelf?.repo.updateTeamIcon(headerUrl, tid) { error in
        NELog.infoLog(ModuleName + " " + self.className(), desc: #function + "CALLBACK " + (error?.localizedDescription ?? "no error"))
        weakSelf?.view.hideToastActivity()
        if let err = error as? NSError {
          if err.code == noNetworkCode {
            weakSelf?.showToast(commonLocalizable("network_error"))
          } else {
            weakSelf?.showToast(localizable("failed_operation"))
          }
        } else {
          weakSelf?.team?.avatarUrl = weakSelf?.headerUrl
          if let completion = weakSelf?.block {
            completion()
          }
          weakSelf?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  // MAKR: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
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
      // headerView.image = coreLoader.loadImage("icon_\(indexPath.row)")
      headerView.sd_setImage(with: URL(string: headerUrl), completed: nil)
    }
  }

  // MARK: UINavigationControllerDelegate

  open func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController
                                    .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    picker.dismiss(animated: true, completion: nil)
  }

  open func uploadHeadImage(image: UIImage) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }
    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
      let filePath = NSHomeDirectory().appending("/Documents/")
        .appending(IMKitClient.instance.imAccid())
      let succcess = imageData.write(toFile: filePath, atomically: true)
      if succcess {
        NIMSDK.shared().resourceManager
          .upload(filePath, progress: nil) { urlString, error in
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
