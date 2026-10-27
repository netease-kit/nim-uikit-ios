// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NIMSDK
import UIKit

public extension NEMarkdownParser {
  @objc(customElements)
  var objcCustomElements: [NEMarkdownElementObjC] {
    get {
      customElements.map { element in
        if let adapter = element as? NEMarkdownObjCElementAdapter {
          return adapter.source
        }
        if let objcElement = element as? NEMarkdownElementObjC {
          return objcElement
        }
        return NEMarkdownSwiftElementAdapter(element)
      }
    }
    set {
      customElements = newValue.map { element in
        (element as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter(element)
      }
    }
  }

  @objc(enabledElements)
  var objcEnabledElements: NEMarkdownEnabledElementsObjC {
    get { NEMarkdownEnabledElementsObjC(enabledElements) }
    set { enabledElements = newValue.swiftValue }
  }

  @objc(enabledElementsBitmask)
  var objcEnabledElementsBitmask: UInt {
    get { UInt(bitPattern: enabledElements.rawValue) }
    set { enabledElements = .init(rawValue: Int(bitPattern: newValue)) }
  }

  @objc(enabledElementsObject)
  var objcEnabledElementsObject: NEMarkdownEnabledElementsObjC {
    get { NEMarkdownEnabledElementsObjC(enabledElements) }
    set { enabledElements = newValue.swiftValue }
  }

  @objc(initWithFont:color:enabledElements:customElements:)
  convenience init(objcFont font: UIFont,
                   color: UIColor,
                   enabledElements: NEMarkdownEnabledElementsObjC,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(font: font,
              color: color,
              enabledElements: enabledElements.swiftValue,
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(initWithFont:color:enabledElementsBitmask:customElements:)
  convenience init(objcFont font: UIFont,
                   color: UIColor,
                   enabledElements: UInt,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(font: font,
              color: color,
              enabledElements: .init(rawValue: Int(bitPattern: enabledElements)),
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(initWithFont:color:enabledElementsObject:customElements:)
  convenience init(objcFont font: UIFont,
                   color: UIColor,
                   enabledElementsObject: NEMarkdownEnabledElementsObjC,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(font: font,
              color: color,
              enabledElements: enabledElementsObject.swiftValue,
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(initWithAutomaticLinkDetectionEnabled:font:customElements:)
  convenience init(objcAutomaticLinkDetectionEnabled enabled: Bool,
                   font: UIFont,
                   customElements: [NEMarkdownElementObjC]) {
    self.init(automaticLinkDetectionEnabled: enabled,
              font: font,
              customElements: customElements.map {
                ($0 as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter($0)
              })
  }

  @objc(addCustomElement:)
  func objcAddCustomElement(_ element: NEMarkdownElementObjC) {
    addCustomElement((element as? NEMarkdownElement) ?? NEMarkdownObjCElementAdapter(element))
  }

  @objc(removeCustomElement:)
  func objcRemoveCustomElement(_ element: NEMarkdownElementObjC) {
    if let swiftElement = element as? NEMarkdownElement {
      removeCustomElement(swiftElement)
      return
    }
    guard let adapter = customElements.first(where: {
      ($0 as? NEMarkdownObjCElementAdapter)?.source === element
    }) else {
      return
    }
    removeCustomElement(adapter)
  }
}

public extension NEMarkdownTableView {
  @objc(initWithData:maxWidth:)
  convenience init(objcData data: NEMarkdownTableDataObjC, maxWidth: CGFloat) {
    self.init(data: data.swiftValue, maxWidth: maxWidth)
  }

  @objc(calculateHeightWithData:maxWidth:headerFont:cellFont:cellPadding:borderWidth:)
  static func objcCalculateHeight(data: NEMarkdownTableDataObjC,
                                  maxWidth: CGFloat,
                                  headerFont: UIFont,
                                  cellFont: UIFont,
                                  cellPadding: CGFloat,
                                  borderWidth: CGFloat) -> CGFloat {
    calculateHeight(data: data.swiftValue,
                    maxWidth: maxWidth,
                    headerFont: headerFont,
                    cellFont: cellFont,
                    cellPadding: cellPadding,
                    borderWidth: borderWidth)
  }
}
