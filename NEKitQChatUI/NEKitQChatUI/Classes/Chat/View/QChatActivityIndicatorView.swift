
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

enum QChatSendMessageStatus {
    case successed
    case sending
    case failed
}

class QChatActivityIndicatorView: UIButton {

    public var messageStatus:QChatSendMessageStatus? {
        didSet {
            
            failBtn.isHidden = true
            activity.isHidden = true
            activity.stopAnimating()

            switch messageStatus {
            case .sending:
                self.isHidden = false
                activity.isHidden = false
                activity.startAnimating()
                break
            case .failed:
                self.isHidden = false
                failBtn.isHidden = false
                break
            case .successed:
                self.isHidden = true
                break
                
            default:
                print("")
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
    private lazy var failBtn:UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
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
