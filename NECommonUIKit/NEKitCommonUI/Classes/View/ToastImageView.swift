
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCommon

public class ToastImageView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    public var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = coreLoader.loadImage("white_right_img")
        return image
    }()
    
    public var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NEConstant.defaultTextFont(14.0)
        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 36)
        ])
        
        addSubview(contentLabel)
        NSLayoutConstraint.activate([
            contentLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            contentLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            contentLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20)
        ])
        
        backgroundColor = NEConstant.hexRGB(0x4C4C4C)
        clipsToBounds = true
        layer.cornerRadius = 8.0
        
        
    }

}
