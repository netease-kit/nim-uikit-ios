
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class CornerButton: UIButton {
    var cornerLayer = CAShapeLayer()
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            cornerLayer.fillColor = newValue ? selectedColor.cgColor : color.cgColor
            super.isSelected = newValue
        }
    
    }
    override var isUserInteractionEnabled: Bool {
        get {
            return super.isUserInteractionEnabled
        }
        set {
            super.isUserInteractionEnabled = newValue
            self.alpha = newValue ? 1.0 : 0.5
        }
    }
//    public var ne_selected: Bool {
//        get {
//            return self.isSelected
//        }
//        set {
//            if newValue {
////                cornerLayer.fillColor = UIColor.purple.cgColor
//            }else {
////                cornerLayer.fillColor = color.cgColor
//            }
//            self.isSelected = newValue
//        }
//    }
    
    
//    public var fillColor: UIColor = .white
    public var color: UIColor = .white
    public var selectedColor: UIColor = .white
    private var type : CornerType = .none
    public var edgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var cornerType: CornerType {
            get { return type }
            set {
                if type != newValue {
                    type = newValue
                    sizeToFit()
                }
            }
        }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = true
        cornerLayer.fillColor = color.cgColor
        cornerLayer.strokeColor = UIColor.ne_borderColor.cgColor
//        self.backgroundColor = .ne_lightBackgroundColor
        self.layer.insertSublayer(cornerLayer, below: self.imageView?.layer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        drawRoundedCorner(rect: self.bounds)
        
        print(#function)
    }
//    public override func draw(_ rect: CGRect) {
//        drawRoundedCorner(rect: rect)
//    }
    
    public func drawRoundedCorner(rect: CGRect) {
        var path: UIBezierPath = UIBezierPath()
        let roundRect = CGRect(x: rect.origin.x + edgeInset.left, y: rect.origin.y + edgeInset.top, width: rect.width - (edgeInset.left + edgeInset.right), height: rect.height - (edgeInset.top + edgeInset.bottom))
        if type == .none {
            path = UIBezierPath(rect: roundRect)
        }
        var corners = UIRectCorner()
        if type.contains(CornerType.topLeft) {
            corners = corners.union(.topLeft)
        }
        if type.contains(CornerType.topRight) {
            corners = corners.union(.topRight)
        }
        if type.contains(CornerType.bottomLeft) {
            corners = corners.union(.bottomLeft)
        }
        if type.contains(CornerType.bottomRight) {
            corners = corners.union(.bottomRight)
        }
        
        path = UIBezierPath(roundedRect:roundRect, byRoundingCorners: corners, cornerRadii: CGSize(width: 10, height: 10))
        cornerLayer.path = path.cgPath
//        cornerLayer.fillColor =  self.isSelected ? selectedColor.cgColor : color.cgColor
//        cornerLayer.strokeColor = UIColor.ne_borderColor.cgColor
    }
    
//    @objc
//    private func didSelect(sender: AnyObject) {
//        self.isSelected = !self.isSelected
//    }
    


}
