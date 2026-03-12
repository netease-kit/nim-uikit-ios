//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

open class NEBaseChatNewMessageView: UIView {
  public lazy var jumpDownImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = .ne_imageNamed(name: "chat_jump_to_new")
    return imageView
  }()

  public var messageCountLabelRightAnchor: NSLayoutConstraint?
  public lazy var messageCountLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = DefaultTextFont(14)
    label.textColor = .ne_normalTheme
    label.textAlignment = .center
    label.isHidden = true
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    layer.borderWidth = 1
    layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor

    addSubview(jumpDownImageView)
    NSLayoutConstraint.activate([
      jumpDownImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      jumpDownImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      jumpDownImageView.widthAnchor.constraint(equalToConstant: 16),
      jumpDownImageView.heightAnchor.constraint(equalToConstant: 16),
    ])

    addSubview(messageCountLabel)
    messageCountLabelRightAnchor = messageCountLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -30)
    messageCountLabelRightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      messageCountLabel.leftAnchor.constraint(equalTo: jumpDownImageView.rightAnchor, constant: 0),
      messageCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  open func updateMessageCount(_ count: Int) {
    if count > 0 {
      isHidden = false
      messageCountLabel.isHidden = false
      messageCountLabel.text = String(format: chatLocalizable("new_message_count"), count)
      messageCountLabelRightAnchor?.constant = -30
    } else if count == 0 {
      isHidden = false
      messageCountLabel.isHidden = true
      messageCountLabel.text = nil
      messageCountLabelRightAnchor?.constant = 0
    } else {
      isHidden = true
    }
  }
}
