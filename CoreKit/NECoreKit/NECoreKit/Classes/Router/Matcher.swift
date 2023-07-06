
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public class RouteRequest {
  private(set) var urlString: String?
  /// 路由携带的参数
  private(set) var routeParams: [String: Any]?
  /// 查询参数
  fileprivate(set) var queryParams: [String: Any]?
  /// 原始参数
  fileprivate(set) var originalParams: [String: Any]?
  init(_ url: String,
       params: [String: Any]? = nil,
       queryParams: [String: Any]? = nil,
       originalParams: [String: Any]? = nil) {
    urlString = url
    routeParams = params
    self.queryParams = queryParams
    self.originalParams = originalParams
  }

  /// 所有参数
  public var allParams: [String: Any] {
    var allParams = [String: Any]()
    if let params = routeParams {
      allParams.merge(params) { _, last in last }
    }
    if let querys = queryParams {
      allParams.merge(querys, uniquingKeysWith: { _, last in last })
    }
    if let originals = originalParams {
      allParams.merge(originals, uniquingKeysWith: { _, last in last })
    }
    return allParams
  }

  public subscript(key: String) -> Any? {
    allParams[key]
  }
}

/// 路由 匹配器
public class Matcher {
  private let _handleClosure: RouteAsyncHandle
  public var handleClosure: RouteAsyncHandle { _handleClosure }
  public var routeRegular: Regular?

  // MARK: - ------------ Public method --------------------

  public init(_ expression: String, closure: @escaping RouteAsyncHandle) {
    _handleClosure = closure
    routeRegular = Regular.regular(with: expression)
  }

  public func createRequest(_ pattern: String?, originalParams: [String: Any]?) -> RouteRequest? {
    guard var pattern = pattern else { return nil }
    let patterns = Regular.match("[^\\?]+", original: pattern)
    guard patterns.count > 0 else { return nil }
    var queryParamDic = [String: Any]()
    if patterns.count > 1 {
      pattern = patterns[0]
      let queryString = patterns[1]
      queryParamDic = queryString.routeParamsFromQuery()
    }
    let result = routeRegular?.result(with: pattern)
    guard result?.isMatch ?? false else { return nil }
    return RouteRequest(pattern,
                        params: result?.params,
                        queryParams: queryParamDic,
                        originalParams: originalParams)
  }
}

extension String {
  func routeParamsFromQuery() -> [String: Any] {
    guard count > 0 else { return [String: Any]() }
    let params = components(separatedBy: "&")
    var paramDic = [String: Any]()
    params.forEach { param in
      let pairs = param.components(separatedBy: "=")
      if pairs.count == 2 {
        let key = pairs[0].removingPercentEncoding!
        let value = pairs[1].removingPercentEncoding!
        paramDic[key] = value
      } else if pairs.count == 1 {
        let key = pairs[0].removingPercentEncoding!
        paramDic[key] = ""
      }
    }
    return paramDic
  }
}
