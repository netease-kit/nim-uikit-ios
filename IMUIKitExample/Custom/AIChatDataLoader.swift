
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CommonCrypto
import Foundation
import NEChatKit
import NEChatUIKit
import NIMSDK

@objcMembers
public class NECommonResult: NSObject {
  /// 错误码
  public var code = -1
  /// 原始数据
  public var originData: NSDictionary?
}

@objcMembers
open class AIChatDataLoader: NSObject {
  public static var messages: [V2NIMMessage]?
  public static var lastMessage: V2NIMMessage?
  /// AI 助聊上下文条数
  public let aiChatContentsCount: Int = 5

  public static func loadData(_ messages: [V2NIMMessage]?,
                              _ completion: @escaping ([AIChatCellModel]?, Error?) -> Void) {
    if messages != nil {
      self.messages = messages
    }

    lastMessage = AIChatDataLoader.getLastTextMessage(messages)

    getSquareData(messages, lastMessage) { error, result in
      var models = [AIChatCellModel]()
      if let data = result?.originData?["data"] as? [String: Any],
         let items = data["items"] as? [[String: Any]] {
        for (index, item) in items.enumerated() {
          if index % 3 == 0 {
            models.append(AIChatCellModel(tagTitle: item["style_name"] as? String,
                                          tagTitleColor: UIColor(hexString: "#F159A2"),
                                          tagTitleBackgroundColor: UIColor(hexString: "#FFE8F3"),
                                          contentTitle: item["answer"] as? String))
          }

          if index % 3 == 1 {
            models.append(AIChatCellModel(tagTitle: item["style_name"] as? String,
                                          tagTitleColor: UIColor(hexString: "#E75257"),
                                          tagTitleBackgroundColor: UIColor(hexString: "#FFE8E8"),
                                          contentTitle: item["answer"] as? String))
          }

          if index % 3 == 2 {
            models.append(AIChatCellModel(tagTitle: item["style_name"] as? String,
                                          tagTitleColor: UIColor(hexString: "#598CF1"),
                                          tagTitleBackgroundColor: UIColor(hexString: "#E8F4FF"),
                                          contentTitle: item["answer"] as? String))
          }
        }
      }
      completion(models, error)
    }
  }

  /// 取最后 N 条文本消息
  open func getAIChatContents(_ messages: [V2NIMMessage]?) -> [V2NIMMessage]? {
    let textMessages = messages?.filter { $0.messageType == .MESSAGE_TYPE_TEXT && $0.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED }
    return textMessages?.suffix(aiChatContentsCount)
  }

  /// 取对方（非自己）发送的最后一条文本消息
  public static func getLastTextMessage(_ messages: [V2NIMMessage]?) -> V2NIMMessage? {
    let textMessages = messages?.filter { $0.messageType == .MESSAGE_TYPE_TEXT && $0.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED && $0.isSelf == false }
    return textMessages?.last
  }

  public static func getSquareData(_ messages: [V2NIMMessage]?,
                                   _ lastMessage: V2NIMMessage?,
                                   _ completion: @escaping (Error?, NECommonResult?) -> Void) {
    let uri = "im/ai/chat_assistant/v1/chat_assist"

    if let request = getRequest(uri, messages, lastMessage) {
      // 发送请求
      dataTaskCallBackInMain(with: request, completionHandler: { data, response, error in
        if error == nil {
          guard let d = data else {
            completion(getError(msg: nil, code: nil), nil)
            return
          }
          if let result = parseResult(data: d) {
            completion(nil, result)
          } else {
            completion(getError(msg: nil, code: nil), nil)
          }
        } else {
          completion(error, nil)
        }
      })
    } else {
      completion(getError(msg: nil, code: nil), nil)
    }
  }

  private static func getRequest(_ uri: String,
                                 _ messages: [V2NIMMessage]?,
                                 _ lastMessage: V2NIMMessage?) -> URLRequest? {
    let requestUrl = getHost() + uri
    guard let url = URL(string: requestUrl) else {
      return nil
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(AppKey.appKey, forHTTPHeaderField: "appkey")
    request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue(account, forHTTPHeaderField: "accountId")
    request.setValue(token, forHTTPHeaderField: "accessToken")

    var bodyDic: [String: Any] = [
      "style_list": ["warm", "hot", "smart"],
      "sender_id": account,
      "receiver_id": ChatRepo.sessionId,
    ]

    if let lastText = lastMessage?.text {
      bodyDic["receiver_last_message"] = lastText
    }

    var history = [[String: Any]]()
    for message in messages ?? [] {
      if let senderId = message.senderId,
         let text = message.text {
        history.append([
          "sender_id": senderId,
          "text": text,
        ])
      }
    }

    bodyDic["history"] = history

    request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDic)

    return request
  }

  private static func getError(msg: String?, code: Int?) -> NSError {
    if let message = msg, let errorCode = code {
      return NSError(domain: "com.netease.im", code: errorCode, userInfo: [NSLocalizedDescriptionKey: message])
    }
    return NSError(domain: "com.netease.im", code: -1, userInfo: [NSLocalizedDescriptionKey: "operation failed"])
  }

  private static func parseResult(data: Data) -> NECommonResult? {
    do {
      print("json string : ", String(data: data, encoding: .utf8) ?? "")
      if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
        let result = NECommonResult()
        if let code = jsonObject["code"] as? Int {
          result.code = code
        }
//          if let msg = jsonObject["msg"] as? String {
//            result.msg = msg
//          }
        result.originData = jsonObject
        return result
      }
    } catch {
      print("Error: \(error.localizedDescription)")
    }
    return nil
  }

  private static func dataTaskCallBackInMain(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, NSError?) -> Void) {
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        completionHandler(data, response, error as NSError?)
      }
    }
    task.resume()
  }

  private static func getHost() -> String {
    "https://yiyong.netease.im/"
  }
}
