
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import UIKit
import NEKitCommon

public class PopListItem {
    public typealias PopListClick = () -> Void
    public var image: UIImage?
    public var showName: String?
    public var completion: PopListClick?
    
    public init(){}
}


public class PopListViewController: UIViewController  {
    
    public var itemDatas = [PopListItem]()
    
    public var buttonHeight: CGFloat = 32.0
    
    public var popViewWidth: CGFloat = 122.0
    
    public var popViewRadius: CGFloat = 8.0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeSelf()
    }
    
    func setupUI(){
        view.backgroundColor = .clear
        
        let popViewHeight: CGFloat = CGFloat(itemDatas.count) * 32 + 16

        let shadowView = UIView()
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = .clear
        view.addSubview(shadowView)
        shadowView.clipsToBounds = false
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowView.layer.shadowColor = NEConstant.hexRGB(0x85888C).cgColor
        shadowView.layer.shadowOpacity = 0.25
        shadowView.layer.shadowRadius = 7
        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            shadowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            shadowView.widthAnchor.constraint(equalToConstant: popViewWidth),
            shadowView.heightAnchor.constraint(equalToConstant: popViewHeight)
        ])
        
        let popView = UIView()
        shadowView.addSubview(popView)
        popView.backgroundColor = NEConstant.hexRGB(0xFFFFFF)
        popView.clipsToBounds = true
        popView.layer.cornerRadius = popViewRadius
        popView.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            popView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            popView.rightAnchor.constraint(equalTo: shadowView.rightAnchor),
            popView.leftAnchor.constraint(equalTo: shadowView.leftAnchor),
            popView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor)
        ])
        
        let offset: CGFloat = 8
        for index in 0..<itemDatas.count {
            let item = itemDatas[index]
            let itemBtn = UIButton()
            itemBtn.tag = index
            itemBtn.translatesAutoresizingMaskIntoConstraints = false
            itemBtn.setImage(item.image, for: .normal)
            itemBtn.layoutButtonImage(style: .left, space: 6)
            itemBtn.setTitle(item.showName, for: .normal)
            itemBtn.titleLabel?.font = NEConstant.defaultTextFont(14.0)
            itemBtn.setTitleColor(NEConstant.hexRGB(0x333333), for: .normal)
            itemBtn.addTarget(self, action: #selector(itemClick(_:)), for: .touchUpInside)
            itemBtn.contentHorizontalAlignment = .left
            
            popView.addSubview(itemBtn)
            NSLayoutConstraint.activate([
                itemBtn.topAnchor.constraint(equalTo: popView.topAnchor, constant: offset + CGFloat(index * 32)),
                itemBtn.leftAnchor.constraint(equalTo: popView.leftAnchor, constant: 15),
                itemBtn.rightAnchor.constraint(equalTo: popView.rightAnchor, constant: -4),
                itemBtn.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
        
       
        
    }
    
    @objc func itemClick(_ sender: UIButton){
        print("item click")
        let index = sender.tag
        let item = itemDatas[index]
        if let block = item.completion {
            block()
        }
        removeSelf()
    }
    
    public func removeSelf(){
        view.removeFromSuperview()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("pop list view touchesBegan")
        removeSelf()
    }
    
}
