//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomSettingTextviewCell: TeamSettingSubtitleCell, UITextViewDelegate {
  var subCornerType: CornerType {
    get { cornerType }
    set {
      if cornerType != newValue {
        cornerType = newValue
        setNeedsDisplay()
      }
    }
  }

  var dataModel: CustomSettingCellModel?

  lazy var clearButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    if #available(iOS 13.0, *) {
      let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
      button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration), for: .normal)
    } else {
      button.setTitle("×", for: .normal)
      button.setTitleColor(.ne_emptyTitleColor, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 16)
    }
    button.tintColor = .ne_emptyTitleColor
    button.accessibilityIdentifier = "id.clear"
    button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    button.isHidden = true
    return button
  }()

  /// 自定义json配置输入
  lazy var inputTextView: UITextView = {
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
    contentView.addSubview(clearButton)


    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
    titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
    titleWidthAnchor?.isActive = true

    NSLayoutConstraint.activate([
      inputTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      inputTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -60),
      inputTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
      inputTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      clearButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -40),
      clearButton.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 8),
      clearButton.widthAnchor.constraint(equalToConstant: 24),
      clearButton.heightAnchor.constraint(equalToConstant: 24),
    ])


  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? CustomSettingCellModel {
      titleLabel.text = model.cellName
      subCornerType = model.cornerType
      inputTextView.text = model.customInputText
      dataModel = model
      updateClearButton()
    }
  }

  @objc
  func clearText() {
    inputTextView.text = ""
    dataModel?.customInputText = ""
    updateClearButton()
  }

  func textViewDidChange(_ textView: UITextView) {
    dataModel?.customInputText = textView.text
    updateClearButton()
  }

  private func updateClearButton() {
    clearButton.isHidden = inputTextView.text?.isEmpty != false
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if let textString = textView.text as? NSString {
      let changeString = textString.replacingCharacters(in: range, with: text)
      dataModel?.customInputText = changeString
    }
    return true
  }
}
