// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A generic result builder that enables a DSL for building arrays of Epoxy models.
@resultBuilder
enum NEEpoxyModelArrayBuilder<NEModel> {
  typealias Expression = NEModel
  typealias Component = [NEModel]

  static func buildExpression(_ expression: Expression) -> Component {
    [expression]
  }

  static func buildExpression(_ expression: Component) -> Component {
    expression
  }

  static func buildExpression(_ expression: Expression?) -> Component {
    if let expression {
      return [expression]
    }
    return []
  }

  static func buildBlock(_ children: Component...) -> Component {
    children.flatMap { $0 }
  }

  static func buildBlock(_ component: Component) -> Component {
    component
  }

  static func buildOptional(_ children: Component?) -> Component {
    children ?? []
  }

  static func buildEither(first child: Component) -> Component {
    child
  }

  static func buildEither(second child: Component) -> Component {
    child
  }

  static func buildArray(_ components: [Component]) -> Component {
    components.flatMap { $0 }
  }
}
