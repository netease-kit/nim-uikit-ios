// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseHistoryMessageCell: UITableViewCell {
  /// 搜索文案(用户匹配高亮)
  public var searchText: String?
  /// 高亮颜色
  public var rangeTextColor = UIColor.ne_normalTheme

  /// 用户头像视图
  public lazy var headView: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 18
    headView.clipsToBounds = true
    return headView
  }()

  /// 用户昵称
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  /// 消息内容
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_lightText
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  /// 分隔线
  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  /// 消息时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0xCCCCCC)
    label.font = NEConstant.defaultTextFont(12)
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(bottomLine)
    contentView.addSubview(timeLabel)
  }

  open func configData(message: HistoryMessageModel?) {
    if message?.fullName?.count ?? 0 <= 0 {
      message?.fullName = ChatMessageHelper.getSenderId(message?.imMessage)
    }
    titleLabel.text = message?.fullName
    timeLabel.text = message?.time

    if let imageName = message?.avatar, !imageName.isEmpty {
      headView.setTitle("")
      headView.sd_setImage(with: URL(string: imageName), completed: nil)
    } else {
      headView.setTitle(message?.shortName ?? "")
      headView.sd_setImage(with: nil, completed: nil)
      headView.backgroundColor = UIColor.colorWithString(string: ChatMessageHelper.getSenderId(message?.imMessage))
    }
  }

  /// 根据label宽度显示关键字段
  /// - Parameter label: 文本控件
  /// - Parameter maxWidth: 最大宽度
  /// - Parameter importantText: 关键字段
  /// - Parameter fullText: 全文本
  public func truncateTextForLabel(_ label: UILabel, _ maxWidth: CGFloat, _ importantText: String, _ fullText: String) {
    guard let font = label.font else {
      return
    }

    var truncatedText = ""
    var displayText = fullText

    let importantTextWidth = importantText.width(withConstrainedHeight: label.frame.size.height, font: font)
    let fullTextWidth = fullText.width(withConstrainedHeight: label.frame.size.height, font: font)

    if fullTextWidth > maxWidth {
      let ellipsis = "..."
      var accumulatedWidth: CGFloat = 0

      for (_, char) in fullText.enumerated() {
        let charWidth = String(char).width(withConstrainedHeight: label.frame.size.height, font: font)
        if accumulatedWidth + charWidth + importantTextWidth + ellipsis.width(withConstrainedHeight: label.frame.size.height, font: font) <= maxWidth {
          truncatedText.append(char)
          accumulatedWidth += charWidth
        } else {
          break
        }
      }

      displayText = truncatedText + ellipsis + importantText
    }

    let attributedStr = NSMutableAttributedString(string: displayText)

    do {
      let regex = try NSRegularExpression(pattern: importantText, options: [])
      let matches = regex.matches(in: displayText, options: [], range: NSRange(location: 0, length: displayText.count))

      for match in matches {
        let matchRange = match.range
        attributedStr.addAttribute(
          .foregroundColor,
          value: rangeTextColor,
          range: matchRange
        )
      }
    } catch {
      print("Regex error: \(error.localizedDescription)")
    }
    label.attributedText = attributedStr
  }
}
