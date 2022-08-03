//
//  CustomerSampleAttachment.swift
//  NEKitChatUI
//
//  Created by vvj on 2022/6/17.
//

import UIKit
import NIMSDK

public class CustomAttachment: NSObject,NIMCustomAttachment {
    
    public var type = 0
    
    public var goodsName = "name"
    
    public var goodsURL = "url"
    
    public func encode() -> String {

        let info = ["goodsName":goodsName,"goodsURL":goodsURL,"type":type] as [String : Any]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
        var content = ""
        if let data = jsonData {
            content = String.init(data: data, encoding: .utf8) ?? ""
        }
        return content
    }

}


public class CustomAttachmentDecoder:NSObject, NIMCustomAttachmentCoding {
    
    public func decodeAttachment(_ content: String?) -> NIMCustomAttachment? {
        
        var attachment: NIMCustomAttachment? = nil
        let data = content?.data(using: .utf8)
        guard let dataInfo = data  else {
            return attachment
        }
       
        let infoDict = try? JSONSerialization.jsonObject(with: dataInfo, options: .mutableContainers)
        let infoResult = infoDict as? [String:Any]
        let type = infoResult?["type"] as? Int
        
        switch type {
        case 0:
            attachment = decodeCustomMessage(info: infoDict as? [String : Any] ?? [String():String()])
        default:
            print("test")
        }
        
        return attachment
    }
    
    
    func decodeCustomMessage(info:[String:Any]) -> CustomAttachment{
        let customAttachment = CustomAttachment()
        customAttachment.goodsName = info["goodsName"]  as? String ?? ""
        customAttachment.goodsURL = info["goodsURL"]  as? String  ?? ""
        if let type = info["type"] as? Int{
            customAttachment.type = type
        }

        return customAttachment
    }
}
