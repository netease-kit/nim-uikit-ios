
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import RSKPlaceholderTextView

@objc public enum ChatMenuType: Int {
  case text = 0
  case audio
  case emoji
  case image
  case addMore
}

@objc
public protocol ChatInputViewDelegate: NSObjectProtocol {
  func sendText(text: String?)
  func willSelectItem(button: UIButton, index: Int)
  func didSelectMoreCell(cell: NEInputMoreCell)

  @discardableResult
  func textChanged(text: String) -> Bool
  func textDelete(range: NSRange, text: String) -> Bool
  func startRecord()
  func moveOutView()
  func moveInView()
  func endRecord(insideView: Bool)
  func textFieldDidChange(_ textField: UITextView)
  func textFieldDidEndEditing(_ textField: UITextView)
  func textFieldDidBeginEditing(_ textField: UITextView)
}

@objcMembers
public class ChatInputView: UIView, ChatRecordViewDelegate,
  InputEmoticonContainerViewDelegate, UITextViewDelegate, NEMoreViewDelagate {
  public weak var delegate: ChatInputViewDelegate?
  public var currentType: ChatMenuType = .text
  public var menuHeight = 100.0
  public var contentHeight = 204.0
  public var atCache: NIMInputAtCache?

  var textField = RSKPlaceholderTextView()
  var stackView = UIStackView()
  var contentView = UIView()
  public var contentSubView: UIView?
  private var greyView = UIView()
  private var recordView = ChatRecordView(frame: .zero)

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func commonUI() {
    backgroundColor = UIColor(hexString: "#EFF1F3")
    textField.layer.cornerRadius = 8
    textField.font = UIFont.systemFont(ofSize: 16)
    textField.clipsToBounds = true
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.backgroundColor = .white
    textField.returnKeyType = .send
    textField.delegate = self
    textField.allowsEditingTextAttributes = true
    addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
      textField.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
      textField.heightAnchor.constraint(equalToConstant: 40),
    ])
//    NotificationCenter.default.addObserver(
//      textField,
//      selector: #selector(textFieldChangeNoti),
//      name: UITextView.textDidChangeNotification,
//      object: nil
//    )

    let imageNames = ["mic", "emoji", "photo", "add"]
//    let imageNames = ["mic", "emoji", "photo", "chat_video", "add"]

    var items = [UIButton]()
    for i in 0 ... 3 {
      let button = UIButton(type: .custom)
      button.setImage(UIImage.ne_imageNamed(name: imageNames[i]), for: .normal)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
      button.tag = i + 5
      items.append(button)
    }

    stackView = UIStackView(arrangedSubviews: items)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.distribution = .fillEqually
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor),
      stackView.rightAnchor.constraint(equalTo: rightAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 54),
      stackView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 0),
    ])

    greyView.translatesAutoresizingMaskIntoConstraints = false
    greyView.backgroundColor = UIColor(hexString: "#EFF1F3")
    greyView.isHidden = true
    addSubview(greyView)
    NSLayoutConstraint.activate([
      greyView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      greyView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      greyView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      greyView.heightAnchor.constraint(equalToConstant: 100),
    ])

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.rightAnchor.constraint(equalTo: rightAnchor),
      contentView.heightAnchor.constraint(equalToConstant: contentHeight),
      contentView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 0),
    ])

    recordView.isHidden = true
    recordView.translatesAutoresizingMaskIntoConstraints = false
    recordView.delegate = self
    recordView.backgroundColor = UIColor.ne_backgroundColor
    contentView.addSubview(recordView)
    NSLayoutConstraint.activate([
      recordView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      recordView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      recordView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      recordView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
    ])

    contentView.addSubview(emojiView)

    contentView.addSubview(chatAddMoreView)
  }

  func addRecordView() {
    if currentType != .audio {
      currentType = .audio
      textField.resignFirstResponder()
      contentSubView?.isHidden = true
      contentSubView = recordView
      contentSubView?.isHidden = false
    }
  }

  func addEmojiView() {
    if currentType != .emoji {
      currentType = .emoji
      textField.resignFirstResponder()
      contentSubView?.isHidden = true
      contentSubView = emojiView
      contentSubView?.isHidden = false
    }
  }

  func addMoreActionView() {
    if currentType != .addMore {
      currentType = .addMore
      contentSubView?.isHidden = true
      contentSubView = chatAddMoreView
      contentSubView?.isHidden = false
    }
  }

  //    func doButtonDeleteText(){
  //        let range = delRangeForLastComponent()
  //        if range.count == 1 {
  //
  //        }
  //        print("\(textField.selectedTextRange?.start)")
  //        textField.deleteBackward()
  //    }

  //    func delRangeForLastComponent() -> NSRange{
  //        let text = textField.text as? NSString
  //        let selectedRange = self.textField.selectedRange
  //        if selectedRange.location == 0 {
  //            return NSRange.init(location: 0, length: 0)
  //        }
  //
  //        let range:NSRange?
  //        let subRange =
  //        if selectedRange?.start >= 2 {
  //            let subStr = text?.substring(with: NSRange.init(location: selectedRange?.start - 2,
  //            length: 2))
  //            isEmoji = sub
  //        }
  //    }

  //    func rangeForPrefix(prefix:String,suffix:String) ->NSRange {
  //        let text = textField.text as? NSString
  //        let range = textField.selectedRange
  //        var selectedText:String?
  //        if range.length > 0 {
  //            selectedText = text?.substring(with: range)
  //        }else {
  //            selectedText = text as? String
  //        }
  //        let endLocaiton = range.location
  //        if endLocaiton <= 0{
  //            return NSMakeRange(NSNotFound, 0)
  //        }
  //        let index = -1
  //
  //        if let selectStr = selectedText,selectStr.hasSuffix(suffix) {
  //            let p = 20
  //            for index = endLocaiton in
  //
  //
  //
  //        }else {
  //            return NSMakeRange(NSNotFound, 0)
  //
  //        }
  //
  //
  //
  //    }

  // MARK: ===================== lazy method =====================

  public lazy var emojiView: InputEmoticonContainerView = {
    let view =
      InputEmoticonContainerView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    //        view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    view.delegate = self
    return view
  }()

  public lazy var chatAddMoreView: NEChatMoreActionView = {
    let view = NEChatMoreActionView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    view.delegate = self
    return view
  }()

  public func textViewDidChange(_ textView: UITextView) {
    delegate?.textFieldDidChange(textField)
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

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    currentType = .text
    return true
  }

  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                       replacementText text: String) -> Bool {
    if text == "\n" {
      guard let text = getRealSendText(textField.attributedText)?
        .trimmingCharacters(in: CharacterSet.whitespaces) else {
        return true
      }
      delegate?.sendText(text: text)
      textField.text = ""
//            textView.resignFirstResponder()
      return false
    }

    print("range:\(range) string:\(text)")
    if text.count == 0 {
      if let delegate = delegate {
        return delegate.textDelete(range: range, text: text)
      }
    } else {
      delegate?.textChanged(text: text)
    }

    return true
  }

  func buttonEvent(button: UIButton) {
    switch button.tag - 5 {
    case 0:
      addRecordView()
    case 1:
      addEmojiView()
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
      //            doButtonDeleteText()
      textField.deleteBackward()
      print("delete ward")
    } else {
      if let font = textField.font {
        let attribute = NEEmotionTool.getAttWithStr(
          str: description,
          font: font,
          CGPoint(x: 0, y: -4)
        )
        print("attribute : ", attribute)
        let mutaAttribute = NSMutableAttributedString()
        if let origin = textField.attributedText {
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
        textField.attributedText = mutaAttribute
        textField.scrollRangeToVisible(NSMakeRange(textField.attributedText.length, 1))
//                [_textView scrollRangeToVisible:NSMakeRange(_textView.text.length, 1)];
      }
    }
  }

  public func didPressSend(sender: UIButton) {
    guard let text = getRealSendText(textField.attributedText) else {
      return
    }
    delegate?.sendText(text: text)
    textField.text = ""
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

  func textFieldChangeNoti() {
    delegate?.textFieldDidChange(textField)
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
}
