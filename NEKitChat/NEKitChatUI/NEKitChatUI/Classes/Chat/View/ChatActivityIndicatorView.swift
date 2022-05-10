
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

enum QChatSendMessageStatus {
    case successed
    case sending
    case failed
}

class ChatActivityIndicatorView: UIView {

    public var messageStatus:QChatSendMessageStatus? {
        didSet {
//            print("messageStatus:\(messageStatus)")
            
            failBtn.isHidden = true
            activity.isHidden = true
            activity.stopAnimating()

            switch messageStatus {
            case .sending:
                self.isHidden = false
                activity.isHidden = false
                failBtn.isHidden = true
                activity.startAnimating()
                break
            case .failed:
                self.isHidden = false
                activity.isHidden = true
                failBtn.isHidden = false
                break
            case .successed:
                self.isHidden = true
                break
                
            default:
                print("default")
            }
        }
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonUI(){
        self.addSubview(failBtn)
        self.addSubview(activity)
        NSLayoutConstraint.activate([
            failBtn.topAnchor.constraint(equalTo:  self.topAnchor),
            failBtn.leftAnchor.constraint(equalTo: self.leftAnchor),
            failBtn.bottomAnchor.constraint(equalTo:  self.bottomAnchor),
            failBtn.rightAnchor.constraint(equalTo:  self.rightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            activity.topAnchor.constraint(equalTo:  self.topAnchor),
            activity.leftAnchor.constraint(equalTo: self.leftAnchor),
            activity.bottomAnchor.constraint(equalTo:  self.bottomAnchor),
            activity.rightAnchor.constraint(equalTo:  self.rightAnchor),
        ])
    }
    
    //MARK: lazy Method
    public lazy var failBtn:UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .center
        button .setBackgroundImage(UIImage.ne_imageNamed(name: "sendMessage_failed"), for: .normal)
        return button
    }()
    
    private lazy var activity:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView.init()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.color = .gray
        return activity
    }()

    
}
