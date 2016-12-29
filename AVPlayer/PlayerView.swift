//
//  PlayerView.swift
//  AVPlayer
//
//  Created by wangyuan on 2016/11/17.
//  Copyright © 2016年 WY. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

public class PlayerView: UIView {
    
    private enum GestureDirection{
        case LeftOrRight,UpOrDown,None
    }
    private enum Direction:Int{
        case Left = 0
        case Right
    }
    private var player:AVPlayer!
    private var playerLayer:AVPlayerLayer!
    private var playerItem:AVPlayerItem!
    private var activity:UIActivityIndicatorView!
    private var isFullScreen = false
    private var disappearTimer:Timer!
    private var customFrame:CGRect!
    private var backView:UIView!
    private var topView:UIView!
    private var bottomView:UIView!
    private var startBtn:UIButton!
    private var progress:UIProgressView!
    private var slider:UISlider!
    private var currentTimeLabel:UILabel!
    private var volumeSlider:UISlider!
    private var startMove = false

    private var playerVolume:CGFloat! //音量
    private var playerBrightness:CGFloat! //亮度
    private var currentVideoSeconds:Double!
    private var gestureControlDirection = GestureDirection.None
    private var startPoint:CGPoint!
    private var currentBrightness:CGFloat!
    public var back:(() -> ())!
    public var endPlay:(() -> ())!
    public var playerTimer:Timer!
    public var url:URL!{
        didSet{
            
            playerItem = AVPlayerItem.init(url: url)
            player = AVPlayer.init(playerItem: playerItem)
            playerLayer = AVPlayerLayer.init(player: player)
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            playerLayer.videoGravity = AVLayerVideoGravityResize
            self.layer.addSublayer(playerLayer)
            
            activity = UIActivityIndicatorView.init(activityIndicatorStyle: .white)
            activity.center = self.center
            activity.startAnimating()
            self.addSubview(activity)
            
            self.originalScreen()
            
            //AVPlayer播放完成通知
            playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
    }
    
    public var isLandscape = false
    
    public var repeatPlay = false
    
    public var autoFullScreen = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customFrame = frame
        currentBrightness = UIScreen.main.brightness
        getVolumeSlider()
        
        self.backgroundColor = UIColor.black
        //屏幕方向改变通知
        NotificationCenter.default.addObserver(self, selector: #selector(orientChange(notification:)), name: Notification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
        //程序即将进入后台通知
        NotificationCenter.default.addObserver(self, selector: #selector(appwillResignActive(notification:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        //程序即将进入前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground(notification:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func originalScreen(){
        UIDevice.current.setValue(NSNumber.init(value: UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        
        isFullScreen = false
        if disappearTimer != nil && disappearTimer.isValid {
            disappearTimer.invalidate()
        }
        self.setStatusBarHidden(hidden: false)
        UIView.animate(withDuration: 0.25) {
            self.transform = CGAffineTransform(rotationAngle: 0)
        }
        
        self.frame = customFrame
        playerLayer.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        for subView in self.subviews {
            subView.removeFromSuperview()
        }
        
        self.createUI()
    }
    
    func getVolumeSlider(){
        
        let volume = MPVolumeView.init()
        volume.sizeToFit()
        for v in volume.subviews{
            if v.classForCoder == NSClassFromString("MPVolumeSlider") {
                volumeSlider = v as! UISlider
            }
        }
    }
    
    func createUI(){
        
        backView = UIView.init(frame: CGRect(x: 0, y: playerLayer.frame.origin.y, width: playerLayer.frame.width, height: playerLayer.frame.height))
        backView.backgroundColor = UIColor.clear
        self.addSubview(backView)
        
        topView = UIView.init(frame: CGRect(x: 0, y: 0, width: backView.frame.width, height: 40))
        topView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        backView.addSubview(topView)
        
        bottomView = UIView.init(frame: CGRect(x: 0, y: backView.frame.height - 40, width: backView.frame.width, height: 40))
        bottomView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        backView.addSubview(bottomView)
        
        //创建播放按钮
        self.createPlayBtn()
        //创建进度条
        self.createProgress()
        //创建播放条
        self.createSlider()
        //创建时间Label
        self.createCurrentTimeLabel()
        //创建返回按钮
        self.createBackBtn()
        //创建全屏按钮
        self.createFullScreenBtn()
        //创建点击手势
        self.createGesture()
        
        if playerTimer != nil && playerTimer.isValid {
            playerTimer.invalidate()
        }else{
            playerTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeStack), userInfo: nil, repeats: true)
        }
        if disappearTimer != nil && disappearTimer.isValid {
            disappearTimer.invalidate()
        }else{
            disappearTimer = Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(disappear), userInfo: nil, repeats: false)
        }
    }
    
    func createPlayBtn(){
        startBtn = UIButton.init(type: .custom)
        startBtn.frame = CGRect(x: 10, y: 0, width: 30, height: 30)
        startBtn.center.y = bottomView.frame.height / 2
        startBtn.setBackgroundImage(UIImage.init(named: "pauseBtn"), for: .selected)
        startBtn.setBackgroundImage(UIImage.init(named: "playBtn"), for: .normal)
        bottomView.addSubview(startBtn)
        
        if player.rate == 1.0 {
            
            startBtn.isSelected = true
            
        }else{
            
            startBtn.isSelected = false
        }
        
        startBtn.addTarget(self, action: #selector(startAction(btn:)), for: .touchUpInside)
        
    }
    
    func createProgress(){
        
        var width:CGFloat!
        if isLandscape {
            
            width = self.frame.size.width
            
        }else{
            
            if isFullScreen == false{
                
                width = self.frame.size.width
                
            }else{
                
                width = self.frame.size.height
                
            }
        }
        
        let startBtnRight = startBtn.frame.origin.x + startBtn.frame.width
        progress = UIProgressView.init(frame: CGRect(x: startBtnRight + 10, y: 0, width: width - 80 - 10 - startBtnRight - 10 - 10, height: 10))
        progress.center.y = bottomView.frame.height / 2.0
        progress.trackTintColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        
        let timeInterval = self.availableDuration()
        let duration = playerItem.duration
        let totalDuration = duration.seconds
        let progressNum = timeInterval / totalDuration
        progress.setProgress(Float(progressNum), animated: false)
        
        if timeInterval == totalDuration {
            
            progress.progressTintColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
        }else{
            
            progress.progressTintColor = UIColor.clear
        }
        bottomView.addSubview(progress)
    }
    
    func createSlider(){
        
        slider = UISlider.init(frame: CGRect(x: progress.frame.origin.x - 2, y: 0, width: progress.frame.width + 3, height: 40))
        slider.center.y = bottomView.frame.height / 2.0
        bottomView.addSubview(slider)
        
        let image = UIImage.init(named: "round")
        let newImage = UIImage.originImage(image: image!, scaleToSize: CGSize(width: 20, height: 20))
        slider.setThumbImage(newImage, for: .normal)
        
        slider.addTarget(self, action: #selector(processSliderStartDragAction(slider:)), for: .touchDown)
        
        slider.addTarget(self, action: #selector(sliderValueChangedAction(slider:)), for: .valueChanged)
        
        slider.addTarget(self, action: #selector(processSliderEndDragAction(slider:)), for: .touchUpOutside)
        
        slider.minimumTrackTintColor = UIColor.red
        slider.maximumTrackTintColor = UIColor.clear
    }
    
    func createCurrentTimeLabel(){
        
        currentTimeLabel = UILabel.init()
        currentTimeLabel.center.y = progress.center.y
        currentTimeLabel.frame.origin.x = progress.frame.origin.x + progress.frame.width + 10
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12)
        currentTimeLabel.text = "00:00/00:00"
        currentTimeLabel.sizeToFit()
        bottomView.addSubview(currentTimeLabel)
    }
    
    func createBackBtn(){
        
        let btn = UIButton.init(type: .custom)
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.center.y = topView.center.y
        btn.setBackgroundImage(UIImage.init(named: "backBtn")?.imageWithTintColor(tintColor: UIColor.white), for: .normal)
        topView.addSubview(btn)
        
        btn.addTarget(self, action: #selector(backButtonAction(btn:)), for: .touchUpInside)
    }
    
    func createFullScreenBtn(){
        let btn = UIButton.init(type: .custom)
        btn.frame = CGRect(x: topView.frame.origin.x + topView.frame.width - 10 - 30, y: 0, width: 30, height: 30)
        btn.center.y = topView.center.y
        topView.addSubview(btn)
        
        if isFullScreen {
            
            btn.setBackgroundImage(UIImage.init(named: "minBtn"), for: .normal)
            
        }else{
            
            btn.setBackgroundImage(UIImage.init(named: "maxBtn"), for: .normal)
        }
        btn.addTarget(self, action: #selector(fullScreenButtonAction(btn:)), for: .touchUpInside)
    }
    
    func createGesture(){
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction(tap:)))
        self.addGestureRecognizer(tap)
    }
    
    func tapAction(tap:UITapGestureRecognizer){
        disappearTimer.invalidate()
        if backView.alpha == 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.backView.alpha = 0
            })
        }else if backView.alpha == 0{
            disappearTimer = Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(disappear), userInfo: nil, repeats: false)
            UIView.animate(withDuration: 0.5, animations: {
                self.backView.alpha = 1.0
            })
        }
    }
    
    func startAction(btn:UIButton){
        
        if btn.isSelected {
            
            self.pausePlay()
            
        }else{
            
            self.playVideo()
        }
        
    }
    
    func backButtonAction(btn:UIButton){
        
        if back != nil {
            back()
        }
    }
    
    func fullScreenButtonAction(btn:UIButton){
        
        let currentIsLandscape = isLandscape
        isLandscape = false
        if isFullScreen == false {
            
            self.fullScreenWithDirection(direction: Direction.Left)
            
        }else{
            self.originalScreen()
        }
        isLandscape = currentIsLandscape
    }
    
    func pausePlay(){
        
        startBtn.isSelected = false
        player.pause()
    }
    
    func playVideo(){
        startBtn.isSelected = true
        player.play()
    }
    
    func processSliderStartDragAction(slider:UISlider){
        
        self.pausePlay()
        disappearTimer.invalidate()
    }
    
    func sliderValueChangedAction(slider:UISlider){
        
        let total = Float(playerItem.duration.seconds)
        let dragedSeconds = Int(total * slider.value)
        let dragedCMTime = CMTime(value: CMTimeValue(dragedSeconds), timescale: CMTimeScale(1.0))
        player.seek(to: dragedCMTime)
    }
    
    func processSliderEndDragAction(slider:UISlider){
        
        self.playVideo()
        disappearTimer.invalidate()
        disappearTimer = Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(disappear), userInfo: nil, repeats: false)
       
    }
    
    func availableDuration() -> Double{
        let loadedTimeRanges = player.currentItem?.loadedTimeRanges
        if loadedTimeRanges != nil && loadedTimeRanges!.count > 0 {
            let timeRange = loadedTimeRanges?.first?.timeRangeValue
            let startSeconds = (timeRange?.start)!.seconds
            let durationSeconds = (timeRange?.duration)!.seconds
            let result = startSeconds + durationSeconds
            return result

        }else{
            return 0
        }
    }
    
    private func fullScreenWithDirection(direction:Direction){
        
        isFullScreen = true
        
        disappearTimer.invalidate()
        self.setStatusBarHidden(hidden: true)
        
        if isLandscape == true {
            
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            playerLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }else{

            if direction == Direction.Left {
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI) / 2.0)
                })
            }else{
                UIView.animate(withDuration: 0.25, animations: {
                    self.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI) / 2.0)
                })
            }
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            playerLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
        }
        for subView in self.subviews {
            
            subView.removeFromSuperview()
        }
        self.createUI()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "loadedTimeRanges" {
            
            let timeInterval = self.availableDuration()
            let duration = playerItem.duration
            let totalDuration = duration.seconds
            let progressNum = timeInterval / totalDuration
            progress.setProgress(Float(progressNum), animated: false)
            
            progress.progressTintColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    func timeStack(){
        
        if playerItem.duration.timescale != 0 {
            
            slider.maximumValue = 1.0
            slider.value = Float(playerItem.currentTime().seconds) / Float(playerItem.duration.seconds)
            let proMin = Int(playerItem.currentTime().seconds / 60)
            let proSec = Int(playerItem.currentTime().seconds) % 60
            
            let durMin = Int(playerItem.duration.seconds) / 60
            let durSec = Int(playerItem.duration.seconds) % 60
            
            self.currentTimeLabel.text = String.init(format: "%02d:%02d / %02d:%02d", proMin,proSec,durMin,durSec)
            self.currentTimeLabel.sizeToFit()
            currentTimeLabel.center.y = progress.center.y
        }
        if player.status == AVPlayerStatus.readyToPlay {
            
            activity.stopAnimating()
        }else{
            activity.startAnimating()
        }
    }
    
    func disappear(){
        
        UIView.animate(withDuration: 0.5, animations: {
            self.backView.alpha = 0
        })

    }
    
    /// 播放结束接收通知的函数
    ///
    /// - Parameter notification: notification
    func moviePlayDidEnd(notification:Notification){
        
        if repeatPlay == false {
            
            self.pausePlay()
        }else{
            self.resetPlay()
        }
        if endPlay != nil {
            
            endPlay()
        }
    }
    
    
    func resetPlay(){
        player.seek(to: CMTime(value: 0, timescale: 1))
        self.playVideo()
    }
    
    func stopPlay(){
        self.pausePlay()
        playerTimer.invalidate()
        disappearTimer.invalidate()
        
    }
    
    func setStatusBarHidden(hidden:Bool){
        
        let application = UIApplication.shared
        application.isStatusBarHidden = hidden
    }
    
    func orientChange(notification:Notification){
        
       
        if autoFullScreen == false {
            
            return
        }
        let orientation = UIDevice.current.orientation
     
        if orientation == UIDeviceOrientation.landscapeLeft {
           
            self.fullScreenWithDirection(direction: Direction.Left)
            
        }else if orientation == UIDeviceOrientation.landscapeRight{
           
            self.fullScreenWithDirection(direction: Direction.Right)
        }else if orientation == UIDeviceOrientation.portrait{
            
            self.originalScreen()
        }
    }
    
    func appWillEnterForeground(notification:Notification){
        UIScreen.main.brightness = playerBrightness
    }
    
    func appwillResignActive(notification:Notification){
        
        UIScreen.main.brightness = currentBrightness
        self.pausePlay()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startPoint = touches.first?.location(in: self)

        if startPoint.x < self.frame.width / 2 {
            //控制亮度
            self.playerBrightness = UIScreen.main.brightness
        }else{
            //控制音量
            self.playerVolume = CGFloat(self.volumeSlider.value)
        }
        self.gestureControlDirection = GestureDirection.None
        
        self.currentVideoSeconds = playerItem.currentTime().seconds
        self.startMove = true
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let endPoint = touches.first?.location(in: self)
        let panPoint = CGPoint(x: endPoint!.x - startPoint.x, y: endPoint!.y - startPoint!.y)
        if self.gestureControlDirection == GestureDirection.None {
            //分析用户手势滑动方向
            if panPoint.x >= 30 || panPoint.x <= -30 {
                //进度
                self.gestureControlDirection = GestureDirection.LeftOrRight
            }else if panPoint.y >= 30 || panPoint.y <= -30{
                //音量或者亮度
                self.gestureControlDirection = GestureDirection.UpOrDown
            }
        }
        if self.gestureControlDirection == GestureDirection.None {
            return
        }else if self.gestureControlDirection == GestureDirection.UpOrDown{
            //音量或者亮度
            if startPoint.x < self.frame.width / 2 {
                //调节亮度
                if panPoint.y < 0 {
                    //增加亮度
                    UIScreen.main.brightness = self.playerBrightness + (-panPoint.y / 30.0 / 10.0)
                }else{
                    //减少亮度
                    UIScreen.main.brightness = self.playerBrightness - (panPoint.y / 30.0 / 10.0)
                }
                
            }else{
                //调节音量
                if panPoint.y < 0 {
                    //增加音量
                    self.volumeSlider.setValue(Float(self.playerVolume + (-panPoint.y / 30.0 / 10.0)), animated: true)
                    
                    if (Float(self.playerVolume + (-panPoint.y / 30.0 / 10.0)) - self.volumeSlider.value) >= 0.1{
                        self.volumeSlider.setValue(0.1, animated: false)
                        self.volumeSlider.setValue(Float(self.playerVolume + (-panPoint.y / 30.0 / 10.0)), animated: true)
                    }
                    
                }else{
                    //减少音量
                    self.volumeSlider.setValue(Float(self.playerVolume - (panPoint.y / 30.0 / 10.0)), animated: true)
                }
            }
        }else if self.gestureControlDirection == GestureDirection.LeftOrRight{
            //控制进度
            if self.startMove {
                
                if panPoint.x > 0{
                    //快进10s
                    self.currentVideoSeconds = self.currentVideoSeconds + 10.0
                }else{
                    //后退10s
                    self.currentVideoSeconds = self.currentVideoSeconds - 10.0
                }
                let total = playerItem.duration.seconds
                if self.currentVideoSeconds > total{
                    self.currentVideoSeconds = playerItem.duration.seconds
                }else if self.currentVideoSeconds < 0{
                    self.currentVideoSeconds = 0
                }
                self.startMove = false
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if self.gestureControlDirection == GestureDirection.LeftOrRight {
            let total = Float(playerItem.duration.seconds)
            let dragedCMTime = CMTime(value: CMTimeValue(self.currentVideoSeconds), timescale: CMTimeScale(1.0))
            player.seek(to: dragedCMTime)
            slider.value = Float(self.currentVideoSeconds) / total
        }
    }
    
    deinit {
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        NotificationCenter.default.removeObserver(self)
    }
}
