
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCommonUI
import NIMSDK
import NEKitTeam

public class TeamAvatarViewController: NEBaseViewController,UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate  {
  typealias SaveCompletion = () -> Void

  var block: SaveCompletion?

  var team: NIMTeam?

  let repo = TeamRepo()

  lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.clipsToBounds = true
    header.layer.cornerRadius = 40
    header.isUserInteractionEnabled = true
    return header
  }()

  var headerUrl = ""

  lazy var iconCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .horizontal
    flow.minimumLineSpacing = 0
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    collection.clipsToBounds = false
    collection.isScrollEnabled = false
    return collection
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    title = "修改头像"
    addRightAction("保存", #selector(savePhoto), self)

    view.backgroundColor = NEConstant.hexRGB(0xF1F1F6)
    let headerBack = UIView()
    headerBack.backgroundColor = .white
    headerBack.clipsToBounds = true
    headerBack.layer.cornerRadius = 8.0
    headerBack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerBack)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        headerBack.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 12.0
        ),
        headerBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        headerBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        headerBack.heightAnchor.constraint(equalToConstant: 128.0),
      ])
    } else {
      NSLayoutConstraint.activate([
        headerBack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.0),
        headerBack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
        headerBack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        headerBack.heightAnchor.constraint(equalToConstant: 128.0),
      ])
    }

    headerBack.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.centerXAnchor.constraint(equalTo: headerBack.centerXAnchor),
      headerView.centerYAnchor.constraint(equalTo: headerBack.centerYAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 80.0),
      headerView.widthAnchor.constraint(equalToConstant: 80.0),
    ])
    if let url = team?.avatarUrl {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerUrl = url
    }

    let photoImage = UIImageView()
    photoImage.translatesAutoresizingMaskIntoConstraints = false
    headerBack.addSubview(photoImage)
    NSLayoutConstraint.activate([
      photoImage.rightAnchor.constraint(equalTo: headerView.rightAnchor),
      photoImage.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
    ])
    photoImage.image = coreLoader.loadImage("photo")

    let gesture = UITapGestureRecognizer()
    headerView.addGestureRecognizer(gesture)
    gesture.addTarget(self, action: #selector(uploadPhoto))

    let defaultHeaderBack = UIView()
    defaultHeaderBack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(defaultHeaderBack)
    defaultHeaderBack.clipsToBounds = true
    defaultHeaderBack.layer.cornerRadius = 8.0
    defaultHeaderBack.backgroundColor = .white
    NSLayoutConstraint.activate([
      defaultHeaderBack.leftAnchor.constraint(equalTo: headerBack.leftAnchor),
      defaultHeaderBack.rightAnchor.constraint(equalTo: headerBack.rightAnchor),
      defaultHeaderBack.topAnchor.constraint(
        equalTo: headerBack.bottomAnchor,
        constant: 12.0
      ),
      defaultHeaderBack.heightAnchor.constraint(equalToConstant: 114.0),
    ])

    let tag = UILabel()
    tag.translatesAutoresizingMaskIntoConstraints = false
    tag.text = localizable("default_icon")
    tag.font = NEConstant.defaultTextFont(16.0)
    tag.textColor = NEConstant.hexRGB(0x333333)
    defaultHeaderBack.addSubview(tag)
    NSLayoutConstraint.activate([
      tag.leftAnchor.constraint(equalTo: defaultHeaderBack.leftAnchor, constant: 16.0),
      tag.topAnchor.constraint(equalTo: defaultHeaderBack.topAnchor, constant: 15.0),
    ])

    defaultHeaderBack.addSubview(iconCollection)
    iconCollection.register(
      TeamDefaultIconCell.self,
      forCellWithReuseIdentifier: "\(TeamDefaultIconCell.self)"
    )
    NSLayoutConstraint.activate([
      iconCollection.topAnchor.constraint(equalTo: tag.bottomAnchor, constant: 16.0),
      iconCollection.leftAnchor.constraint(
        equalTo: defaultHeaderBack.leftAnchor,
        constant: 18
      ),
      iconCollection.rightAnchor.constraint(
        equalTo: defaultHeaderBack.rightAnchor,
        constant: -18.0
      ),
      iconCollection.heightAnchor.constraint(equalToConstant: 48.0),
    ])

    for index in 0 ..< TeamRouter.iconUrls.count {
      let url = TeamRouter.iconUrls[index]
      if url == headerUrl {
        let indexPath = IndexPath(row: index, section: 0)
        iconCollection.selectItem(at: indexPath, animated: false, scrollPosition: .right)
      }
    }

    if changePermission() == false {
      rightNavBtn.isHidden = true
    }
  }

  func changePermission() -> Bool {
    if let type = team?.type, type == .normal {
      return true
    }
    if let ownerId = team?.owner, IMKitLoginManager.instance.isMySelf(ownerId) {
      return true
    }
    if let mode = team?.updateInfoMode, mode == .all {
      return true
    }
    return false
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
        //MARK: objc 方法
    
    @objc func uploadPhoto() {
      print("upload photo")
      showBottomAlert(self)
    }

    @objc func savePhoto() {
      print("save photo")
      if let tid = team?.teamId {
        view.makeToastActivity(.center)
        weak var weakSelf = self

        repo.fetchNOSURL(url: headerUrl) { error, urlStr in
          if error == nil {
            weakSelf?.repo.updateTeamIcon(urlStr ?? "", tid) { error in
              weakSelf?.view.hideToastActivity()
              if let err = error {
                weakSelf?.showToast(err.localizedDescription)
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
      }
    }
    
    //MAKR: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
      5
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      if let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "\(TeamDefaultIconCell.self)",
        for: indexPath
      ) as? TeamDefaultIconCell {
        cell.iconImage.image = coreLoader.loadImage("icon_\(indexPath.row)")

        return cell
      }
      return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
      let space = (view.width - 297.0) / 4.0
      print("mini inter : ", space)
      return space
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
      if TeamRouter.iconUrls.count > indexPath.row {
        headerUrl = TeamRouter.iconUrls[indexPath.row]
        // headerView.image = coreLoader.loadImage("icon_\(indexPath.row)")
        headerView.sd_setImage(with: URL(string: headerUrl), completed: nil)
      }
    }
    
    //MARK: UINavigationControllerDelegate
    
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

