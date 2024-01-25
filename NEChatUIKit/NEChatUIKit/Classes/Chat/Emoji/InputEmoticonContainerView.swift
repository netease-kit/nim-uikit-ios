
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit
@objc public protocol InputEmoticonContainerViewDelegate: NSObjectProtocol {
  func selectedEmoticon(emoticonID: String, emotCatalogID: String, description: String)
  func didPressSend(sender: UIButton)
}

open class InputEmoticonContainerView: UIView {
  private let classTag = "InputEmoticonContainerView"
  public weak var delegate: InputEmoticonContainerViewDelegate?

  private var _totalCatalogData: [NIMInputEmoticonCatalog]?
  private var totalCatalogData: [NIMInputEmoticonCatalog]? {
    set {
      _totalCatalogData = newValue
      tabView.loadCatalogs(newValue)
    }
    get {
      _totalCatalogData
    }
  }

  private var _currentCatalogData: NIMInputEmoticonCatalog?
  private var currentCatalogData: NIMInputEmoticonCatalog? {
    set {
      _currentCatalogData = newValue
      if let currentData = newValue {
        emoticonPageView
          .scrollToPage(page: pageIndexWithEmoticon(emoticonCatalog: currentData))
      }
    }
    get {
      _currentCatalogData
    }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setUpSubViews()
    loadEmojiData()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setUpSubViews() {
    addSubview(emoticonPageView)
    addSubview(tabView)

    NSLayoutConstraint.activate([
      emoticonPageView.topAnchor.constraint(equalTo: topAnchor),
      emoticonPageView.rightAnchor.constraint(equalTo: rightAnchor),
      emoticonPageView.leftAnchor.constraint(equalTo: leftAnchor),
      emoticonPageView.heightAnchor.constraint(equalToConstant: 159),
    ])

    NSLayoutConstraint.activate([
      tabView.bottomAnchor.constraint(equalTo: bottomAnchor),
      tabView.rightAnchor.constraint(equalTo: rightAnchor),
      tabView.leftAnchor.constraint(equalTo: leftAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 35),
    ])
  }

  func loadEmojiData() {
    let data = loadCatalogAndChartlet()
    totalCatalogData = data
    currentCatalogData = data?.first
  }

  func loadCatalogAndChartlet() -> [NIMInputEmoticonCatalog]? {
    if let cataLog = loadDefaultCatalog() {
      return [cataLog]
    } else {
      return nil
    }
  }

  // 加载默认emoji
  func loadDefaultCatalog() -> NIMInputEmoticonCatalog? {
    let emoticonCatalog = NIMInputEmoticonManager.shared
      .emoticonCatalog(catalogID: NIMKit_EmojiCatalog)
    let layout = NIMInputEmoticonLayout(width: width)
    emoticonCatalog?.layout = layout
    emoticonCatalog?.pagesCount = numberOfPagesWithEmoticon(emoticonCatalog: emoticonCatalog)
    return emoticonCatalog
  }

  // 找到某组表情的起始位置
  func pageIndexWithEmoticon(emoticonCatalog: NIMInputEmoticonCatalog) -> NSInteger {
    var pageIndex = 0
    if let totalData = totalCatalogData {
      for emoticon in totalData {
        if emoticon == emoticonCatalog {
          break
        }
        pageIndex += emoticon.pagesCount
      }
      return pageIndex
    }
    return pageIndex
  }

  func pageIndexWithTotalIndex(index: NSInteger) -> NSInteger {
    let cateLog = emoticonWithIndex(index: index)
    let begin = pageIndexWithEmoticon(emoticonCatalog: cateLog)
    return index - begin
  }

  func emoticonWithIndex(index: NSInteger) -> NIMInputEmoticonCatalog {
    var page = 0
    var resultEmotion = NIMInputEmoticonCatalog()

    guard let totalData = totalCatalogData else {
      return resultEmotion
    }

    for emotion in totalData {
      let newPage = page + emotion.pagesCount
      if newPage > index {
        resultEmotion = emotion
        break
      }
      page = newPage
    }
    return resultEmotion
  }

  func numberOfPagesWithEmoticon(emoticonCatalog: NIMInputEmoticonCatalog?) -> NSInteger {
    if let emotionsCount = emoticonCatalog?.emoticons?.count,
       let layoutCount = emoticonCatalog?.layout?.itemCountInPage {
      if emotionsCount % layoutCount == 0 {
        return emotionsCount / layoutCount
      } else {
        return emotionsCount / layoutCount + 1
      }
    } else {
      NELog.errorLog(classTag, desc: "❌count maybe nil")
      return 0
    }
  }

  // MAKR: lazy method
  private lazy var emoticonPageView: EmojiPageView = {
    let pageView = EmojiPageView(frame: self.bounds)
    pageView.translatesAutoresizingMaskIntoConstraints = false
    pageView.dataSource = self
    pageView.pageViewDelegate = self
    return pageView
  }()

  private lazy var tabView: InputEmoticonTabView = {
    let pageView = InputEmoticonTabView(frame: CGRect.zero)
    pageView.translatesAutoresizingMaskIntoConstraints = false
    pageView.delegate = self
    pageView.sendButton.addTarget(self, action: #selector(didPressSend), for: .touchUpInside)
    return pageView
  }()
}

// MARK: ================= config data ==================

extension InputEmoticonContainerView {
  func sumPages() -> NSInteger {
    var pagesCount = 0

    guard let totalData = totalCatalogData else {
      return pagesCount
    }
    for cataLogData in totalData {
      pagesCount += cataLogData.pagesCount
    }
    return pagesCount
  }

  func emojiPageView(pageView: EmojiPageView, emoticon: NIMInputEmoticonCatalog,
                     page: NSInteger) -> UIView {
    let subView = UIView()
    guard let layout = emoticon.layout else {
      NELog.errorLog(classTag, desc: "layout is nil")
      return UIView()
    }

    guard let emotions = emoticon.emoticons else {
      NELog.errorLog(classTag, desc: "emoticon.emoticons is nil")
      return UIView()
    }

    let iconHeight = layout.imageHeight
    let iconWidth = layout.imageWidth
    let startX = Int(layout.cellWidth - iconWidth) / 2 + NIMKit_EmojiLeftMargin
    let startY = Int(layout.cellHeight - iconHeight) / 2 + NIMKit_EmojiTopMargin
    var coloumnIndex = 0
    var rowIndex = 0
    var indexInPage = 0
    let begin = page * layout.itemCountInPage
    var end = begin + layout.itemCountInPage
    end = end > emotions.count ? emotions.count : end
    for i in begin ..< end {
      let data = emotions[i]
      if let id = emoticon.catalogID {
        let button = NIMInputEmoticonButton.iconButtonWithData(
          data: data,
          catalogID: id,
          delegate: self
        )
        rowIndex = indexInPage / layout.columes
        coloumnIndex = indexInPage % layout.columes
        let x = coloumnIndex * Int(layout.cellWidth) + startX
        let y = rowIndex * Int(layout.cellHeight) + startY
        let iconRect = CGRect(
          x: CGFloat(x),
          y: CGFloat(y),
          width: iconWidth,
          height: iconHeight
        )
        button.frame = iconRect
        subView.addSubview(button)
        indexInPage += 1
      }
    }

    if coloumnIndex == layout.columes - 1 {
      rowIndex += 1
      coloumnIndex = -1 // 设置成-1是因为显示在第0位，有加1
    }

    if emoticon.catalogID == NIMKit_EmojiCatalog {
      addDeleteEmotButtonToView(
        view: subView,
        coloumnIndex: coloumnIndex,
        rowIndex: rowIndex,
        startX: CGFloat(startX),
        startY: CGFloat(startY),
        iconWidth: iconWidth,
        iconHeight: iconHeight,
        emotion: emoticon
      )
    }
    return subView
  }

  func addDeleteEmotButtonToView(view: UIView, coloumnIndex: NSInteger, rowIndex: NSInteger,
                                 startX: CGFloat, startY: CGFloat, iconWidth: CGFloat,
                                 iconHeight: CGFloat, emotion: NIMInputEmoticonCatalog) {
    guard let layout = emotion.layout else {
      NELog.errorLog(classTag, desc: "❌emotion is nill")
      return
    }

    let deleteIcon = NIMInputEmoticonButton()
    deleteIcon.isUserInteractionEnabled = true
    deleteIcon.isExclusiveTouch = true
    deleteIcon.contentMode = .center
    deleteIcon.delegate = self
    deleteIcon.setImage(UIImage.ne_imageNamed(name: "emoji_del_normal"), for: .normal)
    deleteIcon.setImage(UIImage.ne_imageNamed(name: "emoji_del_pressed"), for: .highlighted)
    deleteIcon.addTarget(self, action: #selector(onIconSelected), for: .touchUpInside)
    let newX = CGFloat(coloumnIndex + 1) * layout.cellWidth + startX
    let newY = CGFloat(rowIndex) * layout.cellHeight + startY
    let deleteIconRect = CGRect(
      x: newX,
      y: newY,
      width: NIMKit_DeleteIconWidth,
      height: NIMKit_DeleteIconHeight
    )
    deleteIcon.frame = deleteIconRect
    view.addSubview(deleteIcon)
  }

  @objc func onIconSelected(sender: NIMInputEmoticonButton) {
    delegate?.selectedEmoticon(emoticonID: "", emotCatalogID: "", description: "")
  }

  @objc func didPressSend(sender: UIButton) {
    print("did press send")
    delegate?.didPressSend(sender: sender)
  }
}

// MARK: ====== EmojiPageViewDelegate,EmojiPageViewDataSource ==============

extension InputEmoticonContainerView: EmojiPageViewDelegate, EmojiPageViewDataSource {
  open func numberOfPages(pageView: EmojiPageView?) -> NSInteger {
    sumPages()
  }

  open func pageView(pageView: EmojiPageView?, index: NSInteger) -> UIView {
    var page = 0
    var resultEmotion = NIMInputEmoticonCatalog()

    guard let totalData = totalCatalogData, let targetView = pageView else {
      NELog.errorLog(classTag, desc: "❌totalCatalogData is nil")
      return UIView()
    }

    for emotion in totalData {
      let newPage = page + emotion.pagesCount
      if newPage > index {
        resultEmotion = emotion
        break
      }
      page = newPage
    }
    return emojiPageView(pageView: targetView, emoticon: resultEmotion, page: index - page)
  }

  open func needScrollAnimation() -> Bool {
    true
  }

  open func pageViewDidScroll(_ pageView: EmojiPageView?) {}

  open func pageViewScrollEnd(_ pageView: EmojiPageView?, currentIndex: Int, totolPages: Int) {
//        let emticon = emoticonWithIndex(index: currentIndex)
    // 补充pageController逻辑
  }
}

// MARK: =============== InputEmoticonTabViewDelegate ===============

extension InputEmoticonContainerView: InputEmoticonTabViewDelegate {
  open func tabView(_ tabView: InputEmoticonTabView?, didSelectTabIndex index: Int) {}
}

// MARK: =============== InputEmoticonTabViewDelegate ===============

extension InputEmoticonContainerView: NIMInputEmoticonButtonDelegate {
  open func selectedEmoticon(emotion: NIMInputEmoticon, catalogID: String) {
    guard let emotionId = emotion.emoticonID else {
      NELog.errorLog(classTag, desc: "❌emoticonID is nil")
      return
    }
    if emotion.type == .unicode {
      delegate?.selectedEmoticon(
        emoticonID: emotionId,
        emotCatalogID: catalogID,
        description: emotion.unicode ?? ""
      )
    } else {
      delegate?.selectedEmoticon(
        emoticonID: emotionId,
        emotCatalogID: catalogID,
        description: emotion.tag ?? ""
      )
    }
  }
}
