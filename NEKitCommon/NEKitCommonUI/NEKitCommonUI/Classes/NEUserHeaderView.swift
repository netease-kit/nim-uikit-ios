
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit


public class NEUserHeaderView: UIImageView {


    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        isUserInteractionEnabled = true
        clipsToBounds = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor
                .constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        backgroundColor = .clear
    }
    
    
    public func configHeadData(headUrl:String?,name:String){
        if let avatar = headUrl {
            setTitle("")
            self.sd_setImage(with: URL(string: avatar), completed: nil)
        }else {
            setTitle(name)
            self.sd_setImage(with:nil, completed: nil)
            self.backgroundColor = UIColor.colorWithString(string: name)
        }
    }
    
    public func setTitle(_ name: String){
        titleLabel.text = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
    }

}
