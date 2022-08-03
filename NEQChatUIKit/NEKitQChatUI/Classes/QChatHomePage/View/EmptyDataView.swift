
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.
import UIKit

class EmptyDataView: UIView {
    
    private var imageName:String?
    private var content:String?

    public init(imageName:String,content:String,frame:CGRect){
        self.imageName = imageName
        self.content = content
        super.init(frame: frame)
        setupSubviews()
        setupSubviewStyle()
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews(){
        self.backgroundColor = .white
        self.addSubview(emptyImageView)
        self.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            emptyImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 60),
            emptyImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 122),
            emptyImageView.heightAnchor.constraint(equalToConstant: 91),
        ])
        
        NSLayoutConstraint.activate([
            contentLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            contentLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ])
    }

    func setupSubviewStyle(){
        emptyImageView.image = UIImage.ne_imageNamed(name: imageName)
        contentLabel.text = content
    }
    
    private lazy var emptyImageView: UIImageView = {
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.ne_emptyTitleColor
        label.font = DefaultTextFont(14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    public func setttingContent(content:String) {
        self.contentLabel.text = content
    }
    
    public func setEmptyImage(name:String) {
        emptyImageView.image = UIImage.ne_imageNamed(name: name)
    }
    
}
