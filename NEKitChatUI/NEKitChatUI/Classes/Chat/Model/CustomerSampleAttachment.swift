//
//  CustomerSampleAttachment.swift
//  NEKitChatUI
//
//  Created by vvj on 2022/6/17.
//

import UIKit
import NIMSDK

public class CustomerAttachment: NSObject,NIMCustomAttachment {
    
    var title = "custAttachment"
    
    var subTitle = "subCustAttachment"
    
    public func encode() -> String {
        return ""
    }
    
    
}


public class CustomerAttachmentDecoder:NSObject, NIMCustomAttachmentCoding {
    
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
    
    
    func decodeCustomMessage(info:[String:Any]) -> CustomerAttachment{
        let customAttachment = CustomerAttachment()
        customAttachment.title = info["title"]  as? String ?? ""
        customAttachment.subTitle = info["subTitle"]  as? String  ?? ""
        return customAttachment
    }
}
