//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class TextViewController: ChatBaseViewController {
  let leftRightMargin: CGFloat = 24
  var contentMaxWidth: CGFloat = 0
  let textFont = UIFont.systemFont(ofSize: 24, weight: .regular)

  lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isScrollEnabled = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  var contentLabelTopAnchor: NSLayoutConstraint?
  var contentLabelLeftAnchor: NSLayoutConstraint?
  lazy var contentLabel: CopyableLabel = {
    let contentLabel = CopyableLabel()
    contentLabel.numberOfLines = 0
    contentLabel.translatesAutoresizingMaskIntoConstraints = false
    contentLabel.font = textFont
    contentLabel.backgroundColor = .clear
    return contentLabel
  }()

  init(content: String) {
    super.init(nibName: nil, bundle: nil)
    contentMaxWidth = kScreenWidth - leftRightMargin * 2
    let att = NEEmotionTool.getAttWithStr(str: content, font: textFont, CGPoint(x: 0, y: -3))
    contentLabel.copyString = att.string
    contentLabel.attributedText = att
    let line = String.calculateMaxLines(width: kScreenWidth - 2 * leftRightMargin,
                                        string: att.string,
                                        font: textFont)
    contentLabel.textAlignment = .justified
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.isNavigationBarHidden = true
    customNavigationView.isHidden = true
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
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      ])
    } else {
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: view.topAnchor),
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -0),
      ])
    }

    scrollView.addSubview(contentLabel)
    contentLabel.preferredMaxLayoutWidth = contentMaxWidth
    contentLabelTopAnchor = contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor)
    contentLabelLeftAnchor = contentLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: leftRightMargin)
    NSLayoutConstraint.activate([
      contentLabelTopAnchor!,
      contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentLabelLeftAnchor!,
      contentLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -leftRightMargin),
    ])
  }

  // textView 垂直居中
  func contentSizeToFit() {
    let textSize = contentLabel.attributedText?.finalSize(textFont, CGSize(width: contentMaxWidth, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
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
