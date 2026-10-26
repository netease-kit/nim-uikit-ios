
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import SDWebImage
import UIKit
import NEChatKit

@objcMembers
open class PhotoBrowserCell: UICollectionViewCell {
  private var didSetupUI = false
  private var imageSize = CGSize.zero
  private var imageRequestIdentifier = UUID()

  lazy var backScroll: UIScrollView = {
    let scroll =
      UIScrollView(frame: CGRect(x: 0, y: 0, width: NEConstant.screenWidth, height: NEConstant.screenHeight))
    scroll.delegate = self
    scroll.isPagingEnabled = false
    scroll.minimumZoomScale = 1.0
    scroll.maximumZoomScale = 4
    scroll.showsHorizontalScrollIndicator = false
    scroll.showsVerticalScrollIndicator = false
    return scroll
  }()

  lazy var imgView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  lazy var loading: UIActivityIndicatorView = {
    let loading = UIActivityIndicatorView()
    loading.backgroundColor = .clear
    loading.color = .white
    loading.hidesWhenStopped = true
    loading.stopAnimating()
    return loading
  }()

  var imgUrl: String? {
    didSet {
      imageRequestIdentifier = UUID()
      let requestIdentifier = imageRequestIdentifier
      imgView.sd_cancelCurrentImageLoad()
      backScroll.setZoomScale(1, animated: false)
      guard let imgUrl, !imgUrl.isEmpty else {
        loading.stopAnimating()
        imgView.image = nil
        imageSize = .zero
        return
      }

      loading.startAnimating()
      if imgUrl.hasPrefix("http") {
        let context: [SDWebImageContextOption: Any] = [.imageThumbnailPixelSize: CGSize(width: 1000, height: 1000)]
        imgView.sd_setImage(
          with: URL(string: imgUrl),
          placeholderImage: UIImage(contentsOfFile: imgUrl),
          options: .allowInvalidSSLCertificates,
          context: context,
          progress: nil
        ) { [weak self] loadedImage, _, _, _ in
          guard let self,
                self.imageRequestIdentifier == requestIdentifier,
                self.imgUrl == imgUrl else { return }
          self.loading.stopAnimating()
          guard let loadedImage else { return }
          self.imageSize = loadedImage.size
          self.resizeImage(for: loadedImage.size)
        }
      } else {
        let loadedImage = UIImage(contentsOfFile: imgUrl)
        imgView.image = loadedImage
        loading.stopAnimating()
        guard imageRequestIdentifier == requestIdentifier,
              self.imgUrl == imgUrl,
              let loadedImage else { return }
        imageSize = loadedImage.size
        resizeImage(for: loadedImage.size)
      }
    }
  }

  var image: UIImage? {
    didSet {
      imageRequestIdentifier = UUID()
      imgView.sd_cancelCurrentImageLoad()
      loading.stopAnimating()
      backScroll.setZoomScale(1, animated: false)
      guard let image else {
        imgView.image = nil
        imageSize = .zero
        return
      }
      imgView.image = image
      imageSize = image.size
      resizeImage(for: image.size)
    }
  }

  var backRemoveCallBack: (() -> Void)?
  var tapMoveCallBack: ((_ view: UIView) -> Void)?
  var changeAlphaCallBack: ((_ value: CGFloat) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    guard !didSetupUI else { return }
    didSetupUI = true
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    contentView.addSubview(backScroll)

    backScroll.addSubview(imgView)
    addTapGesture(imageview: imgView, scroll: backScroll)
    addPanGesture(imgView)

    contentView.addSubview(loading)
    loading.translatesAutoresizingMaskIntoConstraints = false
    loading.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    loading.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    loading.heightAnchor.constraint(equalToConstant: 30).isActive = true
    loading.widthAnchor.constraint(equalToConstant: 30).isActive = true
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    backScroll.frame = contentView.bounds
    if imageSize.width > 0, imageSize.height > 0 {
      resizeImage(for: imageSize)
    }
  }

  override open func prepareForReuse() {
    super.prepareForReuse()
    imageRequestIdentifier = UUID()
    imgView.sd_cancelCurrentImageLoad()
    imgUrl = nil
    image = nil
    loading.stopAnimating()
    backScroll.setZoomScale(1, animated: false)
    backScroll.contentOffset = .zero
    backScroll.contentSize = backScroll.bounds.size
    imgView.frame = .zero
    backRemoveCallBack = nil
    tapMoveCallBack = nil
    changeAlphaCallBack = nil
  }

  private func resizeImage(for size: CGSize) {
    let applyLayout = { [weak self] in
      guard let self, size.width > 0, size.height > 0 else { return }
      let viewportWidth = self.backScroll.bounds.width > 0 ? self.backScroll.bounds.width : NEConstant.screenWidth
      let viewportHeight = self.backScroll.bounds.height > 0 ? self.backScroll.bounds.height : NEConstant.screenHeight
      self.backScroll.contentOffset = .zero
      if NEAdaptiveDeviceGate.isFoldableDevice {
        // The Duo preview is presented by the app window and can be wider
        // than the source chat column. Fit the complete image into that
        // viewport while preserving its aspect ratio.
        let scale = min(viewportWidth / size.width, viewportHeight / size.height)
        let imageWidth = size.width * scale
        let imageHeight = size.height * scale
        self.backScroll.contentSize = CGSize(width: viewportWidth, height: viewportHeight)
        self.imgView.frame = CGRect(x: (viewportWidth - imageWidth) / 2,
                                    y: (viewportHeight - imageHeight) / 2,
                                    width: imageWidth, height: imageHeight)
      } else {
        let imageHeight = viewportWidth * size.height / size.width
        if imageHeight > viewportHeight {
          self.backScroll.contentSize = CGSize(width: viewportWidth, height: imageHeight)
          self.imgView.frame = CGRect(x: 0, y: 0, width: viewportWidth, height: imageHeight)
        } else {
          let originY = (viewportHeight - imageHeight) / 2
          self.backScroll.contentSize = CGSize(width: viewportWidth, height: viewportHeight)
          self.imgView.frame = CGRect(x: 0, y: originY, width: viewportWidth, height: imageHeight)
        }
      }
    }
    if Thread.isMainThread {
      applyLayout()
    } else {
      DispatchQueue.main.async(execute: applyLayout)
    }
  }
}

// MARK: UIScrollViewDelegate

extension PhotoBrowserCell: UIScrollViewDelegate {
  // 当scrollview 尝试进行缩放的时候
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imgView
  }

  // 当缩放完毕的时候调用
  public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?,
                                      atScale scale: CGFloat) {}

  // 将要开始缩放
  public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {}

  // 当正在缩放的时候
  public func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        获取到这个scrollview
    var centerX = backScroll.center.x
    var centerY = backScroll.center.y
    centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView
      .contentSize.width / 2 : centerX
    centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView
      .contentSize.height / 2 : centerY
    imgView.center = CGPoint(x: centerX, y: centerY)
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}

// MARK: 点击的方法

extension PhotoBrowserCell {
  @objc func imageClick(tap: UITapGestureRecognizer) {
    var newscale: CGFloat = 0

    guard let scroll = tap.view?.superview as? UIScrollView else {
      return
    }

    if scroll.zoomScale == 1.0 {
      newscale = 3
    } else {
      newscale = 1.0
    }

    let zoomRect = zoomRectForScale(
      scrollview: scroll,
      scale: newscale,
      center: tap.location(in: tap.view)
    )

    scroll.zoom(to: zoomRect, animated: true)
  }

  @objc func viewClick(tap: UITapGestureRecognizer) {
    if backScroll.zoomScale != 1 {
      let zoomRect = zoomRectForScale(scrollview: backScroll, scale: 1, center: center)
      backScroll.zoom(to: zoomRect, animated: true)
    } else {
      if tap.state == .recognized {
        tapMoveCallBack?(imgView)
      }
    }
  }

  func zoomRectForScale(scrollview: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
    var zoomRect = CGRect()
    zoomRect.size.height = scrollview.frame.size.height / scale
    zoomRect.size.width = scrollview.frame.size.width / scale
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
    return zoomRect
  }
}

// MARK: 添加手势

extension PhotoBrowserCell: UIGestureRecognizerDelegate {
  // 点击手势
  func addTapGesture(imageview: UIView, scroll: UIScrollView) {
    imageview.isUserInteractionEnabled = true
    scroll.isUserInteractionEnabled = true
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(imageClick(tap:)))
    doubleTap.numberOfTapsRequired = 2
    imageview.addGestureRecognizer(doubleTap)

    let tap = UITapGestureRecognizer(target: self, action: #selector(viewClick(tap:)))
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1
    imageview.addGestureRecognizer(tap)
    scroll.addGestureRecognizer(tap)

    tap.require(toFail: doubleTap)
  }

  // 拖动手势
  func addPanGesture(_ imgView: UIView) {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panRecognizerAction(pan:)))
    imgView.addGestureRecognizer(pan)
    imgView.isUserInteractionEnabled = true
    pan.delegate = self
  }

  @objc func panRecognizerAction(pan: UIPanGestureRecognizer) {
    guard let imageview = pan.view else {
      return
    }
    guard let imgSuperView = imageview.superview else {
      return
    }
    let translation = pan.translation(in: imageview)
    if pan.state == .changed {
      imageview.center = CGPoint(x: imageview.center.x, y: imageview.center.y + translation.y)
      pan.setTranslation(.zero, in: imgSuperView)
      // 滑动时改变背景透明度

      let alphaScale = abs(imageview.center.y - NEConstant.screenHeight / 2)
//            self.backView.backgroundColor = UIColor.black.withAlphaComponent((kScreenHeight - CGFloat(alphaScale)) / kScreenHeight)
      changeAlphaCallBack?((NEConstant.screenHeight - CGFloat(alphaScale)) / NEConstant.screenHeight)
    } else if pan.state == .ended {
      // 如果偏移量大于某个值，直接划走消失，否则回归原位
      if imageview.center.y > NEConstant.screenHeight / 2 + 60 {
        imagePanRemoveAnimation(false, imageview: imageview)
      } else if imageview.center.y < NEConstant.screenHeight / 2 - 60 {
        imagePanRemoveAnimation(true, imageview: imageview)
      } else {
        // 回复原位
        let imgW = NEConstant.screenWidth
        let imgH = NEConstant.screenWidth * (imageview.frame.size.height) /
          (imageview.frame.size.width)
        let y = (NEConstant.screenHeight - imgH) / 2
        UIView.animate(withDuration: 0.3) {
          // 背景色不透明
          self.changeAlphaCallBack?(1)
          imageview.frame = CGRect(x: 0, y: y, width: imgW, height: imgH)
        }
      }
    }
  }

  // 只允许上下起作用
  override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer)
    -> Bool {
    guard let panView = gestureRecognizer.view else {
      return false
    }
    // 正在缩放的view，不支持手势
    guard panView.frame.size.width == NEConstant.screenWidth else {
      return false
    }
    // 长图不支持
    guard panView.frame.size.height <= NEConstant.screenHeight else {
      return false
    }
    if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
      let panGesture = gestureRecognizer as! UIPanGestureRecognizer
      let offset = panGesture.translation(in: panView)
      if offset.x == 0, offset.y != 0 {
        return true
      }
    }

    return false
  }

  func imagePanRemoveAnimation(_ isTop: Bool, imageview: UIView) {
    let duration = 0.4
    if isTop {
      // 向上划走消失
      let imgW = NEConstant.screenWidth
      let imgH = NEConstant.screenWidth * (imageview.frame.size.height) / (imageview.frame.size.width)

      UIView.animate(withDuration: duration) {
        imageview.frame = CGRect(x: 0, y: -imgH, width: imgW, height: imgH)
      }

      backRemoveCallBack?()
    } else {
      // 向下划走消失
      let imgW = NEConstant.screenWidth
      let imgH = NEConstant.screenWidth * (imageview.frame.size.height) / (imageview.frame.size.width)

      UIView.animate(withDuration: duration) {
        imageview.frame = CGRect(x: 0, y: NEConstant.screenHeight, width: imgW, height: imgH)
      }

      backRemoveCallBack?()
    }
  }
}
