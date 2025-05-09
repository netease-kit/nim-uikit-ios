// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

@objcMembers
open class TextViewController: NEChatBaseViewController {
  let leftRightMargin: CGFloat = 20
  var contentMaxWidth: CGFloat = 0
  let titleFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
  let bodyFont = UIFont.systemFont(ofSize: 24)

  public lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isScrollEnabled = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  public lazy var textView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor),
      titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    view.addSubview(bodyLabel)
    NSLayoutConstraint.activate([
      bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      bodyLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      bodyLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      bodyLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    return view
  }()

  public lazy var titleLabel: CopyableLabel = {
    let label = CopyableLabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = titleFont
    label.backgroundColor = .clear
    label.textColor = .ne_darkText
    return label
  }()

  public lazy var bodyLabel: CopyableLabel = {
    let label = CopyableLabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = bodyFont
    label.backgroundColor = .clear
    label.textColor = .ne_darkText
    return label
  }()

  var contentLabelTopAnchor: NSLayoutConstraint?
  var contentLabelLeftAnchor: NSLayoutConstraint?

  public init(title: String?, body: NSAttributedString?) {
    super.init(nibName: nil, bundle: nil)
    contentMaxWidth = kScreenWidth - leftRightMargin * 2
    if let title = title {
      titleLabel.copyString = title
      let titleAtt = NEEmotionTool.getAttWithStr(str: title, font: titleFont, CGPoint(x: 0, y: -3))
      titleLabel.attributedText = titleAtt
    }

    if let body = body {
      bodyLabel.copyString = body.string
      bodyLabel.attributedText = body
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.isNavigationBarHidden = true
    navigationView.isHidden = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    scrollView.addGestureRecognizer(tap)
    setupUI()
    contentSizeToFit()
  }

  open func viewTap() {
    UIMenuController.shared.setMenuVisible(false, animated: true)
    dismiss(animated: false)
  }

  open func setupUI() {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
      scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
    ])

    titleLabel.preferredMaxLayoutWidth = contentMaxWidth
    bodyLabel.preferredMaxLayoutWidth = contentMaxWidth
    scrollView.addSubview(textView)
    contentLabelTopAnchor = textView.topAnchor.constraint(equalTo: scrollView.topAnchor)
    contentLabelTopAnchor?.isActive = true
    contentLabelLeftAnchor = textView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: leftRightMargin)
    contentLabelLeftAnchor?.isActive = true
    NSLayoutConstraint.activate([
      textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      textView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -leftRightMargin),
    ])
  }

  // textView 垂直居中
  func contentSizeToFit() {
    let titleSize = NSAttributedString.getRealLabelSize(titleLabel.attributedText, titleFont, CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude))
    let bodySize = NSAttributedString.getRealLabelSize(bodyLabel.attributedText, bodyFont, CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude))

    let textHeight = titleSize.height + bodySize.height
    let textViewHeight = kScreenHeight - kNavigationHeight - KStatusBarHeight
    if textHeight <= textViewHeight {
      let offsetY = (textViewHeight - textHeight) / 2
      contentLabelTopAnchor?.constant = offsetY
    }

    let textWidth = max(titleSize.width, bodySize.width)
    if textWidth <= contentMaxWidth {
      let offsetX = (kScreenWidth - textWidth) / 2
      contentLabelLeftAnchor?.constant = offsetX
    }
    scrollView.contentSize = CGSize(width: textWidth, height: textHeight)
  }
}
