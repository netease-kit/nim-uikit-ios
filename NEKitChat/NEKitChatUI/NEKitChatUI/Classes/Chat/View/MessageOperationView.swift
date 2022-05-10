
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

public protocol MessageOperationViewDelegate: AnyObject {
    func didSelectedItem(item: OperationItem)
}

public class MessageOperationView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var collcetionView: UICollectionView
    public weak var delegate: MessageOperationViewDelegate?
    public var items = [OperationItem]() {
        didSet {
            collcetionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 56)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = .vertical
        collcetionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collcetionView.backgroundColor = .white
        collcetionView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        self.backgroundColor = .white
//        self.layer.cornerRadius = 8
//        self.layer.shadowRadius = 4
//        self.layer.shadowColor = UIColor.black.cgColor
//        self.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
//        
//        collcetionView.layer.shadowRadius = 4
//        collcetionView.layer.shadowColor = UIColor.black.cgColor
//        collcetionView.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
//        collcetionView.layer.shadowOpacity = 0.8
//        
        
        collcetionView.dataSource = self
        collcetionView.delegate = self
        collcetionView.isUserInteractionEnabled = true
        collcetionView.register(OperationCell.self, forCellWithReuseIdentifier: "\(OperationCell.self)")
        self.addSubview(collcetionView)
        NSLayoutConstraint.activate([
            collcetionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            collcetionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            collcetionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            collcetionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
        ])
        
        self.addSubview(collcetionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    MARK: UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(OperationCell.self)", for: indexPath) as? OperationCell
        cell?.model = items[indexPath.row]
//        cell?.delegate = self
        return cell ?? UICollectionViewCell()
    }
    
//    MARK: UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.removeFromSuperview()
        self.delegate?.didSelectedItem(item: items[indexPath.row])
    }

//    func didSelected(_ cell: OperationCell, _ model: OperationItem?) {
//        self.removeFromSuperview()
//        if let m =  model {
//            self.delegate?.didSelectedItem(item: m)
//        }
//
//    }

}
