//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomSettingTextviewCell: TeamSettingSubtitleCell, UITextViewDelegate {
  public var subCornerType: CornerType {
    get { cornerType }
    set {
      if cornerType != newValue {
        cornerType = newValue
        setNeedsDisplay()
      }
    }
  }

  var dataModel: CustomSettingCellModel?

  /// 自定义json配置输入
  public lazy var inputTextView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.font = UIFont.systemFont(ofSize: 14)
    textView.textColor = UIColor.ne_darkText
    textView.textAlignment = .left
    textView.layer.cornerRadius = 4
    textView.layer.borderWidth = 1
    textView.layer.borderColor = UIColor.ne_outlineColor.cgColor
    textView.delegate = self
    return textView
  }()

  override func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(inputTextView)

    if NEStyleManager.instance.isNormalStyle() {
      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      ])
      titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
      titleWidthAnchor?.isActive = true

      NSLayoutConstraint.activate([
        inputTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
        inputTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
        inputTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
        inputTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      ])

    } else {
      let whiteBgView = UIView()
      whiteBgView.backgroundColor = UIColor.white
      whiteBgView.translatesAutoresizingMaskIntoConstraints = false
      contentView.insertSubview(whiteBgView, belowSubview: dividerLine)
      NSLayoutConstraint.activate([
        whiteBgView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        whiteBgView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        whiteBgView.topAnchor.constraint(equalTo: contentView.topAnchor),
        whiteBgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])

      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      ])
      titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
      titleWidthAnchor?.isActive = true

      NSLayoutConstraint.activate([
        inputTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        inputTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
        inputTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
        inputTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      ])

      dividerLineLeftMargin?.constant = 20
      dividerLineRightMargin?.constant = 0
    }
  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? CustomSettingCellModel {
      titleLabel.text = model.cellName
      subCornerType = model.cornerType
      inputTextView.text = model.customInputText
      dataModel = model
    }
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if let textString = textView.text as? NSString {
      let changeString = textString.replacingCharacters(in: range, with: text)
      dataModel?.customInputText = changeString
    }
    return true
  }
}
