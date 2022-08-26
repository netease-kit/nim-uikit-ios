
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc protocol QChatTextEditCellDelegate:AnyObject {
//  @objc optional func textFieldDidChangeSelection(cell: QChatTextEditCell,
//                                                  _ textField: UITextField)
  @objc optional func textDidChange(_ textField: UITextField)
}


class QChatTextEditCell: QChatCornerCell, UITextFieldDelegate {
  var limit: Int?
  var canEdit = true
  var editTotast = ""
  public var textFied = UITextField()
  public weak var delegate: QChatTextEditCellDelegate?
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textFied.textColor = .ne_darkText
    textFied.font = UIFont.systemFont(ofSize: 16)
    textFied.clearButtonMode = .whileEditing
    textFied.translatesAutoresizingMaskIntoConstraints = false
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textFieldDidChangeValue(_:)),
      name: UITextField.textDidChangeNotification,
      object: textFied
    )
    contentView.addSubview(textFied)
    NSLayoutConstraint.activate([
      textFied.leftAnchor.constraint(equalTo: leftAnchor, constant: 36),
      textFied.topAnchor.constraint(equalTo: topAnchor),
      textFied.bottomAnchor.constraint(equalTo: bottomAnchor),
      textFied.rightAnchor.constraint(equalTo: rightAnchor, constant: -36),
    ])
    textFied.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MAKR: UITextFieldDelegate
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    if let l = limit {
      let text = "\(textField.text ?? "")\(string)"
      if text.count > l {
        return false
      }
    }
    return true
  }

  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    print("1 textFieldShouldEndEditing")
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    print("2 textFieldDidEndEditing")
  }

  func textFieldDidChangeSelection(_ textField: UITextField) {
    print("3 textFieldDidChangeSelection:\(textField.text)")
//    if let d = delegate {
//      d.textFieldDidChangeSelection?(cell: self, textField)
//    }
  }

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if canEdit == false, editTotast.count > 0 {
      UIApplication.shared.keyWindow?.makeToast(editTotast)
    }
    return canEdit
  }

  @objc func textFieldDidChangeValue(_ noti: Notification) {
    if let d = delegate, let text = noti.object as? UITextField {
      d.textDidChange?(text)
    }
  }
}
