// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: - NECoordinateSpace

public enum NECoordinateSpace: Int, Codable, Sendable {
  case type2d
  case type3d
}

// MARK: - NELottieAnimation

/// The `NELottieAnimation` model is the top level model object in Lottie.
///
/// A `NELottieAnimation` holds all of the animation data backing a Lottie Animation.
/// Codable, see JSON schema [here](https://github.com/airbnb/lottie-web/tree/master/docs/json).
public final class NELottieAnimation: Codable, Sendable, NEDictionaryInitializable {
  // MARK: Lifecycle

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: NELottieAnimation.NECodingKeys.self)
    Version = try container.decode(String.self, forKey: .NEVersion)
    type = try container.decodeIfPresent(NECoordinateSpace.self, forKey: .type) ?? .type2d
    startFrame = try container.decode(NEAnimationFrameTime.self, forKey: .startFrame)
    endFrame = try container.decode(NEAnimationFrameTime.self, forKey: .endFrame)
    framerate = try container.decode(Double.self, forKey: .framerate)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    layers = try container.decode([NELayerModel].self, ofFamily: NELayerType.self, forKey: .layers)
    glyphs = try container.decodeIfPresent([NEGlyph].self, forKey: .glyphs)
    fonts = try container.decodeIfPresent(NEFontList.self, forKey: .fonts)
    assetLibrary = try container.decodeIfPresent(NEAssetLibrary.self, forKey: .assetLibrary)
    markers = try container.decodeIfPresent([NEMarker].self, forKey: .markers)

    if let markers {
      var markerMap: [String: NEMarker] = [:]
      for marker in markers {
        markerMap[marker.name] = marker
      }
      self.markerMap = markerMap
    } else {
      markerMap = nil
    }
  }

  public init(dictionary: [String: Any]) throws {
    Version = try dictionary.value(for: NECodingKeys.NEVersion)
    if
      let typeRawValue = dictionary[NECodingKeys.type.rawValue] as? Int,
      let type = NECoordinateSpace(rawValue: typeRawValue) {
      self.type = type
    } else {
      type = .type2d
    }
    startFrame = try dictionary.value(for: NECodingKeys.startFrame)
    endFrame = try dictionary.value(for: NECodingKeys.endFrame)
    framerate = try dictionary.value(for: NECodingKeys.framerate)
    width = try dictionary.value(for: NECodingKeys.width)
    height = try dictionary.value(for: NECodingKeys.height)
    let layerDictionaries: [[String: Any]] = try dictionary.value(for: NECodingKeys.layers)
    layers = try [NELayerModel].fromDictionaries(layerDictionaries)
    if let glyphDictionaries = dictionary[NECodingKeys.glyphs.rawValue] as? [[String: Any]] {
      glyphs = try glyphDictionaries.map { try NEGlyph(dictionary: $0) }
    } else {
      glyphs = nil
    }
    if let fontsDictionary = dictionary[NECodingKeys.fonts.rawValue] as? [String: Any] {
      fonts = try NEFontList(dictionary: fontsDictionary)
    } else {
      fonts = nil
    }
    if let assetLibraryDictionaries = dictionary[NECodingKeys.assetLibrary.rawValue] as? [[String: Any]] {
      assetLibrary = try NEAssetLibrary(value: assetLibraryDictionaries)
    } else {
      assetLibrary = nil
    }
    if let markerDictionaries = dictionary[NECodingKeys.markers.rawValue] as? [[String: Any]] {
      let markers = try markerDictionaries.map { try NEMarker(dictionary: $0) }
      var markerMap: [String: NEMarker] = [:]
      for marker in markers {
        markerMap[marker.name] = marker
      }
      self.markers = markers
      self.markerMap = markerMap
    } else {
      markers = nil
      markerMap = nil
    }
  }

  // MARK: Public

  /// The start time of the composition in frameTime.
  public let startFrame: NEAnimationFrameTime

  /// The end time of the composition in frameTime.
  public let endFrame: NEAnimationFrameTime

  /// The frame rate of the composition.
  public let framerate: Double

  /// Return all marker names, in order, or an empty list if none are specified
  public var markerNames: [String] {
    guard let markers else { return [] }
    return markers.map { $0.name }
  }

  // MARK: Internal

  enum NECodingKeys: String, CodingKey {
    case NEVersion = "v"
    case type = "ddd"
    case startFrame = "ip"
    case endFrame = "op"
    case framerate = "fr"
    case width = "w"
    case height = "h"
    case layers
    case glyphs = "chars"
    case fonts
    case assetLibrary = "assets"
    case markers
  }

  /// The NEVersion of the JSON Schema.
  let Version: String

  /// The coordinate space of the composition.
  let type: NECoordinateSpace

  /// The height of the composition in points.
  let width: Double

  /// The width of the composition in points.
  let height: Double

  /// The list of animation layers
  let layers: [NELayerModel]

  /// The list of glyphs used for text rendering
  let glyphs: [NEGlyph]?

  /// The list of fonts used for text rendering
  let fonts: NEFontList?

  /// NEAsset Library
  let assetLibrary: NEAssetLibrary?

  /// Markers
  let markers: [NEMarker]?
  let markerMap: [String: NEMarker]?

  /// The marker to use if "reduced motion" is enabled.
  /// Supported marker names are case insensitive, and include:
  ///  - reduced motion
  ///  - reducedMotion
  ///  - reduced_motion
  ///  - reduced-motion
  var reducedMotionMarker: NEMarker? {
    let allowedReducedMotionMarkerNames = Set([
      "reduced motion",
      "reduced_motion",
      "reduced-motion",
      "reducedmotion",
    ])

    return markers?.first(where: { marker in
      allowedReducedMotionMarkerNames.contains(marker.name.lowercased())
    })
  }
}
