
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NIMSDK
public class QChatMessageFrame: NSObject {
    //是否显示时间
    public var showTime:Bool = false
    //具体时间
    public var time:String?
    //是否显示头像
    public var showAvatar:Bool = true
    //用户头像地址
    public var avatar: String?
    //nickname
    public var nickname: String?
   //发送者是否为自己
//    public var isSender:Bool?
    //头像frame
    public var headFrame:CGRect?
    //内容frame
    public var contentFrame:CGRect?
    //cell整体高度
    public var cellHeight:CGFloat = 0.0
    //X初始位置
    public var startX:CGFloat = 0.0
   
//    public init(isSender:Bool) {
//        self.isSender = isSender
//    }
    
    public var message:NIMQChatMessage?{
        didSet {

            var contentSize = CGSize.zero
            
            switch message?.messageType {
            case .text://计算文本
                
                contentSize = String.getTextRectSize(message?.text ?? "", font: DefaultTextFont(16), size: CGSize.init(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude))
                if contentSize.height < qChat_min_h {//小于一行高度，就保持一行
                    contentSize.height = qChat_min_h
                }
                contentSize.width += 2*qChat_margin;
                break
            case .image://计算图片类型
                if let imageObject = message?.messageObject,imageObject.isKind(of: NIMImageObject.self) {
                    let obj = (imageObject as! NIMImageObject)
                    contentSize = QChatMessageHelper.getSizeWithMaxSize(qChat_pic_size, size: obj.size, miniWH: qChat_min_h)
                }else {
                    contentSize = qChat_pic_size
                }
                
                break
            default:
                print("others")
            }

            //计算头像
            var headFrameX = qChat_cell_margin
            let headFrameY = qChat_margin
            
            guard let msg = message else {
                return
            }
            
            if (msg.isOutgoingMsg) {//消息发送者
                headFrameX = kScreenWidth - headFrameX - qChat_headWH
            }
            headFrame = CGRect.init(x: headFrameX, y: headFrameY, width: qChat_headWH, height: qChat_headWH)
                
            let viewY = qChat_margin

            //聊天气泡的frame
            var viewX = 0.0
            
            viewX = headFrame!.maxX + qChat_margin;
            if (msg.isOutgoingMsg) {//消息发送者
                viewX = kScreenWidth - contentSize.width - qChat_margin - qChat_headWH - qChat_cell_margin
            }
            contentFrame = CGRect.init(x: viewX, y: viewY, width: contentSize.width, height: contentSize.height)

            //cell 高度
            cellHeight = contentSize.height + qChat_margin
            
            // 起始位置
//            _startX = isSend ? 0 : kChat_angle_w;
            startX = 0
            
            
            
        }
    }
    
    

}
