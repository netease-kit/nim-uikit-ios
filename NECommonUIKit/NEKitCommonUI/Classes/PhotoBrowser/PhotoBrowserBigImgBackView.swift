
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit


public class PhotoBrowserBigImgBackView: UIView {
    
    let duration = 0.3
    
//    lazy var backBtn : UIButton = {
//        let button = UIButton.init(type: .custom)
//        button.setImage(UIImage(named: "back_white"), for: .normal)
//        return button
//    }()
    
    lazy var collectionView : UICollectionView = {
        let layout = PhotoBrowserFlowLayout.init() // 给分页添加间距
        layout.sectionHeadersPinToVisibleBounds = true
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: floor(kScreenWidth), height: kScreenHeight)
        layout.sectionInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        let collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.alwaysBounceVertical = false // 不允许上下弹跳
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        
        return collectionView
    }()
    
    lazy var pageControl : UIPageControl = {
        let pageControl = UIPageControl.init()
        pageControl.isUserInteractionEnabled = false
        pageControl.isHidden = true
        return pageControl
    }()

    var dismissCallBack: (() -> Void)?
    
    var urlArr : [String] = []
    var imgArr : [UIImage] = []
    ///URL初始化
    public init(urlArr: [String],number: Int) {
        super.init(frame: .zero)
        self.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        self.backgroundColor = UIColor.black
        showUrlScroll(urlArr: urlArr, number: number)
    }
    
    private func showUrlScroll(urlArr: [String],number: Int) {
        self.urlArr = urlArr
        self.addSubview(collectionView)
        self.collectionView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.scrollToItem(at: IndexPath.init(item: number, section: 0), at: .centeredHorizontally, animated: false)
        setPageControl(urlArr.count, current: number)
    }
    
    public init(imgArr: [UIImage],number: Int) {
        super.init(frame: .zero)
        self.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        self.backgroundColor = UIColor.black
        showImages(Images: imgArr, number: number)
    }
    
    private func showImages(Images: [UIImage],number: Int) {
        self.imgArr = Images
        self.addSubview(collectionView)
        self.collectionView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.scrollToItem(at: IndexPath.init(item: number, section: 0), at: .centeredHorizontally, animated: false)
        setPageControl(Images.count, current: number)
    }
        
    private func setPageControl(_ total: Int,current: Int) {
        self.addSubview(self.pageControl)
        self.pageControl.frame = CGRect(x: 0, y: kScreenHeight - 80, width: kScreenWidth, height: 30)
        self.pageControl.numberOfPages = total
        self.pageControl.currentPage = current
        self.pageControl.currentPageIndicatorTintColor = UIColor.white
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.hidesForSinglePage = true
    }
    
    public func currentIndex() -> Int {
        Int(collectionView.contentOffset.x / kScreenWidth)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoBrowserBigImgBackView: UICollectionViewDelegate,UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.urlArr.count != 0 {
            return self.urlArr.count
        }else{
            return self.imgArr.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! PhotoBrowserCell
        if self.urlArr.count  != 0 {
            
            cell.imgUrl = self.urlArr[indexPath.row]
        }else{
            cell.image = self.imgArr[indexPath.row]
        }
        // pan手势
        cell.backRemoveCallBack = { [weak self] in
            guard let `self` = self else { return }
            self.backRemoveAnimation(self.duration)
        }
        // 点击手势
        cell.tapMoveCallBack = {[weak self] (imgView) in
            guard let `self` = self else { return }
            self.removeAnimation(imgView)
        }
        cell.changeAlphaCallBack = { [weak self] (alpha) in
            guard let `self` = self else { return }
            self.changeBackAlpha(alpha: alpha)
        }
        return cell
    }
    
    public func dismissPhotoBrowser(){
        if let cell = collectionView.cellForItem(at: IndexPath(row: currentIndex(), section: 0)) as? PhotoBrowserCell {
            removeAnimation(cell.imgView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView ,let index = collectionView.indexPathForItem(at: collectionView.contentOffset)?.item{
            
            self.pageControl.currentPage = Int(index)
        }
    }
}

// MARK: 点击的方法
extension PhotoBrowserBigImgBackView {
    
    @objc func backBtnClick() {
        self.dismissCallBack?()
    }
}
//MARK: 动画
extension PhotoBrowserBigImgBackView {

    /*
     视图将要显示时获取到第一次要显示的cell上的imgView来显示动画
     */
    public func transformAnimation() {
        // 第一次弹出时的动画
        collectionView.reloadData()
        collectionView.setNeedsLayout()
        self.collectionView.layoutIfNeeded()

        guard let indexPath = collectionView.indexPathForItem(at: collectionView.contentOffset) else {
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoBrowserCell else {
            return
        }
        self.showAnimation()
        self.transformScaleAnimation(fromValue: 0.3, toValue: 1, duration: 0.3, view: cell.imgView)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // 赋值方法中imageview重新布局
            self.collectionView.reloadData()

        }
    }
    
    // 缩放 + 淡入淡出
    func removeAnimation(_ imgView: UIView) {
        if imgView.frame.size.height <= kScreenHeight {
            self.transformScaleAnimation(fromValue: 1.0, toValue: 0.3, duration: 0.3, view: imgView)
        }
        self.backRemoveAnimation(duration)
    }
    
    // 缩放
    func transformScaleAnimation(fromValue: CGFloat,toValue: CGFloat,duration: CFTimeInterval,view: UIView) {
        let scale = CABasicAnimation()
        scale.keyPath = "transform.scale"
        scale.fromValue = fromValue
        scale.toValue = toValue
        scale.duration = duration
        scale.fillMode = CAMediaTimingFillMode.forwards
        scale.isRemovedOnCompletion = false
        view.layer.add(scale, forKey: nil)
    }
    
    func showAnimation() {
        let backAnimation = CAKeyframeAnimation()
        backAnimation.keyPath = "opacity"
        backAnimation.duration = duration
        backAnimation.values = [
            NSNumber(value: 0.10 as Float),
            NSNumber(value: 0.40 as Float),
            NSNumber(value: 0.80 as Float),
            NSNumber(value: 1.0 as Float),
        ]
        backAnimation.keyTimes = [
            NSNumber(value: 0.1),
            NSNumber(value: 0.2),
            NSNumber(value: 0.3),
            NSNumber(value: 0.4)
        ]
        backAnimation.fillMode = CAMediaTimingFillMode.forwards
        backAnimation.isRemovedOnCompletion = false
        self.layer.add(backAnimation, forKey: nil)
    }
    
    // 背景变淡消失的动画
    func backRemoveAnimation(_ duration: CFTimeInterval) {
        let backAnimation = CAKeyframeAnimation()
        backAnimation.delegate = self
        backAnimation.keyPath = "opacity"
        backAnimation.duration = duration
        backAnimation.values = [
            NSNumber(value: 0.90 as Float),
            NSNumber(value: 0.60 as Float),
            NSNumber(value: 0.30 as Float),
            NSNumber(value: 0.0 as Float),
            
        ]
        backAnimation.keyTimes = [
            NSNumber(value: 0.1),
            NSNumber(value: 0.2),
            NSNumber(value: 0.3),
            NSNumber(value: 0.4)
        ]
        backAnimation.fillMode = CAMediaTimingFillMode.forwards
        backAnimation.isRemovedOnCompletion = false
        self.layer.add(backAnimation, forKey: nil)
    }
    
    func changeBackAlpha(alpha: CGFloat) {
        self.backgroundColor = UIColor.black.withAlphaComponent(alpha)
    }
}
// MARK: 动画代理
extension PhotoBrowserBigImgBackView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim.isKind(of: CAKeyframeAnimation.self) && flag {
            self.dismissCallBack?()
        }
    }

}
extension UIImage {
    static func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? nil
    }
}
