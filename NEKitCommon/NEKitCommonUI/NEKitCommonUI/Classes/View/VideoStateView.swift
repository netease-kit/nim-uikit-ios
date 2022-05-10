
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCommon

public enum VideoState {
    case VideoPlay
    case VideoDownload
}

public class VideoStateView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.isHidden = true
        return layer
    }()
    
    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.isHidden = true
        return layer
    }()
    
    public var state = VideoState.VideoPlay {
        didSet {
            switch state {
            case .VideoPlay:
                videoPlayImage.isHidden = false
                verticalLineLeft.isHidden = true
                verticalLineRight.isHidden = true
                circleLayer.isHidden = true
                progressLayer.isHidden = true
                alphaBackView.isHidden = true
            case .VideoDownload:
                videoPlayImage.isHidden = true
                verticalLineLeft.isHidden = false
                verticalLineRight.isHidden = false
                circleLayer.isHidden = false
                progressLayer.isHidden = false
                alphaBackView.isHidden = false
            }
        }
    }
    
    lazy var videoPlayImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = coreLoader.loadImage("video_play")
        image.isHidden = false
        return image
    }()
    
    lazy var alphaBackView: UIView = {
        let view = UIView()
        view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.2)
        view.clipsToBounds = true
        view.layer.cornerRadius = 21
        view.isHidden = true
        return view
    }()
    
    lazy var verticalLineLeft: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = .white
        line.clipsToBounds = true
        line.layer.cornerRadius = 1.5
        line.isHidden = true
        return line
    }()
    
    lazy var verticalLineRight: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = .white
        line.clipsToBounds = true
        line.layer.cornerRadius = 1.5
        line.isHidden = true
        return line
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        addSubview(videoPlayImage)
        NSLayoutConstraint.activate([
            videoPlayImage.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoPlayImage.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addSubview(alphaBackView)
        NSLayoutConstraint.activate([
            alphaBackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            alphaBackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            alphaBackView.widthAnchor.constraint(equalToConstant: 42),
            alphaBackView.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        addSubview(verticalLineLeft)
        NSLayoutConstraint.activate([
            verticalLineLeft.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalLineLeft.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -4.5),
            verticalLineLeft.heightAnchor.constraint(equalToConstant: 18.0),
            verticalLineLeft.widthAnchor.constraint(equalToConstant: 3)
        ])
        
        addSubview(verticalLineRight)
        NSLayoutConstraint.activate([
            verticalLineRight.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalLineRight.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 4.5),
            verticalLineRight.heightAnchor.constraint(equalToConstant: 18.0),
            verticalLineRight.widthAnchor.constraint(equalToConstant: 3)
        ])
 
        let borderPath = UIBezierPath(arcCenter: CGPoint(x: 30, y: 30), radius: 21, startAngle:0, endAngle: 2 * Double.pi, clockwise: true)
        circleLayer.path = borderPath.cgPath
        circleLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = 4
        circleLayer.frame = self.bounds
        layer.addSublayer(circleLayer)
        
        layer.addSublayer(progressLayer)
        
    }
    
    public func setProgress(_ progress: Float){
        print("video state view set progress : ", progress)
        if progress < 1.0 && state == .VideoPlay {
            state = .VideoDownload
        }
        let center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        let start = -0.5 * Float.pi
        let end = progress * Float.pi
        print("video state center :", center)
        
        let progressPath = UIBezierPath(arcCenter: center, radius: 21, startAngle: CGFloat(start), endAngle: CGFloat(end), clockwise: true)
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4
        if progress >= 1.0 && state == .VideoDownload {
            state = .VideoPlay
        }
    }
    
    

}
