// Copyright (c) 2026 NetEase, Inc. All rights reserved.

import UIKit

@objcMembers
public final class NETextSearchLayoutResult: NSObject {
  public let text: String
  public let matchRange: NSRange

  public init(text: String, matchRange: NSRange) {
    self.text = text
    self.matchRange = matchRange
    super.init()
  }
}

@objcMembers
public final class NETextSearchLayout: NSObject {
  /// Returns the complete value when it fits, otherwise keeps the match and
  /// builds the largest measured one-line window that fits the label width.
  public static func result(text: String,
                            matchRange: NSRange,
                            font: UIFont,
                            maxWidth: CGFloat) -> NETextSearchLayoutResult {
    guard maxWidth > 0,
          matchRange.location != NSNotFound,
          matchRange.location >= 0,
          NSMaxRange(matchRange) <= (text as NSString).length,
          let range = Range(matchRange, in: text) else {
      return NETextSearchLayoutResult(text: text, matchRange: matchRange)
    }

    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let measure: (String) -> CGFloat = { value in
      (value as NSString).size(withAttributes: attributes).width
    }
    guard measure(text) > maxWidth else {
      return NETextSearchLayoutResult(text: text, matchRange: matchRange)
    }

    let characters = Array(text)
    let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
    let matchEnd = matchStart + text.distance(from: range.lowerBound, to: range.upperBound)
    guard matchStart >= 0, matchEnd <= characters.count else {
      return NETextSearchLayoutResult(text: text, matchRange: matchRange)
    }

    var best: (text: String, range: NSRange, retained: Int, marks: Int, balance: Int)?
    for start in 0...matchStart {
      for end in matchEnd...characters.count {
        let content = String(characters[start..<end])
        let omittedPrefix = start > 0
        let omittedSuffix = end < characters.count
        // An omitted side must be represented by an ellipsis. This prevents
        // silently dropping unmatched text when a measured window is used.
        for prefixMark in omittedPrefix ? [true] : [false] {
          for suffixMark in omittedSuffix ? [true] : [false] {
            let candidate = (prefixMark ? "…" : "") + content + (suffixMark ? "…" : "")
            guard measure(candidate) <= maxWidth + 0.5 else { continue }
            let prefixLength = prefixMark ? 1 : 0
            let candidateRange = NSRange(
              location: prefixLength + String(characters[start..<matchStart]).utf16.count,
              length: String(characters[matchStart..<matchEnd]).utf16.count
            )
            let retained = content.utf16.count
            let marks = (prefixMark ? 1 : 0) + (suffixMark ? 1 : 0)
            let balance = -abs((matchStart - start) - (end - matchEnd))
            let candidateValue = (candidate, candidateRange, retained, marks, balance)
            if best == nil || isBetter(candidateValue, than: best!) {
              best = candidateValue
            }
          }
        }
      }
    }

    if let best {
      return NETextSearchLayoutResult(text: best.text, matchRange: best.range)
    }
    // A match wider than the label cannot be made fully visible. Returning it
    // intact avoids silently truncating the highlighted substring.
    return NETextSearchLayoutResult(text: String(text[range]),
                                    matchRange: NSRange(location: 0, length: matchRange.length))
  }

  private static func isBetter(_ candidate: (String, NSRange, Int, Int, Int),
                               than current: (text: String, range: NSRange, retained: Int, marks: Int, balance: Int)) -> Bool {
    if candidate.3 != current.marks { return candidate.3 < current.marks }
    if candidate.2 != current.retained { return candidate.2 > current.retained }
    return candidate.4 > current.balance
  }
}
