
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc
public protocol EmojiPageViewDataSource: NSObjectProtocol {
  @objc optional func numberOfPages(pageView: EmojiPageView?) -> NSInteger
  @objc optional func pageView(pageView: EmojiPageView?, index: NSInteger) -> UIView
}

@objc
public protocol EmojiPageViewDelegate: NSObjectProtocol {
  @objc optional func pageViewScrollEnd(_ pageView: EmojiPageView?,
                                        currentIndex: Int,
                                        totolPages: Int)
  @objc optional func pageViewDidScroll(_ pageView: EmojiPageView?)
  @objc optional func needScrollAnimation() -> Bool
}

@objcMembers
open class EmojiPageView: UIView {
  open weak var dataSource: EmojiPageViewDataSource?
  open weak var pageViewDelegate: EmojiPageViewDelegate?

  private var currentPage = 0
  private var pages = [UIView?]()
  private var lastLayoutSize = CGSize.zero
  private var isUserScrolling = false

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView(frame: bounds)
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.isPagingEnabled = true
    scrollView.delegate = self
    scrollView.scrollsToTop = false
    return scrollView
  }()

  var pageSlotCount: Int {
    pages.count
  }

  var loadedPageIndexes: [Int] {
    pages.indices.filter { pages[$0] != nil }
  }

  var hasActiveScrollDelegate: Bool {
    scrollView.delegate === self
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupControls()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupControls()
  }

  private func setupControls() {
    addSubview(scrollView)
  }

  open func scrollToPage(page: NSInteger) {
    let targetPage = boundedPage(page)
    let shouldAnimate = pageViewDelegate?.needScrollAnimation?() ?? false
    setCurrentPage(targetPage, animated: shouldAnimate, notifyImmediately: !shouldAnimate)
  }

  func scrollToPage(page: NSInteger, animated: Bool) {
    let targetPage = boundedPage(page)
    setCurrentPage(targetPage, animated: animated, notifyImmediately: !animated)
  }

  open func reloadData() {
    reloadData(currentPage: currentPage)
  }

  func reloadData(currentPage targetPage: Int) {
    isUserScrolling = false
    pages.forEach { $0?.removeFromSuperview() }
    let pageCount = max(0, dataSource?.numberOfPages?(pageView: self) ?? 0)
    pages = Array(repeating: nil, count: pageCount)
    currentPage = boundedPage(targetPage)
    scrollView.delegate = self
    updatePageFrames()
    loadPages(around: currentPage)
    setContentOffset(page: currentPage, animated: false)
    raisePageIndexChangedDelegate()
  }

  func viewAtIndex(index: NSInteger) -> UIView? {
    guard pages.indices.contains(index) else {
      return nil
    }
    return pages[index]
  }

  private func boundedPage(_ page: Int) -> Int {
    guard !pages.isEmpty else {
      return 0
    }
    return min(max(page, 0), pages.count - 1)
  }

  private func setCurrentPage(_ page: Int, animated: Bool, notifyImmediately: Bool) {
    let targetPage = boundedPage(page)
    isUserScrolling = false
    currentPage = targetPage
    loadPages(around: targetPage)
    setContentOffset(page: targetPage, animated: animated)
    if notifyImmediately {
      raisePageIndexChangedDelegate()
    }
  }

  private func setContentOffset(page: Int, animated: Bool) {
    guard bounds.width > 0 else {
      return
    }
    let targetOffset = CGPoint(x: CGFloat(page) * bounds.width, y: 0)
    scrollView.setContentOffset(
      targetOffset,
      animated: animated
    )
  }

  private func updatePageFrames() {
    scrollView.frame = bounds
    scrollView.contentSize = CGSize(
      width: bounds.width * CGFloat(pages.count),
      height: bounds.height
    )
    for index in pages.indices {
      pages[index]?.frame = frameForPage(index)
    }
  }

  private func frameForPage(_ index: Int) -> CGRect {
    CGRect(
      x: bounds.width * CGFloat(index),
      y: 0,
      width: bounds.width,
      height: bounds.height
    )
  }

  private func loadPages(around page: Int) {
    guard !pages.isEmpty else {
      return
    }
    let first = max(page - 1, 0)
    let last = min(page + 1, pages.count - 1)

    for index in pages.indices {
      if (first ... last).contains(index) {
        guard pages[index] == nil,
              let pageView = dataSource?.pageView?(pageView: self, index: index) else {
          continue
        }
        pageView.frame = frameForPage(index)
        pages[index] = pageView
        scrollView.addSubview(pageView)
      } else if let pageView = pages[index] {
        pageView.removeFromSuperview()
        pages[index] = nil
      }
    }
  }

  private func pageForCurrentOffset() -> Int {
    guard bounds.width > 0, !pages.isEmpty else {
      return 0
    }
    let rawPage = scrollView.contentOffset.x / bounds.width
    return boundedPage(Int(rawPage.rounded()))
  }

  private func finishScrolling() {
    isUserScrolling = false
    currentPage = pageForCurrentOffset()
    loadPages(around: currentPage)
    setContentOffset(page: currentPage, animated: false)
    raisePageIndexChangedDelegate()
  }

  private func raisePageIndexChangedDelegate() {
    pageViewDelegate?.pageViewScrollEnd?(
      self,
      currentIndex: currentPage,
      totolPages: pages.count
    )
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    let sizeChanged = bounds.size != lastLayoutSize
    lastLayoutSize = bounds.size
    updatePageFrames()
    if sizeChanged {
      setContentOffset(page: currentPage, animated: false)
      loadPages(around: currentPage)
    }
  }
}

extension EmojiPageView: UIScrollViewDelegate {
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let visiblePage = pageForCurrentOffset()
    loadPages(around: visiblePage)
    if isUserScrolling, currentPage != visiblePage {
      currentPage = visiblePage
      raisePageIndexChangedDelegate()
    }
    pageViewDelegate?.pageViewDidScroll?(self)
  }

  open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    isUserScrolling = true
  }

  open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    finishScrolling()
  }

  open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      finishScrolling()
    }
  }

  open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    if !isUserScrolling {
      finishScrolling()
    }
  }
}
