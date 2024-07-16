//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Lottie
import NECommonUIKit
import UIKit

public enum TranslateState: Int {
  /// 空闲
  case Idle
  /// 处理中
  case Translating
  /// 使用
  case Use
}

@objc public protocol NETranslateViewDelegate: AnyObject {
  /// 切换语言
  func didSwitchLanguageClick(_ currentLanguage: String?)
  /// 关闭
  func didCloseClick(_ view: NEAITranslateView)
  /// 高度改变回调
  @objc optional func didChangeViewHeight(_ translateView: NEAITranslateView, _ changeHeight: CGFloat)
  /// 开始翻译
  @objc optional func didStartClick()
  /// 点击使用按钮
  @objc optional func didUseTranslate(_ content: String)
}

@objcMembers
open class NEAITranslateView: UIView, NEGrowingTextViewDelegate {
  /// 代理
  public weak var delegate: NETranslateViewDelegate?

  /// 输入框(外部传入，用于监听内容)
  public var chatInputText: UITextView?

  /// 当前语言记录
  public var currentLanguage = "" {
    didSet {
      if oldValue != currentLanguage {
        if currentLanguage.count > 0 {
          let userDefault = UserDefaults.standard
          userDefault.setValue(currentLanguage, forKey: IMKitClient.instance.account() + languageSuffix)
          userDefault.synchronize()
        }
        if let first = currentLanguage.first {
          shortLanguageLabel.text = String(first)
          changeToIdleState(true)
        }
      }
    }
  }

  let languageSuffix = "_language"

  public var translateState = TranslateState.Idle

  /// 当前语言提示
  public lazy var shortLanguageLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .black
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    return label
  }()

  /// 语言背景
  public lazy var shortLanguageBgView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.layer.borderColor = UIColor(hexString: "#CCCCCC").cgColor
    view.layer.borderWidth = 1.0
    view.layer.cornerRadius = 2.0
    return view
  }()

  /// 切换语言按钮
  public lazy var switchLanguageButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  /// 关闭按钮
  public lazy var closeButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  /// 关闭图片
  public lazy var closeImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = coreLoader.loadImage("top_close")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  /// 分割线
  public lazy var separatorLine: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hexString: "#DBDFE2")
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  /// 当前状态标签(内容为可使用 撤回  等待处理状态)
  public lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .black
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  /// 配合statusLabel 显示loading状态
  public lazy var loadingImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  /// 翻译内容展示
  public lazy var showTranslateContentText: NEGrowingTextView = {
    let textView = NEGrowingTextView()
    textView.font = UIFont.systemFont(ofSize: 14)
    textView.contentInset = .zero
    textView.contentInset = .zero
    textView.textColor = .ne_darkText
    textView.clipsToBounds = true
    textView.backgroundColor = .clear
    textView.returnKeyType = .send
    textView.isEditable = false
    textView.delegate = self
    textView.maxNumberOfLines = 3
    return textView
  }()

  /// 使用文案富文本
  public var useAttributeString: NSMutableAttributedString = {
    let attributeString = NSMutableAttributedString(string: chatLocalizable("translate_use"))
    if let attachmentImage = coreLoader.loadImage("use_arrow") {
      let attachment = NSTextAttachment()
      attachment.image = attachmentImage
      attachment.bounds = CGRectMake(0, -2, 10, 13)
      attributeString.append(NSAttributedString(attachment: attachment))
    }
    attributeString.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(0, attributeString.length))
    attributeString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, attributeString.length))
    return attributeString
  }()

  /// AI 处理
  public var translateString: NSMutableAttributedString = {
    let attributeString = NSMutableAttributedString(string: chatLocalizable("translate_sure"))
    attributeString.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(0, attributeString.length))
    attributeString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, attributeString.length))
    return attributeString
  }()

  /// 处理中文案
  public var processingString: NSMutableAttributedString = {
    let attributeString = NSMutableAttributedString(string: chatLocalizable("ai_translating"))
    attributeString.addAttribute(.foregroundColor, value: UIColor.ne_normalTheme, range: NSMakeRange(0, attributeString.length))
    attributeString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, attributeString.length))
    return attributeString
  }()

  /// 标题栏 loading 动画
  public lazy var loadingAnimationView: LottieAnimationView = {
    let view = LottieAnimationView(name: "ne_loading_data", bundle: coreLoader.bundle)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.loopMode = .loop
    view.contentMode = .scaleAspectFill
    view.accessibilityIdentifier = "id.loadingView"
    view.isHidden = true
    return view
  }()

  public lazy var startButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupTranslateLanguageUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI 初始化
  open func setupTranslateLanguageUI() {
    backgroundColor = .ne_backgroundColor
    clipsToBounds = true

    addSubview(shortLanguageBgView)
    addSubview(shortLanguageLabel)
    addSubview(switchLanguageButton)
    addSubview(closeImageView)
    addSubview(closeButton)
    addSubview(separatorLine)
    addSubview(statusLabel)
    addSubview(loadingAnimationView)
    addSubview(showTranslateContentText)
    addSubview(startButton)

    NSLayoutConstraint.activate([
      shortLanguageLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      shortLanguageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
    ])

    NSLayoutConstraint.activate([
      shortLanguageBgView.leftAnchor.constraint(equalTo: shortLanguageLabel.leftAnchor, constant: -8),
      shortLanguageBgView.rightAnchor.constraint(equalTo: shortLanguageLabel.rightAnchor, constant: 8),
      shortLanguageBgView.topAnchor.constraint(equalTo: shortLanguageLabel.topAnchor, constant: -2),
      shortLanguageBgView.bottomAnchor.constraint(equalTo: shortLanguageLabel.bottomAnchor, constant: 2),
    ])

    NSLayoutConstraint.activate([
      switchLanguageButton.leftAnchor.constraint(equalTo: leftAnchor),
      switchLanguageButton.topAnchor.constraint(equalTo: topAnchor),
      switchLanguageButton.bottomAnchor.constraint(equalTo: shortLanguageLabel.bottomAnchor, constant: 15),
      switchLanguageButton.rightAnchor.constraint(equalTo: shortLanguageLabel.rightAnchor, constant: 12),
    ])

    NSLayoutConstraint.activate([
      closeImageView.widthAnchor.constraint(equalToConstant: 20),
      closeImageView.heightAnchor.constraint(equalToConstant: 20),
      closeImageView.topAnchor.constraint(equalTo: topAnchor, constant: 7),
      closeImageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
    ])

    NSLayoutConstraint.activate([
      closeButton.widthAnchor.constraint(equalToConstant: 40),
      closeButton.heightAnchor.constraint(equalToConstant: 40),
      closeButton.topAnchor.constraint(equalTo: topAnchor),
      closeButton.rightAnchor.constraint(equalTo: rightAnchor),
    ])

    NSLayoutConstraint.activate([
      separatorLine.heightAnchor.constraint(equalToConstant: 1),
      separatorLine.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      separatorLine.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      separatorLine.topAnchor.constraint(equalTo: topAnchor, constant: 34),
    ])

    if let width = UIApplication.shared.keyWindow?.width {
      showTranslateContentText.frame = CGRectMake(12, 46, width - 112, 20)
    }

    NSLayoutConstraint.activate([
      statusLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      statusLabel.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 11),
    ])

    loadingAnimationView.play()
    NSLayoutConstraint.activate([
      loadingAnimationView.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor, constant: -1),
      loadingAnimationView.rightAnchor.constraint(equalTo: statusLabel.leftAnchor, constant: -2),
      loadingAnimationView.widthAnchor.constraint(equalToConstant: 12),
      loadingAnimationView.heightAnchor.constraint(equalToConstant: 12),
    ])

    NSLayoutConstraint.activate([
      startButton.rightAnchor.constraint(equalTo: rightAnchor),
      startButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
      startButton.heightAnchor.constraint(equalToConstant: 40),
      startButton.widthAnchor.constraint(equalToConstant: 66),
    ])
    startButton.addTarget(self, action: #selector(didStart), for: .touchUpInside)

    let placehoderAttribute = NSMutableAttributedString(string: chatLocalizable("translate_default"))
    placehoderAttribute.addAttribute(.foregroundColor, value: UIColor(hexString: "#AAAAAA"), range: NSMakeRange(0, placehoderAttribute.length))
    placehoderAttribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, placehoderAttribute.length))
    showTranslateContentText.placeholder = placehoderAttribute

    statusLabel.attributedText = translateString
    let userDefault = UserDefaults.standard
    if let cacheLanguage = userDefault.value(forKey: IMKitClient.instance.account() + languageSuffix) as? String, cacheLanguage.count > 0 {
      currentLanguage = cacheLanguage
      shortLanguageLabel.text = cacheLanguage
    } else if let firstLanguage = NETranslateLanguageManager.shared.languageDatas.first, let first = firstLanguage.first {
      currentLanguage = firstLanguage
      shortLanguageLabel.text = firstLanguage
    }

    // 事件绑定
    closeButton.addTarget(self, action: #selector(didClickClose), for: .touchUpInside)

    switchLanguageButton.addTarget(self, action: #selector(didClickChange), for: .touchUpInside)
  }

  /// 控件内容高度
  public func getCurrentHeight() -> CGFloat {
    70
  }

  /// 关闭按钮回调
  func didClickClose() {
    delegate?.didCloseClick(self)
    changeToIdleState(true)
  }

  /// 切花语言按钮点击回调
  func didClickChange() {
    delegate?.didSwitchLanguageClick(currentLanguage)
  }

  // MARK: - growing text view delegate

  public func growingTextView(_ growingTextView: NEGrowingTextView, didChangeHeight height: CGFloat, difference: CGFloat) {
    if frame.height < 1 {
      // 首次加载 不需要回调，此时回调将导致外部显示异常
      return
    }
    showTranslateContentText.frame = CGRectMake(12, 47, width - 112, height)
    delegate?.didChangeViewHeight?(self, 52 + height)
  }

  public func didStart() {
    if translateState == .Use {
      if let text = showTranslateContentText.text {
        delegate?.didUseTranslate?(text)
      }
      changeToIdleState(true)
      return
    }

    if translateState != .Idle {
      return
    }

    if let textView = chatInputText {
      if textView.attributedText.length > 0 {
        if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
          UIApplication.shared.keyWindow?.endEditing(true)
          UIApplication.shared.keyWindow?.ne_makeToast(commonLocalizable("network_error"))
          return
        }
        delegate?.didStartClick?()
        changeToTranslatingState()
      } else {
        changeToIdleState(true)
      }
    }
  }

  public func setTranslateContent(_ content: String) {
    if translateState == .Translating {
      showTranslateContentText.text = content
      changeToUseState()
    }
  }

  /// 恢复默认状态
  /// - Parameter isClearText: 是否清空输入框
  public func changeToIdleState(_ isClearText: Bool = false) {
    translateState = .Idle
    if isClearText {
      showTranslateContentText.text = ""
    }
    statusLabel.attributedText = translateString
    loadingAnimationView.isHidden = true
    loadingAnimationView.stop()
  }

  /// 进入处理中状态
  public func changeToTranslatingState() {
    translateState = .Translating
    statusLabel.attributedText = processingString
    loadingAnimationView.isHidden = false
    loadingAnimationView.play()
  }

  /// 进入翻译完成状态(等待使用)
  public func changeToUseState() {
    translateState = .Use
    statusLabel.attributedText = useAttributeString
    loadingAnimationView.isHidden = true
    loadingAnimationView.stop()
  }
}
