//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open
class NEBaseCollectionMessageMultiForwardCell: NEBaseCollectionMessageCell {
  public let funMargin: CGFloat = 5.2
  let contentW: CGFloat = 248
  var titleLabelFontSize: CGFloat = 14
  var contentLabelFontSize: CGFloat = 14
  var contentLabelColor: UIColor = .ne_lightText

  public lazy var backImageViewLeft: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = true
    return view
  }()

  public lazy var titleLabelLeft1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name1"
    return label
  }()

  public lazy var titleLabelLeft2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("chat_history_by")
    label.textColor = .ne_darkText
    label.font = .systemFont(ofSize: titleLabelFontSize)
    label.accessibilityIdentifier = "id.name2"
    return label
  }()

  public lazy var contentLabelLeft1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 3
    label.accessibilityIdentifier = "id.content1"
    return label
  }()

  public lazy var contentLabelLeft2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 2
    label.accessibilityIdentifier = "id.content2"
    return label
  }()

  public lazy var contentLabelLeft3: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.content3"
    return label
  }()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// 初始化的生命周期
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  /// 反序列化支持回调
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupCommonUI() {
    super.setupCommonUI()
    backImageViewLeft.layer.cornerRadius = 8
    backImageViewLeft.layer.borderColor = multiForwardborderColor.cgColor
    backImageViewLeft.layer.borderWidth = 1

    backView.addSubview(backImageViewLeft)
    NSLayoutConstraint.activate([
      backImageViewLeft.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      backImageViewLeft.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -12),
      backImageViewLeft.widthAnchor.constraint(equalToConstant: 276),
      backImageViewLeft.heightAnchor.constraint(equalToConstant: 100),
    ])

    if let gesture = contentGesture {
      backImageViewLeft.addGestureRecognizer(gesture)
    }
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    guard let data = NECustomUtils.dataOfCustomMessage(model.chatmodel.message?.attachment) else {
      return
    }

    let font = UIFont.systemFont(ofSize: contentLabelFontSize)
    let titleLabel = titleLabelLeft1
    let titleLabel2 = titleLabelLeft2
    let contentLabel1 = contentLabelLeft1
    let contentLabel2 = contentLabelLeft2
    let contentLabel3 = contentLabelLeft3

    if let sessionName = data["sessionName"] as? String {
      titleLabel.attributedText =
        NEEmotionTool.getAttWithStr(str: sessionName,
                                    font: .systemFont(ofSize: titleLabelFontSize),
                                    color: .ne_darkText)
    } else {
      titleLabel2.text = chatLocalizable("chat_history")
    }

    guard let abstracts = data["abstracts"] as? [[String: Any]] else { return }

    contentLabel2.attributedText = nil
    contentLabel3.attributedText = nil
    for i in 0 ..< abstracts.count {
      var contentLabel = contentLabel1
      if i == 1 {
        contentLabel = contentLabel2
      } else if i == 2 {
        contentLabel = contentLabel3
      }

      var contentText = ""
      if var senderNick = abstracts[i]["senderNick"] as? String {
        if senderNick.count > 5 {
          // 截取字符串 abcdefg -> ab...fg
          let leftEndIndex = senderNick.index(senderNick.startIndex, offsetBy: 2)
          let rightStartIndex = senderNick.index(senderNick.endIndex, offsetBy: -2)
          senderNick = senderNick[senderNick.startIndex ..< leftEndIndex] + "..." + senderNick[rightStartIndex ..< senderNick.endIndex]
        }
        contentText = senderNick
        if let content = abstracts[i]["content"] as? String {
          contentText += "：" + content
        }
      }

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 1 // 设置行间距
      paragraphStyle.lineBreakMode = .byTruncatingTail
      let attributedText = NEEmotionTool.getAttWithStr(str: contentText,
                                                       font: font,
                                                       color: contentLabelColor)
      attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedText.length))
      contentLabel.attributedText = attributedText
    }

    let numCount1 = String.calculateMaxLines(width: contentW,
                                             attributeString: contentLabel1.attributedText,
                                             font: font)
    if numCount1 == 1 {
      contentLabel2.numberOfLines = 2
      contentLabel2.isHidden = contentLabel2.attributedText == nil
      let numCount2 = String.calculateMaxLines(width: contentW,
                                               attributeString: contentLabel2.attributedText,
                                               font: font)
      contentLabel3.isHidden = !(contentLabel3.attributedText != nil && numCount2 == 1)
    } else if numCount1 == 2 {
      contentLabel2.numberOfLines = 1
      contentLabel2.isHidden = contentLabel3.attributedText != nil
      contentLabel3.isHidden = true
    } else {
      contentLabel2.isHidden = true
      contentLabel3.isHidden = true
    }
  }
}
