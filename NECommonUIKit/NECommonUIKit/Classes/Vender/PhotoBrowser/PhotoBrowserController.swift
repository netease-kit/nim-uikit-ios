
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import Photos

@objcMembers
open class PhotoBrowserController: UIViewController {
  private let SystemNaviBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height + 24

  public lazy var toolsBar: BrowserToolsBar = {
    let bar = BrowserToolsBar()
    bar.delegate = self
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  public lazy var successView: ToastImageView = {
    let success = ToastImageView()
    success.frame = CGRect(x: 0, y: 0, width: 118, height: 120)
    success.contentLabel.text = commonLocalizable("save_system_album")
    return success
  }()

  var showView: PhotoBrowserBigImgBackView
  var number: Int
  public init(imgs: [UIImage], img: UIImage) {
    var number = 0
    _ = imgs.enumerated().map { index, urlStr in
      if urlStr == img {
        number = index
      }
    }
    self.number = number
    showView = PhotoBrowserBigImgBackView(imgArr: imgs, number: number)
    super.init(nibName: nil, bundle: nil)
  }

  public init(urls: [String], url: String) {
    var number = 0
    _ = urls.enumerated().map { index, urlStr in
      if urlStr == url {
        number = index
      }
    }
    self.number = number
    showView = PhotoBrowserBigImgBackView(urlArr: urls, number: number)
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    number = 0
    showView = PhotoBrowserBigImgBackView(imgArr: [], number: 0)
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    layoutViews()
    showView.transformAnimation()
  }

  func layoutViews() {
    view.addSubview(showView)

    showView.dismissCallBack = { [weak self] in
      self?.dismiss(animated: false, completion: nil)
    }

    showView.addSubview(toolsBar)
    NSLayoutConstraint.activate([
      toolsBar.leftAnchor.constraint(equalTo: showView.leftAnchor),
      toolsBar.rightAnchor.constraint(equalTo: showView.rightAnchor),
      toolsBar.heightAnchor.constraint(equalToConstant: 44.0),
      toolsBar.bottomAnchor.constraint(equalTo: showView.safeAreaLayoutGuide.bottomAnchor, constant: -27),
    ])
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
}

extension PhotoBrowserController: BrowserToolsBarDelegate {
  public func didCloseClick() {
    showView.dismissPhotoBrowser()
  }

  public func didPhotoClick() {
    let imagePickerVC = UIImagePickerController()
    imagePickerVC.allowsEditing = false
    imagePickerVC.sourceType = .photoLibrary
    present(imagePickerVC, animated: true)
  }

  public func didSaveClick() {
    weak var weakSelf = self
    NEAuthManager.requestPhotoAuthorization { granted in
      if granted == false {
        weakSelf?.showToast(commonLocalizable("jump_photo_setting"))
        return
      }
      DispatchQueue.main.async {
        weakSelf?.view.makeToastActivity(.center)
        weakSelf?.saveImage()
      }
    }
  }

  // 保存图片
  @objc func saveImage() {
    let index = showView.currentIndex()
    weak var weakSelf = self
    if showView.urlArray.count > 0 {
      let urlString = showView.urlArray[index]
      if let url = URL(string: urlString) {
        PHPhotoLibrary.shared().performChanges({
          if let data = try? Data(contentsOf: url) {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
          }
        }, completionHandler: { success, error in
          DispatchQueue.main.async {
            weakSelf?.view.hideToastActivity()
            if let err = error {
              weakSelf?.showToast(err.localizedDescription)
            } else {
              if let weak = weakSelf {
                weak.view.showToast(weak.successView, point: weak.view.center)
              }
            }
          }
        })
      } else {
        view.hideToastActivity()
      }
    } else {
      let img = showView.imgArray[index]
      UIImageWriteToSavedPhotosAlbum(
        img,
        self,
        #selector(save(image:didFinishSavingWithError:contextInfo:)),
        nil
      )
    }
  }

  @objc func save(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
    view.hideToastActivity()
    if let error = didFinishSavingWithError {
      showToast(error.localizedDescription)
    } else {
      view.showToast(successView, point: view.center)
    }
  }
}
