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

    public static let disabledAutomaticLink: NEEnabledElements = [
      .header,
      .list,
      .quote,
      .link,
      .bold,
      .italic,
      .code,
      .strikethrough,
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
    let attributedString = NSMutableAttributedString(attributedString: markdown)
    attributedString.addAttribute(.font, value: font,
                                  range: NSRange(location: 0, length: attributedString.length))
    attributedString.addAttribute(.foregroundColor, value: color,
                                  range: NSRange(location: 0, length: attributedString.length))
    var elements: [NEMarkdownElement] = escapingElements
    elements.append(contentsOf: defaultElements)
    elements.append(contentsOf: customElements)
    elements.append(contentsOf: unescapingElements)
    for element in elements {
      element.parse(attributedString)
    }
    return attributedString
  }

  private func updateDefaultElements() {
    let pairs: [(NEEnabledElements, NEMarkdownElement)] = [
      (.automaticLink, automaticLink),
      (.header, header),
      (.list, list),
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
