//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class CustomSettingInputCell: TeamSettingSubtitleCell, UITextFieldDelegate {
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

  public lazy var inputTextField: UITextField = {
    let textField = UITextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.textColor = UIColor.black
    textField.textAlignment = .right
    textField.borderStyle = .roundedRect
    textField.textAlignment = .left
    return textField
  }()

  /// UI 初始化
  override func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(inputTextField)

    if NEStyleManager.instance.isNormalStyle() {
      NSLayoutConstraint.activate([
        titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
        titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      ])
      titleWidthAnchor = titleLabel.widthAnchor.constraint(equalToConstant: 0)
      titleWidthAnchor?.isActive = true

      NSLayoutConstraint.activate([
        inputTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
        inputTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
        inputTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
        inputTextField.heightAnchor.constraint(equalToConstant: 40),
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
        inputTextField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
        inputTextField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
        inputTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
        inputTextField.heightAnchor.constraint(equalToConstant: 40),
      ])

      dividerLineLeftMargin?.constant = 20
      dividerLineRightMargin?.constant = 0
    }
  }

  /// 绑定数据
  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? CustomSettingCellModel {
      inputTextField.placeholder = model.placeholder
      titleLabel.text = model.cellName
      subCornerType = model.cornerType
      dataModel = model
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let textString = textField.text as? NSString {
      let changeString = textString.replacingCharacters(in: range, with: string)
      dataModel?.customInputText = changeString
    }
    return true
  }
}
