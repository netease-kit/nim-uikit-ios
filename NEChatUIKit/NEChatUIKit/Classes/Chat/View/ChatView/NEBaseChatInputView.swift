
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreKit
import UIKit

@objc
public enum ChatMenuType: Int {
  case text = 0
  case audio
  case emoji
  case image
  case addMore
}

public let yxAtMsg = "yxAitMsg"
public let atRangeOffset = 1
public let atSegmentsKey = "segments"
public let atTextKey = "text"

@objcMembers
open class NEBaseChatInputView: UIView, ChatRecordViewDelegate,
  InputEmoticonContainerViewDelegate, UITextViewDelegate, NEMoreViewDelegate {
  public weak var delegate: ChatInputViewDelegate?
  public var currentType: ChatMenuType = .text
  public var currentButton: UIButton?
  public var menuHeight = 100.0
  public var contentHeight = 204.0
  public var atCache: NIMInputAtCache?

  public var atRangeCache = [String: MessageAtCacheModel]()

  public var nickAccidDic = [String: String]()

  public var textView: NETextView = {
    let textView = NETextView()
    textView.placeholderLabel.numberOfLines = 1
    textView.layer.cornerRadius = 8
    textView.font = UIFont.systemFont(ofSize: 16)
    textView.clipsToBounds = true
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .white
    textView.returnKeyType = .send
    textView.allowsEditingTextAttributes = true
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    textView.dataDetectorTypes = []
    textView.accessibilityIdentifier = "id.chatMessageInput"
    return textView
  }()

  public var stackView = UIStackView()
  var contentView = UIView()
  public var contentSubView: UIView?
  public var greyView = UIView()
  public var recordView = ChatRecordView(frame: .zero)
  public var textInput: UITextInput?

  public var textviewLeftConstraint: NSLayoutConstraint?
  public var textviewRightConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  open func commonUI() {}

  public func addRecordView() {
    currentType = .audio
    textView.resignFirstResponder()
    contentSubView?.isHidden = true
    contentSubView = recordView
    contentSubView?.isHidden = false
  }

  public func addEmojiView() {
    currentType = .emoji
    textView.resignFirstResponder()
    contentSubView?.isHidden = true
    contentSubView = emojiView
    contentSubView?.isHidden = false
  }

  public func addMoreActionView() {
    currentType = .addMore
    contentSubView?.isHidden = true
    contentSubView = chatAddMoreView
    contentSubView?.isHidden = false
  }

  // MARK: ===================== lazy method =====================

  public lazy var emojiView: UIView = {
    let backView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    let view =
      InputEmoticonContainerView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    view.delegate = self
    backView.isHidden = true

    backView.backgroundColor = UIColor.clear
    backView.addSubview(view)
    let tap = UITapGestureRecognizer()
    backView.addGestureRecognizer(tap)
    tap.addTarget(self, action: #selector(missClickEmoj))
    return backView
  }()

  public lazy var chatAddMoreView: NEChatMoreActionView = {
    let view = NEChatMoreActionView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    view.delegate = self
    return view
  }()

  public func textViewDidChange(_ textView: UITextView) {
    delegate?.textFieldDidChange(textView)
  }

  public func textViewDidEndEditing(_ textView: UITextView) {
    delegate?.textFieldDidEndEditing(textView)
  }

  public func textViewDidBeginEditing(_ textView: UITextView) {
    delegate?.textFieldDidBeginEditing(textView)
  }

  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    currentType = .text
    return true
  }

  public func checkRemoveAtMessage(range: NSRange, attribute: NSAttributedString) -> NSRange? {
    var temRange: NSRange?
    let start = range.location
//    let end = range.location + range.length
    attribute.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, attribute.length)
    ) { value, findRange, stop in
      guard let findColor = value as? UIColor else {
        return
      }
      if isEqualToColor(findColor, UIColor.ne_blueText) == false {
        return
      }
      if findRange.location <= start, start < findRange.location + findRange.length + atRangeOffset {
        temRange = NSMakeRange(findRange.location, findRange.length + atRangeOffset)
        stop.pointee = true
      }

//      if (findRange.location <= start && start < findRange.location + findRange.length + atRangeOffset) ||
//        (findRange.location < end && end <= findRange.location + findRange.length + atRangeOffset) {
//        temRange = NSMakeRange(findRange.location, findRange.length + atRangeOffset)
//        stop.pointee = true
//      }
    }
    return temRange
  }

  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                       replacementText text: String) -> Bool {
    print("text view range : ", range)
    print("select range : ", textView.selectedRange)
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]

    if text == "\n" {
      guard var realText = getRealSendText(textView.attributedText) else {
        return true
      }
      if realText.trimmingCharacters(in: .whitespaces).isEmpty {
        realText = ""
      }
      delegate?.sendText(text: realText, attribute: textView.attributedText)
      textView.text = ""
      return false
    }

    if textView.attributedText.length == 0, let pasteString = UIPasteboard.general.string, text.count > 0 {
      if pasteString == text {
        let muta = NSMutableAttributedString(string: text)
        muta.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_darkText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0)], range: NSMakeRange(0, text.count))
        textView.attributedText = muta
        textView.selectedRange = NSMakeRange(text.count - 1, 0)
        return false
      }
    }

    if text.count == 0 {
//      let selectRange = textView.selectedRange
      let temRange = checkRemoveAtMessage(range: range, attribute: textView.attributedText)

      if let findRange = temRange {
        let mutableAttri = NSMutableAttributedString(attributedString: textView.attributedText)
        if mutableAttri.length >= findRange.location + findRange.length {
          mutableAttri.removeAttribute(NSAttributedString.Key.foregroundColor, range: findRange)
          mutableAttri.removeAttribute(NSAttributedString.Key.font, range: findRange)
          if range.length == 1 {
            mutableAttri.replaceCharacters(in: findRange, with: "")
          }
          if mutableAttri.length <= 0 {
            textView.attributedText = nil
          } else {
            textView.attributedText = mutableAttri
          }
          textView.selectedRange = NSMakeRange(findRange.location, 0)
        }
        return false
      }
      return true
    } else {
      delegate?.textChanged(text: text)
    }

    return true
  }

  public func textViewDidChangeSelection(_ textView: UITextView) {
    print("textViewDidChangeSelection")
    let range = textView.selectedRange
    if let findRange = checkRemoveAtMessage(range: range, attribute: textView.attributedText) {
      textView.selectedRange = NSMakeRange(findRange.location + findRange.length, 0)
    }
  }

  @available(iOS 10.0, *)
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    print("action : ", interaction)

    return true
  }

//    @available(iOS 10.0, *)
//    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//
//        return true
//    }

  public func buttonEvent(button: UIButton) {
    button.isSelected = !button.isSelected
    if button.tag - 5 != 2, button != currentButton {
      currentButton?.isSelected = false
      currentButton = button
    }

    switch button.tag - 5 {
    case 0:
      addRecordView()
    case 1:
      addEmojiView()
    case 2:
      button.isSelected = true
    case 3:
      addMoreActionView()
    default:
      print("default")
    }
    delegate?.willSelectItem(button: button, index: button.tag - 5)
  }

  // MARK: InputEmoticonContainerViewDelegate

  public func selectedEmoticon(emoticonID: String, emotCatalogID: String, description: String) {
    if emoticonID.isEmpty { // 删除键
      textView.deleteBackward()
      print("delete ward")
    } else {
      if let font = textView.font {
        let attribute = NEEmotionTool.getAttWithStr(
          str: description,
          font: font,
          CGPoint(x: 0, y: -4)
        )
        print("attribute : ", attribute)
        let mutaAttribute = NSMutableAttributedString()
        if let origin = textView.attributedText {
          mutaAttribute.append(origin)
        }
        attribute.enumerateAttribute(
          NSAttributedString.Key.attachment,
          in: NSMakeRange(0, attribute.length)
        ) { value, range, stop in
          if let neAttachment = value as? NEEmotionAttachment {
            print("ne attachment bounds ", neAttachment.bounds)
          }
        }
        mutaAttribute.append(attribute)
        mutaAttribute.addAttribute(
          NSAttributedString.Key.font,
          value: font,
          range: NSMakeRange(0, mutaAttribute.length)
        )
        textView.attributedText = mutaAttribute
        textView.scrollRangeToVisible(NSMakeRange(textView.attributedText.length, 1))
      }
    }
  }

  public func didPressSend(sender: UIButton) {
    guard let text = getRealSendText(textView.attributedText) else {
      return
    }
    delegate?.sendText(text: text, attribute: textView.attributedText)
    textView.text = ""
    atCache?.clean()
  }

  public func stopRecordAnimation() {
    greyView.isHidden = true
    recordView.stopRecordAnimation()
  }

  // MARK: NEMoreViewDelagate

  public func moreViewDidSelectMoreCell(moreView: NEChatMoreActionView, cell: NEInputMoreCell) {
    delegate?.didSelectMoreCell(cell: cell)
  }

  //    MARK: ChatRecordViewDelegate

  public func startRecord() {
    greyView.isHidden = false
    delegate?.startRecord()
  }

  public func moveOutView() {
    delegate?.moveOutView()
  }

  public func moveInView() {
    delegate?.moveInView()
  }

  public func endRecord(insideView: Bool) {
    greyView.isHidden = true
    delegate?.endRecord(insideView: insideView)
  }

//  func textFieldChangeNoti() {
//    delegate?.textFieldDidChange(textField)
//  }

  func getRealSendText(_ attribute: NSAttributedString) -> String? {
    let muta = NSMutableString()

    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, range, stop in

      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment,
         let des = neAttachment.emotion?.tag {
        muta.append(des)
      } else {
        let sub = attribute.attributedSubstring(from: range).string
        muta.append(sub)
      }
    }
    return muta as String
  }

  public func getRemoteExtension(_ attri: NSAttributedString?) -> [String: Any]? {
    guard let attribute = attri else {
      return nil
    }
    var atDic = [String: [String: Any]]()
    let string = attribute.string
    attribute.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, attribute.length)
    ) { value, findRange, stop in
      guard let findColor = value as? UIColor else {
        return
      }
      if isEqualToColor(findColor, UIColor.ne_blueText) == false {
        return
      }
      if let range = Range(findRange, in: string) {
        let text = string[range]
        let model = MessageAtInfoModel()
        print("range text : ", String(text))
        model.start = findRange.location
        model.end = model.start + findRange.length
        var dic: [String: Any]?
        var array: [Any]?
        if let accid = nickAccidDic[String(text)] {
          if let atCacheDic = atDic[accid] {
            dic = atCacheDic
          } else {
            dic = [String: Any]()
          }

          if let atCacheArray = dic?[atSegmentsKey] as? [Any] {
            array = atCacheArray
          } else {
            array = [Any]()
          }

          if let object = model.yx_modelToJSONObject() {
            array?.append(object)
          }
          dic?[atSegmentsKey] = array
          dic?[atTextKey] = String(text) + " "
          dic?[#keyPath(MessageAtCacheModel.accid)] = accid
          atDic[accid] = dic
        }
      }
    }
    if atDic.count > 0 {
      return [yxAtMsg: atDic]
    }
    return nil
  }

  public func getAtRemoteExtension() -> [String: Any]? {
    var atDic = [String: Any]()
    NELog.infoLog(className(), desc: "at range cache : \(atRangeCache)")
    atRangeCache.forEach { (key: String, value: MessageAtCacheModel) in
      if let userValue = atDic[value.accid] as? [String: AnyObject], var array = userValue[atSegmentsKey] as? [Any], let object = value.atModel.yx_modelToJSONObject() {
        array.append(object)
        if var dic = atDic[value.accid] as? [String: Any] {
          dic[atSegmentsKey] = array
          atDic[value.accid] = dic
        }
      } else if let object = value.atModel.yx_modelToJSONObject() {
        var array = [Any]()
        array.append(object)
        var dic = [String: Any]()
        dic[atTextKey] = value.text
        dic[atSegmentsKey] = array
        atDic[value.accid] = dic
      }
    }
    NELog.infoLog(className(), desc: "at dic value : \(atDic)")
    if atDic.count > 0 {
      return [yxAtMsg: atDic]
    }
    return nil
  }

  public func cleartAtCache() {
    nickAccidDic.removeAll()
  }

  private func convertRangeToNSRange(range: UITextRange?) -> NSRange? {
    if let start = range?.start, let end = range?.end {
      let startIndex = textInput?.offset(from: textInput?.beginningOfDocument ?? start, to: start) ?? 0
      let endIndex = textInput?.offset(from: textInput?.beginningOfDocument ?? end, to: end) ?? 0
      return NSMakeRange(startIndex, endIndex - startIndex)
    }
    return nil
  }

  private func isEqualToColor(_ color1: UIColor, _ color2: UIColor) -> Bool {
    guard let components1 = color1.cgColor.components,
          let components2 = color2.cgColor.components,
          color1.cgColor.colorSpace == color2.cgColor.colorSpace,
          color1.cgColor.numberOfComponents == 4,
          color2.cgColor.numberOfComponents == 4
    else {
      return false
    }

    return components1[0] == components2[0] && // Red
      components1[1] == components2[1] && // Green
      components1[2] == components2[2] && // Blue
      components1[3] == components2[3] // Alpha
  }

  func missClickEmoj() {
    print("click one px space")
  }
}
