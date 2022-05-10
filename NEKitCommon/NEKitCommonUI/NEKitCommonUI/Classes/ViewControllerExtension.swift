
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import AVFoundation
import Toast_Swift
import NEKitCommon

public typealias AlertCallBack = () -> Void

extension UIViewController: UIImagePickerControllerDelegate {
    
     public var rightNavBtn: ExpandButton {
        get {
            if let btn = objc_getAssociatedObject(self, UnsafeRawPointer.init(bitPattern: "rightNavBtn".hashValue)!) as? ExpandButton {
                return btn
            }else {
                let btn = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
                self.rightNavBtn = btn
                btn.setTitleColor(.ne_blueText, for: .normal)
                btn.titleLabel?.font = NEConstant.defaultTextFont(16)
                return btn
            }
        }
         
        set {
            objc_setAssociatedObject(self, UnsafeRawPointer.init(bitPattern: "rightNavBtn".hashValue)!, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    public var leftNavBtn: ExpandButton {
       get {
           if let btn = objc_getAssociatedObject(self, UnsafeRawPointer.init(bitPattern: "leftNavBtn".hashValue)!) as? ExpandButton {
               return btn
           }else {
               let btn = ExpandButton(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
               self.leftNavBtn = btn
               btn.setTitleColor(.ne_darkText, for: .normal)
               btn.titleLabel?.font = NEConstant.defaultTextFont(16)
               return btn
           }
       }
       set {
           objc_setAssociatedObject(self, UnsafeRawPointer.init(bitPattern: "leftNavBtn".hashValue)!, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
       }
   }
    
    public func addLeftAction(_ image: UIImage?, _ selector: Selector, _ target: Any?){
        let leftItem = UIBarButtonItem(image: image, style: .plain, target: target, action: selector)
        leftItem.tintColor = .ne_greyText
        navigationItem.leftBarButtonItem = leftItem
    }
    
    public func addLeftAction(_ title: String, _ selector: Selector, _ target: Any?){
        leftNavBtn.addTarget(target, action: selector, for: .touchUpInside)
        leftNavBtn.setTitle(title, for: .normal)
        let leftItem = UIBarButtonItem(customView: leftNavBtn)
        leftItem.tintColor = .ne_blueText
        navigationItem.leftBarButtonItem = leftItem
    }
    
    
    public func addRightAction(_ image: UIImage?, _ selector: Selector, _ target: Any?){
        let rightItem = UIBarButtonItem(image: image, style: .plain, target: target, action: selector)
        rightItem.tintColor = .ne_greyText
        navigationItem.rightBarButtonItem = rightItem
    }
    
    public func addRightAction(_ title: String, _ selector: Selector, _ target: Any?){
        rightNavBtn.addTarget(target, action: selector, for: .touchUpInside)
        rightNavBtn.setTitle(title, for: .normal)
        let rightItem = UIBarButtonItem(customView: rightNavBtn)
        rightItem.tintColor = .ne_blueText
        navigationItem.rightBarButtonItem = rightItem
    }
    
    public func showAlert(title: String = commonLocalizable("qchat_tip"), message: String?, sureText: String = commonLocalizable("qchat_sure"), cancelText: String = commonLocalizable("qchat_cancel"), _ sureBack: @escaping AlertCallBack, cancelBack: AlertCallBack? = nil ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
       
        let cancelAction = UIAlertAction(title: cancelText, style: .default) { action in
            if let block = cancelBack {
                block()
            }
        }
        alertController.addAction(cancelAction)
        let sureAction = UIAlertAction(title: sureText, style: .default) { action in
            sureBack()
        }
        alertController.addAction(sureAction)
        print("show alert view")
        present(alertController, animated: true, completion: nil)
    }
    
    public func showSingleAlert(title: String = commonLocalizable("qchat_tip"), message: String?, sureText: String = commonLocalizable("qchat_sure"), _ sureBack: @escaping AlertCallBack) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let sureAction = UIAlertAction(title: sureText, style: .default) { action in
            sureBack()
        }
        alertController.addAction(sureAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func showToast(_ message: String){
        UIApplication.shared.keyWindow?.endEditing(true)
        view.makeToast(message, duration: 2, position: .center)
    }
    
    public func showToastInWindow(_ message: String){
        UIApplication.shared.keyWindow?.endEditing(true)
        UIApplication.shared.keyWindow?.makeToast(message)
    }
    
    public func showActionSheet(_ actions: [UIAlertAction]){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.forEach { action in
            action.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
            alertController.addAction(action)
        }
        alertController.fixIpadAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func showBottomVideoAction(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate, _ editing: Bool = true){
        
        if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
            showToast("当前网络错误")
            return
        }
        weak var weakSelf = self
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title:commonLocalizable("取消"), style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
        
        let takingPicturesAction = UIAlertAction(title:commonLocalizable("摄像"), style: .default){ action in
            weakSelf?.goCamera(delegate, editing, true)
        }
        takingPicturesAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")

        let localPhotoAction = UIAlertAction(title:commonLocalizable("拍照"), style: .default){ action in
            weakSelf?.goCamera(delegate, editing, false)
        }
        localPhotoAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")

        alertController.addAction(cancelAction)
        alertController.addAction(localPhotoAction)
        alertController.addAction(takingPicturesAction)
        fixAlertOnIpad(alertController)
        self.present(alertController, animated:true, completion:nil)
    }
    
    private func fixAlertOnIpad(_ alertViewController: UIAlertController) {
        alertViewController.fixIpadAction()
//        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
//            alertViewController.popoverPresentationController?.sourceView = view
//            alertViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
//            alertViewController.popoverPresentationController?.permittedArrowDirections = []
//        }
    }
    
    public func showBottomAlert(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate, _ editing: Bool = true){
        
        if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
            showToast("当前网络错误")
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title:commonLocalizable("取消"), style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")
        
        let takingPicturesAction = UIAlertAction(title:commonLocalizable("拍照"), style: .default){ action in
            self.goCamera(delegate, editing)
        }
        takingPicturesAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")

        let localPhotoAction = UIAlertAction(title:commonLocalizable("从相册选择"), style: .default){ action in
            self.goPhotoAlbum(delegate, editing)
        }
        localPhotoAction.setValue(UIColor.ne_darkText, forKey: "_titleTextColor")

        alertController.addAction(cancelAction)
        alertController.addAction(takingPicturesAction)
        alertController.addAction(localPhotoAction)
        fixAlertOnIpad(alertController)
        self.present(alertController, animated:true, completion:nil)
    }
    
    public func goCamera(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate, _ editing: Bool, _ isVideo: Bool = false){
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if (authStatus == .authorized) {//已授权，可以打开相机
            let  cameraPicker = UIImagePickerController()
            cameraPicker.delegate = delegate
            cameraPicker.allowsEditing = editing
            cameraPicker.sourceType = .camera
            if isVideo == true {
                cameraPicker.mediaTypes = ["public.movie"]
            }
            //在需要的地方present出来
            self.present(cameraPicker, animated: true, completion: nil)
               
        } else if (authStatus == .denied) {
            
            showAlert(message: "请去-> [设置 - 隐私 - 相机] 打开访问开关") {}

       } else if (authStatus == .restricted) {//相机权限受限
           
           showAlert(message: "相机权限受限") {}

       } else if (authStatus == .notDetermined) {//首次 使用
           AVCaptureDevice.requestAccess(for: .video, completionHandler: { (statusFirst) in
               if statusFirst { //用户首次允许
                   let  cameraPicker = UIImagePickerController()
                   cameraPicker.delegate = delegate
                   cameraPicker.allowsEditing = true
                   cameraPicker.sourceType = .camera
                   //在需要的地方present出来
                   DispatchQueue.main.async {
                       self.present(cameraPicker, animated: true, completion: nil)
                   }
               } else {//用户首次拒接
                   
               }
           })
       }
    }
        
    public func goPhotoAlbum(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate, _ editing: Bool, _ isVideo: Bool = false){
        NEAuthManager.requestCameraAuthorization { granted in
            if granted {
                let photoPicker =  UIImagePickerController()
                photoPicker.delegate = delegate
                photoPicker.allowsEditing = editing
                photoPicker.sourceType = .photoLibrary
                if isVideo == true {
                    photoPicker.mediaTypes = ["public.movie"]
                }
                //在需要的地方present出来
                self.present(photoPicker, animated: true, completion: nil)
            }else {
                self.view.makeToast("未打开相册权限")
            }
        }
    }
    
    public func goPhotoAlbumWithVideo(_ delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate){
        NEAuthManager.requestCameraAuthorization { granted in
            if granted {
                let photoPicker =  UIImagePickerController()
                photoPicker.delegate = delegate
                photoPicker.sourceType = .photoLibrary
                photoPicker.mediaTypes = ["public.movie","public.image"]
                //在需要的地方present出来
                self.present(photoPicker, animated: true, completion: nil)
            }else {
                self.view.makeToast("未打开相册权限")
            }
        }
    }
 
}

