
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// protocol ChatRevokeRightCellDelegate: ChatBaseCellDelegate  {
//    func onReeditMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)
// }

// typealias ReeditBlock = (_ cell: ChatRevokeRightCell, _ model: MessageContentModel?) -> ()

@objcMembers
public class ChatRevokeRightCell: ChatBaseRightCell {
  public var label = UILabel()
  public var reeditButton = UIButton(type: .custom)
//    public var reeditBlock: ReeditBlock?
//    public override var delegate: ChatBaseCellDelegate?
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_greyText
    label.font = UIFont.systemFont(ofSize: 16.0)
    bubbleImage.addSubview(label)
    NSLayoutConstraint.activate([
      label.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 16),
      label.widthAnchor.constraint(equalToConstant: 100),
      label.heightAnchor.constraint(equalToConstant: qChat_min_h),
      label.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 0),
      label.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])

    reeditButton.translatesAutoresizingMaskIntoConstraints = false
    reeditButton.setImage(UIImage.ne_imageNamed(name: "right_arrow"), for: .normal)
    reeditButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    reeditButton.setTitleColor(UIColor.ne_blueText, for: .normal)
    reeditButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -30, bottom: 0, right: 0)
    reeditButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 0)

    bubbleImage.addSubview(reeditButton)
    NSLayoutConstraint.activate([
      reeditButton.leftAnchor.constraint(equalTo: label.rightAnchor, constant: 8),
      reeditButton.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -8),
      reeditButton.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 0),
      reeditButton.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])
    reeditButton.addTarget(self, action: #selector(reeditEvent), for: .touchUpInside)
  }

  override func setModel(_ model: MessageContentModel) {
    if let time = model.message?.timestamp {
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        model.timeOut = true
      }
    }
    if let isSend = model.message?.isOutgoingMsg, isSend, model.isRevokedText == true, model.timeOut == false {
      model.contentSize = CGSize(width: 218, height: qChat_min_h)
    } else {
      model.contentSize = CGSize(width: 130, height: qChat_min_h)
    }
    super.setModel(model)
    label.text = chatLocalizable("message_has_be_withdrawn")
    reeditButton.setTitle(chatLocalizable("message_reedit"), for: .normal)

    if model.isRevokedText == true {
      if model.timeOut == true {
        reeditButton.isHidden = true
      } else {
        reeditButton.isHidden = false
      }
    } else {
      reeditButton.isHidden = true
    }
  }

  func reeditEvent(button: UIButton) {
    print(#function)
    delegate?.didTapReeditButton(self, contentModel)
  }
}
