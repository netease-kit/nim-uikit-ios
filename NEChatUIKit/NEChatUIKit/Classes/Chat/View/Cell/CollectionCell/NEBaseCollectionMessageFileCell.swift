//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open
class NEBaseCollectionMessageFileCell: NEBaseCollectionMessageCell {
  /// 文件下载状态
  public lazy var fileStateView: FileStateView = {
    let stateView = FileStateView()
    stateView.translatesAutoresizingMaskIntoConstraints = false
    stateView.backgroundColor = .clear
    return stateView
  }()

  /// 气泡图片
  public var bubbleImage = UIImageView()

  public lazy var imgView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.backgroundColor = .clear
    return imageView
  }()

  /// 标题
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = false
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingMiddle
    label.font = DefaultTextFont(14)
    label.textAlignment = .left
    return label
  }()

  /// 文件大小
  public lazy var sizeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "#999999")
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .left
    return label
  }()

  public lazy var labelView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor),
      titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: 18),
    ])
    view.addSubview(sizeLabel)
    NSLayoutConstraint.activate([
      sizeLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      sizeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
      sizeLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      sizeLabel.heightAnchor.constraint(equalToConstant: 10),
    ])
    return view
  }()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// 初始化的生命周期
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  /// 反序列化支持回调
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupCommonUI() {
    super.setupCommonUI()
    bubbleImage.image = nil
    bubbleImage.layer.cornerRadius = 8
    bubbleImage.layer.borderColor = UIColor.ne_borderColor.cgColor
    bubbleImage.layer.borderWidth = 1
    bubbleImage.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.isUserInteractionEnabled = true
    backView.addSubview(bubbleImage)
    contentWidth = bubbleImage.widthAnchor.constraint(equalToConstant: chat_content_maxW)
    contentHeight = bubbleImage.heightAnchor.constraint(equalToConstant: chat_content_maxW)
    NSLayoutConstraint.activate([
      contentHeight!,
      contentWidth!,
      bubbleImage.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      bubbleImage.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -12),
    ])

    bubbleImage.addSubview(imgView)
    NSLayoutConstraint.activate([
      imgView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 10),
      imgView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      imgView.widthAnchor.constraint(equalToConstant: 32),
      imgView.heightAnchor.constraint(equalToConstant: 32),
    ])

    bubbleImage.addSubview(labelView)
    NSLayoutConstraint.activate([
      labelView.leftAnchor.constraint(equalTo: imgView.rightAnchor, constant: 15),
      labelView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      labelView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -10),
      labelView.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])

    bubbleImage.addSubview(fileStateView)
    NSLayoutConstraint.activate([
      fileStateView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 10),
      fileStateView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 10),
      fileStateView.widthAnchor.constraint(equalToConstant: 32),
      fileStateView.heightAnchor.constraint(equalToConstant: 32),
    ])

    if let gesture = contentGesture {
      bubbleImage.addGestureRecognizer(gesture)
    }
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let fileObject = model.message?.attachment as? V2NIMMessageFileAttachment {
      if let fileModel = model.fileModel {
        fileModel.cell = self
        if fileModel.state == .Success {
          fileStateView.state = .FileOpen
        } else {
          fileStateView.state = .FileDownload
          fileStateView.setProgress(Float(fileModel.progress))
          if fileModel.progress >= 100 {
            fileModel.state = .Success
          }
        }
      }
      var fileName = "file_unknown"
      let suffix = (fileObject.name as NSString).pathExtension.lowercased()
      switch suffix {
      case file_doc_support:
        fileName = "file_doc"
      case file_xls_support:
        fileName = "file_xls"
      case file_img_support:
        fileName = "file_img"
      case file_ppt_support:
        fileName = "file_ppt"
      case file_txt_support:
        fileName = "file_txt"
      case file_audio_support:
        fileName = "file_audio"
      case file_vedio_support:
        fileName = "file_vedio"
      case file_zip_support:
        fileName = "file_zip"
      case file_pdf_support:
        fileName = "file_pdf"
      case file_html_support:
        fileName = "file_html"
      case "key", "keynote":
        fileName = "file_keynote"
      default:
        fileName = "file_unknown"
      }

      imgView.image = UIImage.ne_imageNamed(name: fileName)
      titleLabel.text = fileObject.name

      let size_B = Double(fileObject.size)
      var size_str = String(format: "%.1f B", size_B)
      if size_B > 1e3 {
        let size_KB = size_B / 1e3
        size_str = String(format: "%.1f KB", size_KB)
        if size_KB > 1e3 {
          let size_MB = size_KB / 1e3
          size_str = String(format: "%.1f MB", size_MB)
          if size_MB > 1e3 {
            let size_GB = size_KB / 1e6
            size_str = String(format: "%.1f GB", size_GB)
          }
        }
      }
      sizeLabel.text = size_str
    }
  }

  /// 更新下载进度
  /// - Parameter progress: 进度比率
  open func uploadProgress(_ progress: UInt) {
    fileStateView.setProgress(Float(progress))
  }
}
