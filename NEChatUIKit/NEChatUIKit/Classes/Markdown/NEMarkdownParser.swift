// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

open class NEMarkdownParser {
  public struct NEEnabledElements: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public static let automaticLink = NEEnabledElements(rawValue: 1)
    public static let header = NEEnabledElements(rawValue: 1 << 1)
    public static let list = NEEnabledElements(rawValue: 1 << 2)
    public static let quote = NEEnabledElements(rawValue: 1 << 3)
    public static let link = NEEnabledElements(rawValue: 1 << 4)
    public static let bold = NEEnabledElements(rawValue: 1 << 5)
    public static let italic = NEEnabledElements(rawValue: 1 << 6)
    public static let code = NEEnabledElements(rawValue: 1 << 7)
    public static let strikethrough = NEEnabledElements(rawValue: 1 << 8)
    public static let table = NEEnabledElements(rawValue: 1 << 9)
    public static let orderedList = NEEnabledElements(rawValue: 1 << 10)
    public static let horizontalRule = NEEnabledElements(rawValue: 1 << 11)
    public static let image = NEEnabledElements(rawValue: 1 << 12)

    public static let disabledAutomaticLink: NEEnabledElements = [
      .header,
      .list,
      .quote,
      .link,
      .bold,
      .italic,
      .code,
      .strikethrough,
      .table,
      .orderedList,
      .horizontalRule,
      .image,
    ]

    public static let all: NEEnabledElements = [
      .disabledAutomaticLink,
      .automaticLink,
    ]
  }

  // MARK: Element Arrays

  private var escapingElements: [NEMarkdownElement]
  private var defaultElements: [NEMarkdownElement] = []
  private var unescapingElements: [NEMarkdownElement]

  open var customElements: [NEMarkdownElement]

  // MARK: Basic Elements

  public let header: NEMarkdownHeader
  public let list: NEMarkdownList
  public let quote: NEMarkdownQuote
  public let link: NEMarkdownLink
  public let automaticLink: NEMarkdownAutomaticLink
  public let bold: NEMarkdownBold
  public let italic: NEMarkdownItalic
  public let code: NEMarkdownCode
  public let strikethrough: NEMarkdownStrikethrough
  /// 表格解析 Element（GFM 表格语法）
  public let table: NEMarkdownTable
  /// 有序列表 Element（`1. 2. 3.`）
  public let orderedList: NEMarkdownOrderedList
  /// 分隔线 Element（`---` / `***` / `___`）
  public let horizontalRule: NEMarkdownHorizontalRule
  /// 图片 Element（`![alt](url)`）
  public let markdownImage: NEMarkdownImage

  // MARK: Escaping Elements

  private var codeEscaping = NEMarkdownCodeEscaping()
  private var escaping = NEMarkdownEscaping()
  private var unescaping = NEMarkdownUnescaping()

  // MARK: Configuration

  /// Enables individual Markdown elements and automatic link detection
  open var enabledElements: NEEnabledElements {
    didSet {
      updateDefaultElements()
      updateEscapingElements()
      updateUnescapingElements()
    }
  }

  public let font: UIFont
  public let color: UIColor

  // MARK: Legacy Initializer

  @available(*, deprecated, renamed: "init", message: "This constructor will be removed soon, please use the new opions constructor")
  public convenience init(automaticLinkDetectionEnabled: Bool,
                          font: UIFont = NEMarkdownParser.defaultFont,
                          customElements: [NEMarkdownElement] = []) {
    let enabledElements: NEEnabledElements = automaticLinkDetectionEnabled ? .all : .disabledAutomaticLink
    self.init(font: font, enabledElements: enabledElements, customElements: customElements)
  }

  // MARK: Initializer

  public init(font: UIFont = NEMarkdownParser.defaultFont,
              color: UIColor = NEMarkdownParser.defaultColor,
              enabledElements: NEEnabledElements = .all,
              customElements: [NEMarkdownElement] = []) {
    self.font = font
    self.color = color

    header = NEMarkdownHeader(font: font)
    list = NEMarkdownList(font: font)
    quote = NEMarkdownQuote(font: font)
    link = NEMarkdownLink(font: font)
    automaticLink = NEMarkdownAutomaticLink(font: font)
    bold = NEMarkdownBold(font: font)
    italic = NEMarkdownItalic(font: font)
    code = NEMarkdownCode(font: font)
    strikethrough = NEMarkdownStrikethrough(font: font)
    table = NEMarkdownTable()
    orderedList = NEMarkdownOrderedList(font: font)
    horizontalRule = NEMarkdownHorizontalRule()
    markdownImage = NEMarkdownImage()

    escapingElements = [codeEscaping, escaping]
    unescapingElements = [code, unescaping]
    self.customElements = customElements
    self.enabledElements = enabledElements
    updateDefaultElements()
    updateEscapingElements()
    updateUnescapingElements()
  }

  // MARK: Element Extensibility

  open func addCustomElement(_ element: NEMarkdownElement) {
    customElements.append(element)
  }

  open func removeCustomElement(_ element: NEMarkdownElement) {
    guard let index = customElements.firstIndex(where: { someElement -> Bool in
      element === someElement
    }) else {
      return
    }
    customElements.remove(at: index)
  }

  // MARK: Parsing

  open func parse(_ markdown: String) -> NSAttributedString {
    parse(NSAttributedString(string: markdown))
  }

  open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
    // ── 第一步：如果表格功能开启，先对纯文本做表格预处理 ──
    // 在 escapingElements 运行前处理，保证 | 字符不被转义。
    // 表格块被替换为 NSTextAttachment 占位符；剩余文本继续走正常 parse 流程。
    let preprocessed: NSAttributedString
    if enabledElements.contains(.table) {
      preprocessed = table.preprocess(markdown.string,
                                      font: font,
                                      color: color)
    } else {
      preprocessed = markdown
    }

    let attributedString = NSMutableAttributedString(attributedString: preprocessed)
    attributedString.addAttribute(.font, value: font,
                                  range: NSRange(location: 0, length: attributedString.length))
    attributedString.addAttribute(.foregroundColor, value: color,
                                  range: NSRange(location: 0, length: attributedString.length))

    // ── 第二步：其余 element 正常处理（表格已替换，不会被误处理）──
    // table element 本身不再加入 elements 列表（已在上面预处理）
    var elements: [NEMarkdownElement] = escapingElements
    elements.append(contentsOf: defaultElements.filter { $0 !== table })
    elements.append(contentsOf: customElements)
    elements.append(contentsOf: unescapingElements)
    for element in elements {
      element.parse(attributedString)
    }
    return attributedString
  }

  private func updateDefaultElements() {
    let pairs: [(NEEnabledElements, NEMarkdownElement)] = [
      // 图片必须在链接之前处理，防止 ![alt](url) 被误识别为链接
      (.image, markdownImage),
      // 分隔线必须在无序列表之前处理，防止 `---` 被误识别为列表标记
      (.horizontalRule, horizontalRule),
      // 表格必须在 bold/italic/code 之前处理，防止表格内容被提前处理
      (.table, table),
      (.automaticLink, automaticLink),
      (.header, header),
      (.list, list),
      (.orderedList, orderedList),
      (.quote, quote),
      (.link, link),
      (.bold, bold),
      (.italic, italic),
      (.code, code),
      (.strikethrough, strikethrough),
    ]
    defaultElements = pairs.filter { enabled, _ in
      enabledElements.contains(enabled)
    }
    .map { _, element in
      element
    }
  }

  private func updateEscapingElements() {
    if enabledElements.contains(.code) {
      escapingElements = [codeEscaping, escaping]
    } else {
      escapingElements = [escaping]
    }
  }

  private func updateUnescapingElements() {
    if enabledElements.contains(.code) {
      unescapingElements = [code, unescaping]
    } else {
      unescapingElements = [unescaping]
    }
  }
}
