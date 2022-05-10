
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitCommon

public class PhotoBrowserController: UIViewController {
    
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
        success.contentLabel.text = "已保存到系统相册"
        return success
    }()
    
    internal var showView: PhotoBrowserBigImgBackView
    internal var number: Int
    public init(imgs: [UIImage],img: UIImage) {
        var number = 0
        _ = imgs.enumerated().map { (index,urlStr) in
            if urlStr == img {
                number = index
            }
        }
        self.number = number
        self.showView = PhotoBrowserBigImgBackView(imgArr: imgs, number: number)
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(urls: [String],url: String) {
        var number = 0
        _ = urls.enumerated().map { (index,urlStr) in
            if urlStr == url {
                number = index
            }
        }
        self.number = number
        self.showView = PhotoBrowserBigImgBackView.init(urlArr: urls, number: number)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.layoutViews()
        self.showView.transformAnimation()
    }
    
    func layoutViews() {
        self.view.addSubview(self.showView)
        
        self.showView.dismissCallBack = { [weak self] in
            self?.dismiss(animated: false, completion: nil)
        }
        
        showView.addSubview(toolsBar)
        toolsBar.leftAnchor.constraint(equalTo: showView.leftAnchor).isActive = true
        toolsBar.rightAnchor.constraint(equalTo: showView.rightAnchor).isActive = true
        toolsBar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            toolsBar.bottomAnchor.constraint(equalTo: showView.safeAreaLayoutGuide.bottomAnchor, constant: -27).isActive = true
        } else {
            toolsBar.bottomAnchor.constraint(equalTo: showView.bottomAnchor, constant: -27).isActive = true
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
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
        view.makeToastActivity(.center)
        weak var weakSelf = self
        DispatchQueue.main.async {
            weakSelf?.saveImage()
        }
    }
    
    
    // 保存图片
    @objc func saveImage() {
        
        let index = showView.currentIndex()
        if self.showView.urlArr.count > 0 {
            let urlString = self.showView.urlArr[index]
            if let url = URL(string: urlString),  let data = try? Data.init(contentsOf: url), let img = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(img, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
            }else {
                view.hideToastActivity()
            }
        }else{
            let img = self.showView.imgArr[index]
            UIImageWriteToSavedPhotosAlbum(img, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
        view.hideToastActivity()
        if let error = didFinishSavingWithError {
            showToast(error.localizedDescription)
        } else {
            view.showToast(successView, point: view.center)
        }
    }
    
}
