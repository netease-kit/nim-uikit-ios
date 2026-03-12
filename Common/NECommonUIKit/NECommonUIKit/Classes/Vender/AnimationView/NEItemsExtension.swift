// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NENodeTree

final class NENodeTree {
  var rootNode: NEAnimatorNode?
  var transform: NEShapeTransform?
  var renderContainers: [NEShapeContainerLayer] = []
  var paths: [NEPathOutputNode] = []
  var childrenNodes: [NEAnimatorNode] = []
}

extension [NEShapeItem] {
  func initializeNodeTree() -> NENodeTree {
    let nodeTree = NENodeTree()

    for item in self {
      guard item.hidden == false, item.type != .unknown else { continue }
      if let fill = item as? NEFill {
        let node = NEFillNode(parentNode: nodeTree.rootNode, fill: fill)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let stroke = item as? NEStroke {
        let node = NEStrokeNode(parentNode: nodeTree.rootNode, stroke: stroke)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let gradientFill = item as? NEGradientFill {
        let node = NEGradientFillNode(parentNode: nodeTree.rootNode, gradientFill: gradientFill)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let gradientStroke = item as? NEGradientStroke {
        let node = NEGradientStrokeNode(parentNode: nodeTree.rootNode, gradientStroke: gradientStroke)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let ellipse = item as? NEEllipse {
        let node = NEEllipseNode(parentNode: nodeTree.rootNode, ellipse: ellipse)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let rect = item as? NERectangle {
        let node = NERectangleNode(parentNode: nodeTree.rootNode, rectangle: rect)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let star = item as? NEStar {
        switch star.starType {
        case .none:
          continue
        case .polygon:
          let node = NEPolygonNode(parentNode: nodeTree.rootNode, star: star)
          nodeTree.rootNode = node
          nodeTree.childrenNodes.append(node)
        case .star:
          let node = NEStarNode(parentNode: nodeTree.rootNode, star: star)
          nodeTree.rootNode = node
          nodeTree.childrenNodes.append(node)
        }
      } else if let shape = item as? NEShape {
        let node = NEShapeNode(parentNode: nodeTree.rootNode, shape: shape)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let trim = item as? NETrim {
        let node = NETrimPathNode(parentNode: nodeTree.rootNode, trim: trim, upstreamPaths: nodeTree.paths)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let roundedCorners = item as? NERoundedCorners {
        let node = NERoundedCornersNode(
          parentNode: nodeTree.rootNode,
          roundedCorners: roundedCorners,
          upstreamPaths: nodeTree.paths
        )
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
      } else if let xform = item as? NEShapeTransform {
        nodeTree.transform = xform
        continue
      } else if let group = item as? NEGroup {
        let tree = group.items.initializeNodeTree()
        let node = NEGroupNode(name: group.name, parentNode: nodeTree.rootNode, tree: tree)
        nodeTree.rootNode = node
        nodeTree.childrenNodes.append(node)
        /// Now add all child paths to current tree
        nodeTree.paths.append(contentsOf: tree.paths)
        nodeTree.renderContainers.append(node.container)
      } else if item is NERepeater {
        NELottieLogger.shared.warn("""
        The Main Thread rendering engine doesn't currently support repeaters.
        To play an animation with repeaters, you can use the Core Animation rendering engine instead.
        """)
      }

      if let pathNode = nodeTree.rootNode as? NEPathNode {
        //// Add path container to the node tree
        nodeTree.paths.append(pathNode.pathOutput)
      }

      if let renderNode = nodeTree.rootNode as? NERenderNode {
        nodeTree.renderContainers.append(NEShapeRenderLayer(renderer: renderNode.renderer))
      }
    }
    return nodeTree
  }
}
