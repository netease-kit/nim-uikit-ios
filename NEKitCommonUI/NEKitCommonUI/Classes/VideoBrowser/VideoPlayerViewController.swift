
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import AVFoundation
import NEKitCommon
public class VideoPlayerViewController: UIViewController {
    
    public var videoUrl: URL?
    public var totalTime: Int?
    
    public lazy var playBtn: ExpandButton = {
        let btn = ExpandButton()
        btn.isHidden = true
        btn.setImage(coreLoader.loadImage("video_play_big"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    @Atomic var isRefreshProgress: Bool = true
    
    @Atomic var isPlayingEnd: Bool = false
    
    public lazy var toolsBar: BrowserToolsBar = {
        let bar = BrowserToolsBar()
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    public lazy var successView: ToastImageView = {
        let success = ToastImageView()
        success.frame = CGRect(x: 0, y: 0, width: 118, height: 120)
        success.contentLabel.text = "已保存到系统相册"
        return success
    }()
    
    public lazy var videoToolBar: VideoToolBar = {
        let bar = VideoToolBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = .clear
        bar.delegate = self
        return bar
    }()
    
    private var dismissGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
    var avPlayer: AVPlayer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupUI()
    }
    
    func setupUI(){
        
        if let url = videoUrl {
            let palyerItem = AVPlayerItem(url: url)
            avPlayer = AVPlayer(playerItem: palyerItem)
            let playerLayer = AVPlayerLayer.init(player: avPlayer)
            playerLayer.videoGravity = .resizeAspect
            playerLayer.frame = self.view.bounds
            self.view.layer .addSublayer(playerLayer)
            //播放
            avPlayer?.play()
            
            weak var weakSelf = self
            let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { (time) in
                        // Update slider value to audio item progress.
                if weakSelf?.isRefreshProgress == false {
                    return
                }
                if let duration = weakSelf?.avPlayer?.currentItem?.duration.seconds,
                   let seekTime = weakSelf?.avPlayer?.currentTime().seconds {
                    let proress = seekTime/duration
                    DispatchQueue.main.async {
                        weakSelf?.videoToolBar.progressSlider.value = Float(proress)
                        weakSelf?.videoToolBar.currentTime.text = Date.getFormatPlayTime(seekTime)
                        if proress >= 1.0 {
                            weakSelf?.endPlay()
                        }
                    }
                    
                }
            })
        }
        
        view.backgroundColor = .black
        view.addSubview(toolsBar)
        toolsBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        toolsBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        toolsBar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        if #available(iOS 11.0, *) {
            toolsBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -27).isActive = true
        } else {
            toolsBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -27).isActive = true
        }
        
        view.addSubview(videoToolBar)
        NSLayoutConstraint.activate([
            videoToolBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoToolBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoToolBar.heightAnchor.constraint(equalToConstant: 44.0),
            videoToolBar.bottomAnchor.constraint(equalTo: toolsBar.topAnchor)
        ])
        
        if let total = totalTime {
            let time = Date.getFormatPlayTime(TimeInterval(total/1000))
            videoToolBar.totalTime.text = time
            videoToolBar.total = total
        }
        
        view.addSubview(playBtn)
        NSLayoutConstraint.activate([
            playBtn.leftAnchor.constraint(equalTo: view.leftAnchor),
            playBtn.topAnchor.constraint(equalTo: view.topAnchor),
            playBtn.rightAnchor.constraint(equalTo: view.rightAnchor),
            playBtn.bottomAnchor.constraint(equalTo: videoToolBar.topAnchor)
        ])
        playBtn.addTarget(self, action: #selector(toPlay), for: .touchUpInside)
        
        view.addGestureRecognizer(dismissGesture)
        dismissGesture.addTarget(self, action: #selector(dismissVideoToolBar))
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func toPlay(){
        if isPlayingEnd == true {
            avPlayer?.seek(to: CMTime.zero)
            isPlayingEnd = false
        }
        playBtn.isHidden = true
        avPlayer?.play()
        videoToolBar.playBtn.isSelected = false
    }
    
    @objc func dismissVideoToolBar(){
        videoToolBar.isHidden = !videoToolBar.isHidden
    }
    
}

extension VideoPlayerViewController: BrowserToolsBarDelegate, UINavigationControllerDelegate, VideoToolBarDelegate {
    
    func didClickPause() {
        
        avPlayer?.pause()
        playBtn.isHidden = false
    }
    
    func didClickPlay() {
        if isPlayingEnd == true {
            avPlayer?.seek(to: CMTime.zero)
            isPlayingEnd = false
        }
        avPlayer?.play()
        isRefreshProgress = true
        playBtn.isHidden = true
    }
    
    func didSeek(_ progress: Float) {
        if let duration = totalTime {
            let seekTime = Float(duration) * progress/1000.0
            print("seek value : ", seekTime)
            avPlayer?.seek(to: CMTime(seconds: Double(seekTime), preferredTimescale: 1))
        }
    }
    
    func didStopRefreshProgress() {
        isRefreshProgress = false
    }
    
    func didStartRefreshProgress() {
        isRefreshProgress = true
    }
    
    
    public func didCloseClick() {
        dismiss(animated: true, completion: nil)
    }
    
    public func didPhotoClick() {
        goPhotoAlbum(self, false, true)
    }
    
    public func didSaveClick() {
        
        view.makeToastActivity(.center)
        weak var weakSelf = self
        DispatchQueue.main.async {
            weakSelf?.didToSave()
        }
    }
    
    func didToSave(){
        if  videoUrl?.isFileURL == true , let path = videoUrl?.path {
            print("save  path : ", path)
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(save(path:didFinishSavingWithError:contextInfo:)), nil)
        }else {
            view.hideToastActivity()
            showToast("视频文件未保存到本地")
        }
    }
    
    public func endPlay(){
        videoToolBar.resetState()
        playBtn.isHidden = false
    }
    
    @objc func save(path:String, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
        view.hideToastActivity()
        if let error = didFinishSavingWithError {
            showToast(error.localizedDescription)
        } else {
            view.showToast(successView, point: view.center)
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        isPlayingEnd = true
    }
    
    
}
