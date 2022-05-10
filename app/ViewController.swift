
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ViewController: UIViewController {

    lazy var launchIcon : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "launch_icon")
        return imageView
    }()
    
    lazy var copyrightImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "copy_right")
        return imageView
    }()
    
    lazy var slogan: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "真正稳定的IM云服务"
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor(hexString: "666666")
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
    }
    
    func setupUI(){
        
        view.addSubview(launchIcon)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                launchIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160.0)
            ])
        }else {
            NSLayoutConstraint.activate([
                launchIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                launchIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 160.0)
            ])
        }
        
        view.addSubview(slogan)
        NSLayoutConstraint.activate([
            slogan.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slogan.topAnchor.constraint(equalTo: launchIcon.bottomAnchor, constant: 12.0)
            
        ])
        
        view.addSubview(copyrightImage)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                copyrightImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                copyrightImage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48)
            ])
        } else {
            NSLayoutConstraint.activate([
                copyrightImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                copyrightImage.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
            ])
        }
    }


}

