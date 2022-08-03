
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NIMSDK
import NEKitCore

@objc class QChatBubbleButton:UIButton {
    //设置气泡背景图片
    public func setBubbleImage(image:UIImage){
       let image = image.resizableImage(withCapInsets: UIEdgeInsets.init(top: 35, left: 25, bottom: 10, right: 25))
        self.setBackgroundImage(image, for: .normal)
        self.setBackgroundImage(image, for: .highlighted)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView?.contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
//    //设置气泡背景色
//    public func setBubbleImage(color:UIColor){
//        let image = self.currentBackgroundImage
//    }
}

enum QChatMessageClickType: String {
    case message
    case LongPressMessage
    case head
    case retry
}

protocol QChatBaseCellDelegate: NSObjectProtocol{
    // click action
    func didSelectWithCell(cell:QChatBaseTableViewCell,type:QChatMessageClickType,message:NIMQChatMessage)
    
    func didClickHeader(_ message: NIMQChatMessage)
}

class QChatBaseTableViewCell: UITableViewCell {
    
    weak var delegate: QChatBaseCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public var messageFrame:QChatMessageFrame? {
        didSet {
  
            self.btnHeadImage.frame = messageFrame?.headFrame ?? CGRect.zero
            self.contentBtn.frame = messageFrame?.contentFrame ?? CGRect.zero
            
            //TODO: 头像赋值
            if let icon = messageFrame?.avatar {
                btnHeadImage.setTitle("")
                btnHeadImage.sd_setImage(with: URL.init(string: icon), completed: nil)
            }else {
                if let sendName = messageFrame?.message?.senderName {
                    btnHeadImage.setTitle(sendName)
                }else {
                    btnHeadImage.setTitle(messageFrame?.message?.from ?? "")
                }
                btnHeadImage.sd_setImage(with:nil, completed: nil)
                btnHeadImage.backgroundColor = UIColor.colorWithNumber(number: 0)
            }
 
            
            guard let msg = messageFrame?.message else {
                return
            }
            if (msg.isOutgoingMsg){
                self.contentBtn.setBubbleImage(image: UIImage.ne_imageNamed(name: "chat_message_send")!)
                // 设置消息状态 判断消息发送是否成功
                if msg.deliveryState == NIMMessageDeliveryState.delivering{
                    self.activityView.frame = CGRect.init(x: contentBtn.left - (5+20), y: contentBtn.top + (contentBtn.height - 20)/2, width: 20, height: 20)
                    self.activityView.messageStatus = .sending
                }else if msg.deliveryState == NIMMessageDeliveryState.deliveried {
                    self.activityView.messageStatus = .successed
                }else {
                    self.activityView.messageStatus = .failed
                }
                
            }else {
                self.contentBtn.setBubbleImage(image: UIImage.ne_imageNamed(name: "chat_message_receive")!)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.backgroundColor = .white
        addContentSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addContentSubviews(){
        contentView.addSubview(btnHeadImage)
        contentView.addSubview(contentBtn)
        contentView.addSubview(activityView)
    }
    
    override func draw(_ rect: CGRect) {
        btnHeadImage.addCorner(conrners: .allCorners, radius: 16)
    }
    
    private lazy var btnHeadImage:NEUserHeaderView = {
        let view = NEUserHeaderView(frame: .zero)
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(headerClick))
        return view
    }()

    public lazy var contentBtn:QChatBubbleButton = {
        let btn = QChatBubbleButton.init(frame: .zero)
        btn.addTarget(self, action: #selector(bubbleClick), for: .touchUpInside)
        return btn
    }()
    
    public lazy var activityView:QChatActivityIndicatorView = {
        let activityView = QChatActivityIndicatorView.init()
        activityView.isHidden = true
        return activityView
    }()
    
}

extension QChatBaseTableViewCell {
    
    @objc func bubbleClick(sender:UIButton){
        if let message = messageFrame?.message {
            delegate?.didSelectWithCell(cell: self, type: .message, message: message)
        }
    }
    
    @objc func headerClick(){
        NELog.infoLog("chat base cell", desc: "header click")
        if let message = messageFrame?.message {
            delegate?.didClickHeader(message)
        }
    }
}
