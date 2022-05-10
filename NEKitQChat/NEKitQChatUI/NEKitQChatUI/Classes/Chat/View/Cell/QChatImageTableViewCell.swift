
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import UIKit
import NIMSDK
class QChatImageTableViewCell: QChatBaseTableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        contentBtn.addCorner(conrners: .allCorners, radius: 8)
    }
    
    private lazy var contentImageView:UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        self.contentBtn.addSubview(imageView)
        return imageView
    }()
    
    override public var messageFrame:QChatMessageFrame? {
        didSet {
            
            let imageObject = messageFrame?.message?.messageObject as! NIMImageObject
            contentImageView.frame = CGRect.init(x: qChat_margin, y: qChat_margin, width: contentBtn.width - 2*qChat_margin, height: contentBtn.height - 2*qChat_margin)

            if let imageUrl = imageObject.url {
                contentImageView.sd_setImage(with: URL.init(string: imageUrl), placeholderImage: nil, options: .retryFailed, progress: nil, completed: nil)
            }else {
                contentImageView.image = UIImage()
            }

        }
    }
}
