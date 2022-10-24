
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatTextTableViewCell: QChatBaseTableViewCell {
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  override public var messageFrame: QChatMessageFrame? {
    didSet {
//        //    SHMessage *message = messageFrame.message;
      textView.text = messageFrame?.message?.text
      var viewY = qChat_margin
      if contentBtn.height == qChat_min_h {
        viewY = (qChat_min_h - DefaultTextFont(16).lineHeight) / 2
      }

      // 此处要根据发送者还是接收者判断起始x值
      let leftStartMargin = messageFrame?.startX
      textView.frame = CGRect(
        x: (leftStartMargin ?? 0) + qChat_margin,
        y: viewY,
        width: contentBtn.width - 2 * qChat_margin - qChat_angle_w,
        height: contentBtn.height - 2 * viewY
      )
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var textView: QChatTextView = {
    let textview = QChatTextView()
    textview.isEditable = false
    textview.isScrollEnabled = false
    textview.showsVerticalScrollIndicator = false
    textview.textContainer.maximumNumberOfLines = 0
    self.contentBtn.addSubview(textview)
    return textview
  }()
}

class QChatTextView: UITextView {
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    setupUI()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    backgroundColor = .clear
    textContainer.lineFragmentPadding = 0
    textContainerInset = .zero
    dataDetectorTypes = .all
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    font = DefaultTextFont(16)
  }

  override var textContainerInset: UIEdgeInsets {
    set {
      let padding = textContainer.lineFragmentPadding
      super.textContainerInset = UIEdgeInsets(
        top: newValue.top,
        left: newValue.left - padding,
        bottom: newValue.bottom,
        right: newValue.right - padding
      )
    }
    get {
      super.textContainerInset
    }
  }
}
