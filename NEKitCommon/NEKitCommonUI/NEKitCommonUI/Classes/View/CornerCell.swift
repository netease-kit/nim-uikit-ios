
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCommon

public struct CornerType:OptionSet {
    public init(rawValue: Int) { self.rawValue = rawValue }
    public let rawValue: Int
    public static let none = CornerType(rawValue: 1)
    public static let topLeft = CornerType(rawValue: 2)
    public static let topRight = CornerType(rawValue: 4)
    public static let bottomLeft = CornerType(rawValue: 8)
    public static let bottomRight = CornerType(rawValue: 16)
}

open class CornerCell: UITableViewCell {

    var cornerLayer = CAShapeLayer()
    public var fillColor: UIColor = .white
    public var edgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    private var type : CornerType = .none
    public var cornerType: CornerType {
            get { return type }
            set {
                if type != newValue {
                    type = newValue
                    sizeToFit()
                }
            }
        }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor =  NEConstant.hexRGB(0xF1F1F6)
        selectionStyle = .none
        self.layer.insertSublayer(cornerLayer, below: self.contentView.layer)
        print(#function)
        contentView.addSubview(dividerLine)
        NSLayoutConstraint.activate([
            dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
            dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = NEConstant.hexRGB(0xF5F8FC)
        line.isHidden = true
        return line
    }()
    
    public var showDefaultLine = false
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func draw(_ rect: CGRect) {
        drawRoundedCorner(rect: rect)
        print(#function)
    }
    
    public func drawRoundedCorner(rect: CGRect) {
        var path: UIBezierPath = UIBezierPath()
        let roundRect = CGRect(x: rect.origin.x + edgeInset.left, y: rect.origin.y + edgeInset.top, width: rect.width - (edgeInset.left + edgeInset.right), height: rect.height - (edgeInset.top + edgeInset.bottom))
        if type == .none {
            path = UIBezierPath(rect: roundRect)
            if showDefaultLine { dividerLine.isHidden = false }
        }
        var corners = UIRectCorner()
        if type.contains(CornerType.topLeft) {
            corners = corners.union(.topLeft)
            if showDefaultLine { dividerLine.isHidden = false }
        }
        if type.contains(CornerType.topRight) {
            corners = corners.union(.topRight)
        }
        if type.contains(CornerType.bottomLeft) {
            corners = corners.union(.bottomLeft)
            if showDefaultLine { dividerLine.isHidden = true }
        }
        if type.contains(CornerType.bottomRight) {
            corners = corners.union(.bottomRight)
            
        }
        path = UIBezierPath(roundedRect:roundRect, byRoundingCorners: corners, cornerRadii: CGSize(width: 10, height: 10))
        
        cornerLayer.path = path.cgPath
        cornerLayer.fillColor = fillColor.cgColor
    }

}
