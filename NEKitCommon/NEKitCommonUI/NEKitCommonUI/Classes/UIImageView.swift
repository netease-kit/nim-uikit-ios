
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation

class CornerView: UIView {
    
    var corner = UIRectCorner.bottomLeft
    var radius: CGFloat = 8
    var color = UIColor.white
    init(corner: UIRectCorner, radius: CGFloat = 8, color: UIColor = .white){
        self.corner = corner
        self.radius = radius
        super.init(frame: CGRect(x: 0, y: 0, width: radius, height: radius))
    }
    
    
    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        color.set()
        context.setLineWidth(1.0)
        switch corner {
        case .bottomLeft:
            context.move(to: CGPoint(x: radius, y: radius) )
            context.addLine(to: CGPoint(x: 0, y: radius))
            context.addLine(to: .zero)
            context.addArc(center: CGPoint(x: radius, y: 0), radius: radius, startAngle: Double.pi, endAngle: 0.5 * Double.pi, clockwise: true)
            break
        case .bottomRight:
            
            context.move(to: CGPoint(x: radius, y: 0))
            context.addLine(to: CGPoint(x: radius, y: radius))
            context.addLine(to: CGPoint(x: 0, y: radius))
            context.addArc(center: .zero, radius: radius, startAngle: 0.5 * .pi, endAngle: 0, clockwise: true)
            
            break
        case .topRight:
            
            context.move(to: .zero )
            context.addLine(to: CGPoint(x: radius, y: 0))
            context.addLine(to: CGPoint(x: radius, y: radius))
            context.addArc(center: CGPoint(x: 0, y: radius), radius: radius, startAngle: 0 , endAngle: -0.5 * .pi, clockwise: true)
            
            break
        case .topLeft:
            context.move(to: CGPoint(x: 0, y: radius))
            context.addLine(to: .zero)
            context.addLine(to: CGPoint(x: radius, y: 0))
            context.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: 1.5 *  Double.pi, endAngle: Double.pi, clockwise: true)
            break
        default:
            break
        }
        
        context.fillPath()
        context.strokePath()
    }
}

public extension UIImageView {
    
    func addCustomCorner(conrners: UIRectCorner, radius: CGFloat, backcolor: UIColor) {
        if conrners.contains(UIRectCorner.topLeft) {
            let view = CornerView(corner: .topLeft, radius: radius)
            view.backgroundColor = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: leftAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.widthAnchor.constraint(equalToConstant: radius),
                view.heightAnchor.constraint(equalToConstant: radius)
            ])
        }
        
        if conrners.contains(UIRectCorner.topRight) {
            let view = CornerView(corner: .topRight, radius: radius)
            view.backgroundColor = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.rightAnchor.constraint(equalTo: rightAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.widthAnchor.constraint(equalToConstant: radius),
                view.heightAnchor.constraint(equalToConstant: radius)
            ])
        }
        
        if conrners.contains(UIRectCorner.bottomRight) {
            let view = CornerView(corner: .bottomRight, radius: radius)
            view.backgroundColor = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.rightAnchor.constraint(equalTo: rightAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
                view.widthAnchor.constraint(equalToConstant: radius),
                view.heightAnchor.constraint(equalToConstant: radius)
            ])
        }
        
        if conrners.contains(UIRectCorner.bottomLeft) {
            let view = CornerView(corner: .bottomLeft, radius: radius)
            view.backgroundColor = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: leftAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
                view.widthAnchor.constraint(equalToConstant: radius),
                view.heightAnchor.constraint(equalToConstant: radius)
            ])
        }
    }
    
}
