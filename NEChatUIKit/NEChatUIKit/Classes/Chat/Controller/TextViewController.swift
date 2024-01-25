// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit

@objcMembers
open class TextViewController: ChatBaseViewController {
  let leftRightMargin: CGFloat = 20
  var contentMaxWidth: CGFloat = 0
  let titleFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
  let bodyFont = UIFont.systemFont(ofSize: 24)

  lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isScrollEnabled = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  lazy var textView: UIView = {
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

  lazy var titleLabel: CopyableLabel = {
    let label = CopyableLabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = titleFont
    label.backgroundColor = .clear
    label.textColor = .ne_darkText
    return label
  }()

  lazy var bodyLabel: CopyableLabel = {
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

  init(title: String?, body: String?) {
    super.init(nibName: nil, bundle: nil)
    contentMaxWidth = kScreenWidth - leftRightMargin * 2
    if let title = title {
      let titleAtt = NEEmotionTool.getAttWithStr(str: title, font: titleFont, CGPoint(x: 0, y: -3))
      titleLabel.copyString = titleAtt.string
      titleLabel.attributedText = titleAtt
    }

    if let body = body {
      let bodyAtt = NEEmotionTool.getAttWithStr(str: body, font: bodyFont, CGPoint(x: 0, y: -3))
      bodyLabel.copyString = bodyAtt.string
      bodyLabel.attributedText = bodyAtt
    }
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      ])
    } else {
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      ])
    }

    titleLabel.preferredMaxLayoutWidth = contentMaxWidth
    bodyLabel.preferredMaxLayoutWidth = contentMaxWidth
    scrollView.addSubview(textView)
    contentLabelTopAnchor = textView.topAnchor.constraint(equalTo: scrollView.topAnchor)
    contentLabelLeftAnchor = textView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: leftRightMargin)
    NSLayoutConstraint.activate([
      contentLabelTopAnchor!,
      textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentLabelLeftAnchor!,
      textView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -leftRightMargin),
    ])
  }

  // textView 垂直居中
  func contentSizeToFit() {
    var label = bodyLabel
    if let titleLength = titleLabel.attributedText?.length {
      if let bodyLength = bodyLabel.attributedText?.length {
        label = titleLength > bodyLength ? titleLabel : bodyLabel
      } else {
        label = titleLabel
      }
    }

    let textSize = label.attributedText?.finalSize(bodyFont, CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
    let textViewHeight = kScreenHeight - kNavigationHeight - KStatusBarHeight
    if textSize.height <= textViewHeight {
      let offsetY = (textViewHeight - textSize.height) / 2
      contentLabelTopAnchor?.constant = offsetY
    }

    if textSize.width <= contentMaxWidth {
      let offsetX = (kScreenWidth - textSize.width) / 2
      contentLabelLeftAnchor?.constant = offsetX
    }
    scrollView.contentSize = textSize
  }
}
