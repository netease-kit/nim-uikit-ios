
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objc
public enum ChatMenuType: Int {
  case text = 0
  case audio
  case emoji
  case image
  case addMore
}

@objc
public enum ChatInputMode: Int {
  case normal
  case multipleSend
  case multipleReturn
}

public let yxAtMsg = "yxAitMsg"
public let atRangeOffset = 1
public let atSegmentsKey = "segments"
public let atTextKey = "text"

@objc
public protocol ChatInputMultilineDelegate: NSObjectProtocol {
  func expandButtonDidClick()
  func didHideMultipleButtonClick()

  func aiChatButtonDidClick(_ aiChatViewController: AIChatViewController, _ open: Bool)
  func aiChatMessageDidClick(_ text: String)
}

@objcMembers
open class NEBaseChatInputView: UIView, ChatRecordViewDelegate,
  InputEmoticonContainerViewDelegate, UITextViewDelegate, NEMoreViewDelegate, UITextFieldDelegate {
  public weak var multipleLineDelegate: ChatInputMultilineDelegate?

  public weak var delegate: ChatInputViewDelegate?
  public var currentType: ChatMenuType = .text
  public var currentButton: UIButton?
  public var menuHeight = 100.0
  public var contentHeight = 204.0

  public var atRangeCache = [String: MessageAtCacheModel]()

  public var nickAccidList = [String]()
  public var nickAccidDic = [String: String]()

  public var chatInpuMode = ChatInputMode.normal
  public var conversationType = V2NIMConversationType.CONVERSATION_TYPE_UNKNOWN

  // 换行输入框 标题限制字数
  public var textLimit = 20

  public var textView: NETextView = {
    let textView = NETextView()
    textView.placeholderLabel.numberOfLines = 1
    textView.layer.cornerRadius = 8
    textView.font = UIFont.systemFont(ofSize: 16)
    textView.clipsToBounds = true
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .clear
    textView.returnKeyType = .send
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: ChatUIConfig.shared.messageProperties.inputTextColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ChatUIConfig.shared.messageProperties.inputTextColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
    textView.dataDetectorTypes = []
    textView.accessibilityIdentifier = "id.chatMessageInput"
    return textView
  }()

  lazy var backView: UIView = {
    let back = UIView()
    back.translatesAutoresizingMaskIntoConstraints = false
    back.backgroundColor = .clear
    back.clipsToBounds = true
    back.layer.cornerRadius = 8
    return back
  }()

  // 展开按钮
  public var expandButton: ExpandButton? = {
    let button = IMKitConfigCenter.shared.enableRichTextMessage ? ExpandButton() : nil
    button?.translatesAutoresizingMaskIntoConstraints = false
    button?.backgroundColor = .clear
    button?.accessibilityIdentifier = "id.chatExpandButton"
    return button
  }()

  // 助聊按钮
  public var aiChatButton: ExpandButton? = {
    let button = IMKitConfigCenter.shared.enableAIChatHelper ? ExpandButton() : nil
    button?.translatesAutoresizingMaskIntoConstraints = false
    button?.backgroundColor = .clear
    button?.accessibilityIdentifier = "id.aiChatButton"
    return button
  }()

  public lazy var stackView: UIStackView = {
    let view = UIStackView()
    view.accessibilityIdentifier = "id.chatInputStackView"
    return view
  }()

  var contentView = UIView()
  public var contentSubView: UIView?
  public var greyView = UIView()
  public var recordView = ChatRecordView(frame: .zero)
  public var textInput: UITextInput?

  public var textviewLeftConstraint: NSLayoutConstraint?
  public var textviewRightConstraint: NSLayoutConstraint?

  public var multipleLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.clipsToBounds = false
    view.isHidden = true

    view.layer.cornerRadius = 6.0
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.5
    view.layer.shadowOffset = CGSize(width: 3, height: 3)
    view.layer.shadowRadius = 5
    view.layer.masksToBounds = false
    return view
  }()

  public var titleField: UITextField = {
    let textField = UITextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.font = UIFont.systemFont(ofSize: 18.0)
    textField.textColor = .ne_darkText
    textField.returnKeyType = .send
    textField.attributedPlaceholder = NSAttributedString(string: chatCoreLoader.localizable("multiple_line_placleholder"), attributes: [NSAttributedString.Key.foregroundColor: ChatUIConfig.shared.messageProperties.inputTextColor])
    return textField
  }()

  public var multipleLineExpandButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    return button
  }()

  public var multipleSendButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    button.setImage(chatCoreLoader.loadImage("multiple_send_image"), for: .normal)
    return button
  }()

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

  public var aiChatViewControllerTopConstant: CGFloat = 54
  public lazy var aiChatViewController: AIChatViewController = {
    let view = AIChatViewController()
    view.view.translatesAutoresizingMaskIntoConstraints = false
    view.view.clipsToBounds = true
    view.delegate = self
    return view
  }()

  public var multipleLineViewHeight: NSLayoutConstraint?

  public init(_ conversationType: V2NIMConversationType) {
    super.init(frame: .zero)
    self.conversationType = conversationType
    commonUI()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  open func commonUI() {
    accessibilityIdentifier = "id.chatInputView"
  }

  open func addRecordView() {
    currentType = .audio
    textView.resignFirstResponder()
    titleField.resignFirstResponder()
    contentSubView?.isHidden = true
    contentSubView = recordView
    contentSubView?.isHidden = false
  }

  open func addEmojiView() {
    currentType = .emoji
    textView.resignFirstResponder()
    titleField.resignFirstResponder()

    contentSubView?.isHidden = true
    contentSubView = emojiView
    contentSubView?.isHidden = false
  }

  open func addMoreActionView() {
    currentType = .addMore
    textView.resignFirstResponder()
    titleField.resignFirstResponder()

    contentSubView?.isHidden = true
    contentSubView = chatAddMoreView
    contentSubView?.isHidden = false
  }

  open func sendText() {
    guard let text = getRealSendText(textView.attributedText) else {
      return
    }
    delegate?.sendText(text: text, attribute: textView.attributedText)
    titleField.text = ""
    textView.text = ""
  }

  open func textViewDidChange(_ textView: UITextView) {
    textView.attributedText.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, textView.attributedText.length)
    ) { value, findRange, stop in
      guard let findColor = value as? UIColor else {
        return
      }

      if isEqualToColor(findColor, UIColor.ne_normalTheme) {
        let string = textView.attributedText.string
        if let range = Range(findRange, in: string) {
          let text = String(string[range])
          if nickAccidDic[text] == nil {
            let mutableAttri = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableAttri.addAttribute(.foregroundColor, value: ChatUIConfig.shared.messageProperties.inputTextColor, range: findRange)
            textView.attributedText = mutableAttri
          }
        }
      }
    }

    delegate?.textFieldDidChange(textView.text)
  }

  open func textViewDidEndEditing(_ textView: UITextView) {
    delegate?.textFieldDidEndEditing(textView.text)
  }

  open func textViewDidBeginEditing(_ textView: UITextView) {
    delegate?.textFieldDidBeginEditing(textView.text)
  }

  open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    currentType = .text
    return true
  }

  open func checkRemoveAtMessage(range: NSRange, attribute: NSAttributedString) -> NSRange? {
    var temRange: NSRange?
    let start = range.location
    attribute.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, attribute.length)
    ) { value, findRange, stop in
      guard let findColor = value as? UIColor else {
        return
      }

      if isEqualToColor(findColor, UIColor.ne_normalTheme) == false {
        return
      }

      if findRange.location <= start, start < findRange.location + findRange.length + atRangeOffset {
        temRange = NSMakeRange(findRange.location, findRange.length + atRangeOffset)
        stop.pointee = true
      }
    }
    return temRange
  }

  // 查找at消息位置并且根据光标位置距离高亮前段或者后端更近判断光标最终显示在前还是在后
  open func findShowPosition(range: NSRange, attribute: NSAttributedString) -> NSRange? {
    var showRange: NSRange?
    let start = range.location
    attribute.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, attribute.length)
    ) { value, findRange, stop in
      guard let findColor = value as? UIColor else {
        return
      }
      if isEqualToColor(findColor, UIColor.ne_normalTheme) == false {
        return
      }
      let findStart = findRange.location
      let findEnd = findRange.location + findRange.length + atRangeOffset
      if findStart <= start, start < findEnd {
        if findEnd - start > start - findStart {
          showRange = NSMakeRange(findStart, 0)
        } else {
          showRange = NSMakeRange(findRange.location, findRange.length + atRangeOffset)
        }
        stop.pointee = true
      }
    }
    return showRange
  }

  open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                     replacementText text: String) -> Bool {
    textView.typingAttributes = [NSAttributedString.Key.foregroundColor: ChatUIConfig.shared.messageProperties.inputTextColor,
                                 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]

    if chatInpuMode == .normal || chatInpuMode == .multipleSend, text == "\n" {
      guard var realText = getRealSendText(textView.attributedText) else {
        delegate?.textViewDidChange()
        return true
      }
      if realText.trimmingCharacters(in: .whitespaces).isEmpty {
        realText = ""
      }
      delegate?.sendText(text: realText, attribute: textView.attributedText)
      titleField.text = ""
      textView.text = ""
      return false
    }

    // 处理粘贴，表情解析（存在表情则字符数量>=3）
    if text.count >= 3,
       (NEEmotionTool.getRegularArray(str: text)?.count ?? 0) > 0 {
      let mutaString = NSMutableAttributedString(attributedString: textView.attributedText)
      let addString = NEEmotionTool.getAttWithStr(str: text, font: .systemFont(ofSize: 16))
      mutaString.replaceCharacters(in: range, with: addString)
      textView.attributedText = mutaString
      textView.accessibilityValue = text
      DispatchQueue.main.async {
        textView.selectedRange = NSMakeRange(range.location + addString.length, 0)
      }
      delegate?.textViewDidChange()
      textView.font = UIFont.systemFont(ofSize: 16)
      return false
    }

    if text.count == 0, range.length > 0 {
      let temRange = checkRemoveAtMessage(range: range, attribute: textView.attributedText)
      if let findRange = temRange {
        let mutableAttri = NSMutableAttributedString(attributedString: textView.attributedText)
        if mutableAttri.length >= findRange.location + findRange.length {
          let string = textView.attributedText.string
          let rawRange = NSRange(location: findRange.location, length: findRange.length - atRangeOffset)
          if let range = Range(rawRange, in: string) {
            let text = String(string[range])
            if let nick = nickAccidDic[text] {
              nickAccidDic[text] = nil
              nickAccidList.removeAll { $0 == nick }
            }
          }

          if range.length == 1 {
            mutableAttri.replaceCharacters(in: findRange, with: "")
          } else if range.length - 1 > 0,
                    range.location >= findRange.location,
                    range.location <= findRange.location + findRange.length {
            mutableAttri.replaceCharacters(in: NSRange(location: range.location + 1, length: range.length - 1), with: "")
          }

          if mutableAttri.length <= 0 {
            textView.attributedText = nil
          } else {
            textView.attributedText = mutableAttri
          }

          if range.length == 1 {
            textView.selectedRange = NSMakeRange(findRange.location, 0)
          } else {
            textView.selectedRange = NSMakeRange(range.location + 1, 0)
          }
        }
        return false
      }
      delegate?.textViewDidChange()
      return true
    } else {
      delegate?.textChanged(text: text)
    }
    delegate?.textViewDidChange()
    return true
  }

  open func textViewDidChangeSelection(_ textView: UITextView) {
    let range = textView.selectedRange
    if let findRange = findShowPosition(range: range, attribute: textView.attributedText) {
      textView.selectedRange = NSMakeRange(findRange.location + findRange.length, 0)
    }

    textView.scrollRangeToVisible(NSMakeRange(textView.selectedRange.location, 1))
    textView.accessibilityValue = getRealSendText(textView.attributedText)
  }

  @available(iOS 10.0, *)
  open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    print("action : ", interaction)

    return true
  }

  open func buttonEvent(button: UIButton) {
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

  // MARK: NIMInputEmoticonContainerViewDelegate

  open func selectedEmoticon(emoticonID: String, emotCatalogID: String, description: String) {
    if emoticonID.isEmpty { // 删除键
      delegate?.textViewDidChange()
      textView.deleteBackward()
    } else {
      let range = textView.selectedRange
      let attribute = NEEmotionTool.getAttWithStr(str: description, font: .systemFont(ofSize: 16))
      let mutaAttribute = NSMutableAttributedString(attributedString: textView.attributedText)
      mutaAttribute.insert(attribute, at: range.location)
      textView.attributedText = mutaAttribute
      textView.selectedRange = NSMakeRange(range.location + attribute.length, 0)
      textView.font = UIFont.systemFont(ofSize: 16)

      textViewDidChange(textView)
      delegate?.textViewDidChange()
    }
  }

  /// 点击富文本图片
  open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    textView.becomeFirstResponder()

    var offset = characterRange.location
    // 修复iOS 14.1，点击空白识别为点击最后一个富文本图片的问题，待优化
    if characterRange.location + characterRange.length == textView.text.count {
      offset += 1
    }

    if let newPosition = textView.position(from: textView.beginningOfDocument, offset: offset) {
      textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
    }

    return true
  }

  /// 点击表情列表中的【发送】
  open func didPressSend(sender: UIButton) {
    sendText()
  }

  open func stopRecordAnimation() {
    greyView.isHidden = true
    recordView.stopRecordAnimation()
  }

  // MARK: NEMoreViewDelagate

  open func moreViewDidSelectMoreCell(moreView: NEChatMoreActionView, cell: NEInputMoreCell) {
    delegate?.didSelectMoreCell(cell: cell)
  }

  //    MARK: ChatRecordViewDelegate

  open func startRecord() {
    greyView.isHidden = false
    delegate?.startRecord()
  }

  open func moveOutView() {
    delegate?.moveOutView()
  }

  open func moveInView() {
    delegate?.moveInView()
  }

  open func endRecord(insideView: Bool) {
    greyView.isHidden = true
    delegate?.endRecord(insideView: insideView)
  }

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

  open func getRemoteExtension(_ attri: NSAttributedString?) -> [String: Any]? {
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
      if isEqualToColor(findColor, UIColor.ne_normalTheme) == false {
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

  open func getAtRemoteExtension(_ attri: NSAttributedString?) -> [String: Any]? {
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
      if isEqualToColor(findColor, UIColor.ne_normalTheme) == false {
        return
      }
      if let range = Range(findRange, in: string) {
        let text = string[range]
        let model = MessageAtInfoModel()
        print("range text : ", String(text))
        // 计算at前有表情导致索引新增的数量
        let expandIndex = getConvertedExtraIndex(attribute.attributedSubstring(from: NSRange(location: 0, length: findRange.location)))
        print("expand index value ", expandIndex)
        model.start = findRange.location + expandIndex
        let nameExpandCount = getConvertedExtraIndex(attribute.attributedSubstring(from: findRange))
        print("name expand index value ", nameExpandCount)
        model.end = model.start + findRange.length + nameExpandCount
        print("model start : ", model.start, " model end : ", model.end)
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

  /// 把表情转换成字符编码计算index的增量
  /// - Parameter attribute： at 文本前的文本
  func getConvertedExtraIndex(_ attribute: NSAttributedString) -> Int {
    var count = 0
    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, range, stop in
      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment {
        if let tagCount = neAttachment.emotion?.tag?.count {
          print(" \(count) getConvertedExtraIndex tag : ", neAttachment.emotion?.tag as Any)
          count = count + tagCount - 1
        }
      }
    }
    return count
  }

  open func clearAtCache() {
    nickAccidList.removeAll()
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

  open func textFieldDidEndEditing(_ textField: UITextField) {
    delegate?.textFieldDidChange(textField.text)
  }

  open func textFieldDidBeginEditing(_ textField: UITextField) {
    currentType = .text
    delegate?.textFieldDidBeginEditing(textField.text)
  }

  open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if textField == titleField {
      if string == "\n" {
        var realText = ""
        if let text = getRealSendText(textView.attributedText) {
          realText = text
        }
        delegate?.sendText(text: realText, attribute: textView.attributedText)
        titleField.text = ""
        textView.text = ""
        return false
      }
    }

    return true
  }

  open func textFieldChange() {
    delegate?.textFieldDidChange(titleField.text)
    if titleField.text?.count ?? 0 <= 0 {
      delegate?.titleTextDidClearEmpty()
    }
    guard let _ = titleField.markedTextRange else {
      if let text = titleField.text,
         text.utf16.count > textLimit {
        titleField.text = String(text.prefix(textLimit))
      }
      return
    }
  }

  func setupMultipleLineView() {
    addSubview(multipleLineView)
    multipleLineViewHeight = multipleLineView.heightAnchor.constraint(equalToConstant: 400)
    NSLayoutConstraint.activate([
      multipleLineViewHeight!,
      multipleLineView.leftAnchor.constraint(equalTo: leftAnchor),
      multipleLineView.rightAnchor.constraint(equalTo: rightAnchor),
      multipleLineView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
    ])

    multipleLineView.addSubview(titleField)
    titleField.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    titleField.delegate = self
    NSLayoutConstraint.activate([
      titleField.leftAnchor.constraint(equalTo: multipleLineView.leftAnchor, constant: 16),
      titleField.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor, constant: -56),
      titleField.topAnchor.constraint(equalTo: multipleLineView.topAnchor, constant: 5),
      titleField.heightAnchor.constraint(equalToConstant: 40),
    ])

    multipleLineView.addSubview(multipleLineExpandButton)
    NSLayoutConstraint.activate([
      multipleLineExpandButton.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor, constant: 0),
      multipleLineExpandButton.topAnchor.constraint(equalTo: multipleLineView.topAnchor, constant: 5),
      multipleLineExpandButton.widthAnchor.constraint(equalToConstant: 44),
      multipleLineExpandButton.heightAnchor.constraint(equalToConstant: 40),
    ])
    multipleLineExpandButton.addTarget(self, action: #selector(didClickHideMultipleButton), for: .touchUpInside)

    let dividerLine = UIView()
    dividerLine.translatesAutoresizingMaskIntoConstraints = false
    dividerLine.backgroundColor = UIColor(hexString: "#ECECEC")
    multipleLineView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: multipleLineView.leftAnchor),
      dividerLine.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor),
      dividerLine.topAnchor.constraint(equalTo: multipleLineView.topAnchor, constant: 236),
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    multipleLineView.addSubview(multipleSendButton)
    NSLayoutConstraint.activate([
      multipleSendButton.rightAnchor.constraint(equalTo: multipleLineView.rightAnchor, constant: -16),
      multipleSendButton.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 8),
      multipleSendButton.widthAnchor.constraint(equalToConstant: 44),
      multipleSendButton.heightAnchor.constraint(equalToConstant: 40),
    ])
    multipleSendButton.addTarget(self, action: #selector(didClickSendButton), for: .touchUpInside)
  }

  open func didClickExpandButton() {
    multipleLineDelegate?.expandButtonDidClick()
  }

  open func didClickAIChatButton() {
    aiChatButton?.isSelected = !(aiChatButton?.isSelected ?? true)
    stackView.isHidden = aiChatButton?.isSelected ?? true
    contentView.isHidden = aiChatButton?.isSelected ?? true
    contentSubView?.isHidden = aiChatButton?.isSelected ?? true

    if aiChatButton?.isSelected ?? true {
      showAIChatView()
    } else {
      hideAIChatView()
      multipleLineDelegate?.aiChatButtonDidClick(aiChatViewController, false)
    }
  }

  func showAIChatView() {
    currentButton?.isSelected = false
    setLayerContents(true)

    if let customController = ChatUIConfig.shared.aiChatViewController {
      customController(aiChatViewController)
    }

    if chatInpuMode != .multipleReturn {
      addSubview(aiChatViewController.view)
      NSLayoutConstraint.activate([
        aiChatViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
        aiChatViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        aiChatViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
        aiChatViewController.view.topAnchor.constraint(equalTo: topAnchor, constant: aiChatViewControllerTopConstant),
      ])
    }
    multipleLineDelegate?.aiChatButtonDidClick(aiChatViewController, true)
  }

  open func setLayerContents(_ open: Bool) {}

  open func hideAIChatView() {
    setLayerContents(false)
    stackView.isHidden = false
    contentView.isHidden = false
    contentSubView?.isHidden = false
    aiChatButton?.isSelected = false
    aiChatViewController.view.removeFromSuperview()
  }

  open func didClickSendButton() {
    sendText()
  }

  open func didClickHideMultipleButton() {
    multipleLineDelegate?.didHideMultipleButtonClick()
  }

  open func restoreNormalInputStyle() {
    multipleLineView.isHidden = true
    if titleField.text?.count ?? 0 > 0 {
      chatInpuMode = .multipleSend
    } else {
      chatInpuMode = .normal
    }
  }

  open func changeToMultipleLineStyle() {
    chatInpuMode = .multipleReturn
    multipleLineView.isHidden = false
  }

  open func setMuteInputStyle() {
    clearAtCache()
    expandButton?.isEnabled = false
    textView.attributedText = nil
    textView.text = nil
  }

  open func setUnMuteInputStyle() {
    expandButton?.isEnabled = true
  }
}

extension NEBaseChatInputView: AIChatViewDelegate {
  public func didClickEditButton(_ text: String?) {
    textView.text = text
    textView.becomeFirstResponder()
    hideAIChatView()
  }

  public func didClickMessageItem(_ text: String) {
    multipleLineDelegate?.aiChatMessageDidClick(text)
  }
}
