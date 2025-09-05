
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import NECommonKit
import Photos
import PhotosUI
import UIKit

public typealias AlertCallBack = () -> Void

public extension UIViewController {
  var rightNavButton: ExpandButton {
    get {
      if let button = objc_getAssociatedObject(
        self,
        UnsafeRawPointer(bitPattern: "rightNavButton".hashValue)!
      ) as? ExpandButton {
        return button
      } else {
        let button = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        self.rightNavButton = button
        button.setTitleColor(UIColor.ne_normalTheme, for: .normal)
        button.titleLabel?.font = NEConstant.defaultTextFont(16)
        return button
      }
    }

    set {
      objc_setAssociatedObject(
        self,
        UnsafeRawPointer(bitPattern: "rightNavButton".hashValue)!,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  var leftNavButton: ExpandButton {
    get {
      if let button = objc_getAssociatedObject(
        self,
        UnsafeRawPointer(bitPattern: "leftNavButton".hashValue)!
      ) as? ExpandButton {
        return button
      } else {
        let button = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        self.leftNavButton = button
        button.setTitleColor(.ne_darkText, for: .normal)
        button.titleLabel?.font = NEConstant.defaultTextFont(16)
        return button
      }
    }
    set {
      objc_setAssociatedObject(
        self,
        UnsafeRawPointer(bitPattern: "leftNavButton".hashValue)!,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  func addLeftAction(_ image: UIImage?, _ selector: Selector, _ target: Any?, _ tintColor: UIColor = .ne_greyText) {
    let leftItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: target,
      action: selector
    )
    leftItem.tintColor = tintColor
    navigationItem.leftBarButtonItem = leftItem
  }

  func addLeftAction(_ title: String, _ selector: Selector, _ target: Any?, _ tintColor: UIColor = UIColor.ne_normalTheme) {
    leftNavButton.addTarget(target, action: selector, for: .touchUpInside)
    leftNavButton.setTitle(title, for: .normal)
    let leftItem = UIBarButtonItem(customView: leftNavButton)
    leftItem.tintColor = tintColor
    navigationItem.leftBarButtonItem = leftItem
  }

  func addRightAction(_ image: UIImage?, _ selector: Selector, _ target: Any?, _ tintColor: UIColor = .ne_greyText) {
    let rightItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: target,
      action: selector
    )
    rightItem.tintColor = tintColor
    navigationItem.rightBarButtonItem = rightItem
  }

  func addRightAction(_ title: String, _ selector: Selector, _ target: Any?, _ tintColor: UIColor = UIColor.ne_normalTheme) {
    rightNavButton.addTarget(target, action: selector, for: .touchUpInside)
    rightNavButton.setTitle(title, for: .normal)
    let rightItem = UIBarButtonItem(customView: rightNavButton)
    rightItem.tintColor = tintColor
    navigationItem.rightBarButtonItem = rightItem
  }

  func showAlert(title: String = commonLocalizable("tip"), message: String?,
                 sureText: String = commonLocalizable("sure"),
                 cancelText: String = commonLocalizable("cancel"),
                 sureTextColor: UIColor? = nil,
                 canceTextColor: UIColor? = nil,
                 sureBack: @escaping AlertCallBack,
                 cancelBack: AlertCallBack? = nil) {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    alertController.view.findLabel(with: title)?.accessibilityIdentifier = "id.dialogTitle"
    alertController.view.findLabel(with: message)?.accessibilityIdentifier = "id.dialogContent"

    let cancelAction = UIAlertAction(title: cancelText, style: .default) { action in
      if let block = cancelBack {
        block()
      }
    }
    cancelAction.accessibilityIdentifier = "id.dialogNegative"
    alertController.addAction(cancelAction)

    let sureAction = UIAlertAction(title: sureText, style: .default) { action in
      sureBack()
    }
    sureAction.accessibilityIdentifier = "id.dialogPositive"
    alertController.addAction(sureAction)

    if let sureColor = sureTextColor {
      sureAction.setValue(sureColor, forKey: "titleTextColor")
    }
    if let cancelColor = canceTextColor {
      cancelAction.setValue(cancelColor, forKey: "titleTextColor")
    }

    present(alertController, animated: true, completion: nil)
  }

  func showSingleAlert(title: String = commonLocalizable("tip"), message: String?,
                       sureText: String = commonLocalizable("sure"),
                       _ sureBack: @escaping AlertCallBack) {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    alertController.view.findLabel(with: title)?.accessibilityIdentifier = "id.dialogTitle"
    alertController.view.findLabel(with: message)?.accessibilityIdentifier = "id.dialogContent"

    let sureAction = UIAlertAction(title: sureText, style: .default) { action in
      sureBack()
    }
    sureAction.accessibilityIdentifier = "id.dialogPositive"
    alertController.addAction(sureAction)
    present(alertController, animated: true, completion: nil)
  }

  func showToast(_ message: String, _ position: ToastPosition = .center) {
    UIApplication.shared.keyWindow?.endEditing(true)
    view.makeToast(message, duration: 2, position: position)
  }

  func showToastInWindow(_ message: String) {
    UIApplication.shared.keyWindow?.endEditing(true)
    UIApplication.shared.keyWindow?.makeToast(message, duration: 2, position: .center)
  }

  func showActionSheet(_ actions: [UIAlertAction]) {
    let alertController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    for (index, action) in actions.enumerated() {
      action.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
      action.accessibilityIdentifier = "id.action\(index + 1)"
      alertController.addAction(action)
    }

    alertController.fixIpadAction()
    present(alertController, animated: true, completion: nil)
  }

  func showCustomActionSheet(_ actions: [NECustomAlertAction]) {
    let alertController = NECustomActionSheetController()
    for (index, action) in actions.enumerated() {
      action.contentText.accessibilityIdentifier = "id.action\(index + 1)"
    }

    for action in actions.reversed() {
      alertController.addAction(action)
    }
    alertController.cancelAction.contentText.accessibilityIdentifier = "id.action\(actions.count + 1)"
    present(alertController, animated: true, completion: nil)
  }

  func showBottomVideoAction(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate,
    _ editing: Bool = true) {
    weak var weakSelf = self

    let alertController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let takingPicturesAction = UIAlertAction(title: commonLocalizable("take_picture"),
                                             style: .default) { action in
      weakSelf?.goCamera(delegate, editing, false)
    }
    takingPicturesAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    takingPicturesAction.accessibilityIdentifier = "id.action1"

    let localPhotoAction = UIAlertAction(title: commonLocalizable("camera"),
                                         style: .default) { action in
      weakSelf?.goCamera(delegate, editing, true)
    }
    localPhotoAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    localPhotoAction.accessibilityIdentifier = "id.action2"

    alertController.addAction(cancelAction)
    alertController.addAction(takingPicturesAction)
    alertController.addAction(localPhotoAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: nil)
  }

  func showCustomBottomVideoAction(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate,
    _ editing: Bool = true) {
    weak var weakSelf = self

    let takingPicturesAction = NECustomAlertAction(title: commonLocalizable("camera")) {
      weakSelf?.goCamera(delegate, editing, true)
    }

    let localPhotoAction = NECustomAlertAction(title: commonLocalizable("take_picture")) {
      weakSelf?.goCamera(delegate, editing, false)
    }

    showCustomActionSheet([localPhotoAction, takingPicturesAction])
  }

  func showBottomFileAction(_ delegate: UIImagePickerControllerDelegate & UIDocumentPickerDelegate &
    UINavigationControllerDelegate) {
    let alertController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let selectAlbumAction = UIAlertAction(title: commonLocalizable("select_from_album"),
                                          style: .default) { [weak self] action in
      self?.goPhotoAlbumWithVideo(delegate)
    }
    selectAlbumAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    selectAlbumAction.accessibilityIdentifier = "id.action2"

    let selectICloudAction = UIAlertAction(title: commonLocalizable("select_from_icloud"),
                                           style: .default) { [weak self] action in
      self?.goICloudDocument(delegate)
    }
    selectICloudAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    selectICloudAction.accessibilityIdentifier = "id.action1"

    alertController.addAction(cancelAction)
    alertController.addAction(selectICloudAction)
    alertController.addAction(selectAlbumAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: nil)
  }

  func showCustomBottomFileAction(_ delegate: UIImagePickerControllerDelegate & UIDocumentPickerDelegate &
    UINavigationControllerDelegate) {
    let selectAlbumAction = NECustomAlertAction(title: commonLocalizable("select_from_album")) { [weak self] in
      self?.goPhotoAlbumWithVideo(delegate)
    }

    let selectICloudAction = NECustomAlertAction(title: commonLocalizable("select_from_icloud")) { [weak self] in
      self?.goICloudDocument(delegate)
    }

    showCustomActionSheet([selectICloudAction, selectAlbumAction])
  }

  func showBottomTelAction(_ url: URL) {
    let tel = url.absoluteString.replacingOccurrences(of: "tel:", with: "")
    let title = String(format: commonLocalizable("detect_tel_title"), tel)
    let alertController = UIAlertController(
      title: title,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let callAction = UIAlertAction(title: commonLocalizable("detect_tel_call"),
                                   style: .default) { action in
      UIApplication.shared.open(url)
    }
    callAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    callAction.accessibilityIdentifier = "id.action2"

    let copyAction = UIAlertAction(title: commonLocalizable("detect_tel_copy"),
                                   style: .default) { [weak self] action in
      UIPasteboard.general.string = tel
      self?.showToast(commonLocalizable("copy_success"))
    }
    copyAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    copyAction.accessibilityIdentifier = "id.action1"

    alertController.addAction(cancelAction)
    alertController.addAction(callAction)
    alertController.addAction(copyAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: nil)
  }

  func showCustomBottomTelAction(_ url: URL) {
    let tel = url.absoluteString.replacingOccurrences(of: "tel:", with: "")
    let titleAction = NECustomAlertAction(title: String(format: commonLocalizable("detect_tel_title"), tel)) {}
    titleAction.contentText.font = .systemFont(ofSize: 13)
    titleAction.contentText.textColor = .ne_lightText

    let callAction = NECustomAlertAction(title: commonLocalizable("detect_tel_call")) {
      UIApplication.shared.open(url)
    }

    let copyAction = NECustomAlertAction(title: commonLocalizable("detect_tel_copy")) { [weak self] in
      UIPasteboard.general.string = tel
      self?.showToast(commonLocalizable("copy_success"))
    }

    showCustomActionSheet([titleAction, callAction, copyAction])
  }

  func showBottomMailAction(_ url: URL) {
    let tel = url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
    let title = String(format: commonLocalizable("detect_mailto_title"), tel)
    let alertController = UIAlertController(
      title: title,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let sendAction = UIAlertAction(title: commonLocalizable("detect_mailto_send"),
                                   style: .default) { action in
      UIApplication.shared.open(url)
    }
    sendAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    sendAction.accessibilityIdentifier = "id.action2"

    let copyAction = UIAlertAction(title: commonLocalizable("detect_mailto_copy"),
                                   style: .default) { [weak self] action in
      UIPasteboard.general.string = tel
      self?.showToast(commonLocalizable("copy_success"))
    }
    copyAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    copyAction.accessibilityIdentifier = "id.action1"

    alertController.addAction(cancelAction)
    alertController.addAction(sendAction)
    alertController.addAction(copyAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: nil)
  }

  func showCustomBottomMailAction(_ url: URL) {
    let tel = url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
    let titleAction = NECustomAlertAction(title: String(format: commonLocalizable("detect_mailto_title"), tel)) {}
    titleAction.contentText.font = .systemFont(ofSize: 13)
    titleAction.contentText.textColor = .ne_lightText

    let sendAction = NECustomAlertAction(title: commonLocalizable("detect_mailto_send")) {
      UIApplication.shared.open(url)
    }

    let copyAction = NECustomAlertAction(title: commonLocalizable("detect_mailto_copy")) { [weak self] in
      UIPasteboard.general.string = tel
      self?.showToast(commonLocalizable("copy_success"))
    }

    showCustomActionSheet([titleAction, sendAction, copyAction])
  }

  func fixAlertOnIpad(_ alertViewController: UIAlertController) {
    alertViewController.fixIpadAction()
//        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
//            alertViewController.popoverPresentationController?.sourceView = view
//            alertViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
//            alertViewController.popoverPresentationController?.permittedArrowDirections = []
//        }
  }

  func showBottomAlert(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate,
    _ editing: Bool = true,
    _ checkNetwork: Bool = true,
    _ clickedAction: (() -> Void)? = nil,
    _ presentCompletion: (() -> Void)? = nil) {
    if checkNetwork,
       !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(commonLocalizable("network_error"))
      return
    }

    let alertController = UIAlertController(
      title: nil,
      message: nil,
      preferredStyle: .actionSheet
    )

    let cancelAction = UIAlertAction(
      title: commonLocalizable("cancel"),
      style: .cancel,
      handler: nil
    )
    cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    cancelAction.accessibilityIdentifier = "id.action3"

    let takingPicturesAction = UIAlertAction(title: commonLocalizable("take_picture"),
                                             style: .default) { action in
      self.goCamera(delegate, editing)
      if let action = clickedAction {
        action()
      }
    }
    takingPicturesAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    takingPicturesAction.accessibilityIdentifier = "id.action1"

    let localPhotoAction = UIAlertAction(title: commonLocalizable("select_from_album"),
                                         style: .default) { action in
      self.goPhotoAlbum(delegate, editing)
      if let action = clickedAction {
        action()
      }
    }
    localPhotoAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
    localPhotoAction.accessibilityIdentifier = "id.action2"

    alertController.addAction(cancelAction)
    alertController.addAction(takingPicturesAction)
    alertController.addAction(localPhotoAction)
    fixAlertOnIpad(alertController)
    present(alertController, animated: true, completion: presentCompletion)
  }

  func showCustomBottomAlert(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate,
    _ editing: Bool = true,
    _ checkNetwork: Bool = true) {
    if checkNetwork,
       !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(commonLocalizable("network_error"))
      return
    }

    let takingPicturesAction = NECustomAlertAction(title: commonLocalizable("take_picture")) { [weak self] in
      self?.goCamera(delegate, editing)
    }

    let localPhotoAction = NECustomAlertAction(title: commonLocalizable("select_from_album")) { [weak self] in
      self?.goPhotoAlbum(delegate, editing)
    }

    showCustomActionSheet([takingPicturesAction, localPhotoAction])
  }

  /// 底部视图弹窗
  /// - Parameters:
  ///   - firstContent: 第一选项文本内容
  ///   - secondContent: 第一选项文本内容
  ///   - selectValue: 选中action
  func showBottomSelectAlert(firstContent: String, secondContent: String,
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
                               style: .cancel) { action in
    }
    cancel.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    cancel.accessibilityIdentifier = "id.action3"

    alert.addAction(first)
    alert.addAction(second)
    alert.addAction(cancel)

    present(alert, animated: true, completion: nil)
  }

  func goCamera(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate,
                _ editing: Bool,
                _ isVideo: Bool = false) {
    weak var weakSelf = self
    let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    let cameraPicker = UIImagePickerController()
    cameraPicker.delegate = delegate
    cameraPicker.allowsEditing = editing
    cameraPicker.sourceType = .camera
    if isVideo == true {
      cameraPicker.mediaTypes = ["public.movie"]
    }

    if authStatus == .authorized { // 已授权，可以打开相机
      // 在需要的地方present出来
      DispatchQueue.main.async {
        weakSelf?.present(cameraPicker, animated: true, completion: nil)
      }
    } else if authStatus == .denied {
      showSingleAlert(message: commonLocalizable("jump_camera_setting")) {}
    } else if authStatus == .restricted { // 相机权限受限
      showSingleAlert(message: "\(commonLocalizable("camera_limit"))\n\(commonLocalizable("jump_camera_setting"))") {}
    } else if authStatus == .notDetermined { // 首次 使用
      AVCaptureDevice.requestAccess(for: .video, completionHandler: { statusFirst in
        if statusFirst { // 用户首次允许
          // 在需要的地方present出来
          DispatchQueue.main.async {
            weakSelf?.present(cameraPicker, animated: true, completion: nil)
          }
        } else { // 用户首次拒接
        }
      })
    }
  }

  func goPhotoAlbum(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate,
    _ editing: Bool, _ isVideo: Bool = false) {
    weak var weakSelf = self
    let status = PHPhotoLibrary.authorizationStatus()
    if status == .denied || status == .restricted {
      showSingleAlert(message: commonLocalizable("jump_photo_setting")) {}
    } else if status == .notDetermined {
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
          if status == .denied || status == .restricted {
            DispatchQueue.main.async {
              weakSelf?.showSingleAlert(message: commonLocalizable("jump_photo_setting")) {}
            }
          } else {
            DispatchQueue.main.async {
              weakSelf?.showPicker(delegate, isVideo, editing)
            }
          }
        }
      } else {
        PHPhotoLibrary.requestAuthorization { status in
          if status == .denied || status == .restricted {
            DispatchQueue.main.async {
              weakSelf?.showSingleAlert(message: commonLocalizable("jump_photo_setting")) {}
            }
          } else {
            DispatchQueue.main.async {
              weakSelf?.showPicker(delegate, isVideo, editing)
            }
          }
        }
      }
    } else {
      showPicker(delegate, isVideo, editing)
    }
  }

  func showPicker(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate, _ isVideo: Bool, _ editing: Bool) {
    let photoPicker = UIImagePickerController()
    photoPicker.delegate = delegate
    photoPicker.allowsEditing = editing
    photoPicker.sourceType = .photoLibrary
    if isVideo == true {
      photoPicker.mediaTypes = ["public.movie"]
    }
    photoPicker.modalPresentationStyle = .overFullScreen
    present(photoPicker, animated: true, completion: nil)
  }

  func goPhotoAlbumWithVideo(_ delegate: UIImagePickerControllerDelegate &
    UINavigationControllerDelegate, _ completion: (() -> Void)? = nil) {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    NEAuthManager.requestPhotoAuthorization { granted in
      weakSelf?.view.hideToastActivity()
      if granted == false {
        weakSelf?.showSingleAlert(message: commonLocalizable("jump_photo_setting")) {}
        return
      }
      let photoPicker = UIImagePickerController()
      photoPicker.delegate = delegate
      photoPicker.mediaTypes = ["public.movie", "public.image"]
      photoPicker.modalPresentationStyle = .overFullScreen
      weakSelf?.present(photoPicker, animated: true, completion: completion)
    }
  }

  func goICloudDocument(_ delegate: UIDocumentPickerDelegate &
    UINavigationControllerDelegate) {
    print("choose iCloud")
    let documentTypes = [
      "public.text",
      "public.plain-text",
      "public.archive",
      "public.image",
      "public.movie",
      "public.data",
      "public.content",
      "public.text",
      "public.source-code",
      "public.audiovisual-content",
      "com.adobe.pdf",
      "com.apple.keynote.key",
      "com.microsoft.word.doc",
      "com.microsoft.excel.xls",
      "com.microsoft.powerpoint.ppt",
    ]

    let document = UIDocumentPickerViewController(documentTypes: documentTypes, in: .open)
    document.delegate = delegate // UIDocumentPickerDelegate
    present(document, animated: true, completion: nil)
  }
}
