
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit

public protocol BrowserToolsBarDelegate: AnyObject {
    func didCloseClick()
    func didPhotoClick()
    func didSaveClick()
}

public class BrowserToolsBar: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    public weak var delegate: BrowserToolsBarDelegate?
    
    public lazy var saveBtn: ExpandButton = {
        let btn = ExpandButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(coreLoader.loadImage("save_btn"), for: .normal)
        return btn
    }()
    
    public lazy var closeBtn: ExpandButton = {
        let btn = ExpandButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(coreLoader.loadImage("close_btn"), for: .normal)
        return btn
    }()
    
    public lazy var photoBtn: ExpandButton = {
        let btn = ExpandButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(coreLoader.loadImage("photo_btn"), for: .normal)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        backgroundColor = .clear
        addSubview(closeBtn)
        NSLayoutConstraint.activate([
            closeBtn.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            closeBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeBtn.heightAnchor.constraint(equalToConstant: 28),
            closeBtn.widthAnchor.constraint(equalToConstant: 28)
        ])
        closeBtn.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        
        addSubview(photoBtn)
        NSLayoutConstraint.activate([
            photoBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            photoBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            photoBtn.heightAnchor.constraint(equalToConstant: 28),
            photoBtn.widthAnchor.constraint(equalToConstant: 28)
        ])
        photoBtn.addTarget(self, action: #selector(photoClick), for: .touchUpInside)
        
        addSubview(saveBtn)
        NSLayoutConstraint.activate([
            saveBtn.rightAnchor.constraint(equalTo: photoBtn.leftAnchor, constant: -20),
            saveBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            saveBtn.heightAnchor.constraint(equalToConstant: 28),
            saveBtn.widthAnchor.constraint(equalToConstant: 28)
        ])
        saveBtn.addTarget(self, action: #selector(saveClick), for: .touchUpInside)
    }
    
    @objc func saveClick(){
        delegate?.didSaveClick()
    }
    
    @objc func photoClick(){
        delegate?.didPhotoClick()
    }
    
    @objc func closeClick(){
        delegate?.didCloseClick()
    }

}
