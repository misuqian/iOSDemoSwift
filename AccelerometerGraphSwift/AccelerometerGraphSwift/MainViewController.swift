//
//  MainViewController.swift
//  AccelerometerGraphSwift
//
//  Created by 彭芊 on 16/4/26.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit
import CoreMotion

//加速计数据图像显示.加速计能够检测手机摇动
//程序主窗口.官方原版OC使用xib,这里我改用StoryBoard,使用autolayout兼容横竖屏
//UIAccelerometer在iOS5.0之后被CoreMotion.framework替代,故这个版本使用CoreMotion
class MainViewController: UIViewController{
    @IBOutlet weak var unfiltered: GraphView!
    @IBOutlet weak var filtered: GraphView!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var pause: UIBarButtonItem!
    
    var isPaused : Bool = false // 用来存储是否暂停
    var useAdaptive : Bool = false //是否开启Adaptive lowpass filter
    var filter : AccelerometerFilter!
    
    let kUpdateFrequency = 10.0
    let kLocalizedPause = NSLocalizedString("Pause",comment: "pause taking samples") //本地化.strings文件
    let kLocalizedResume = NSLocalizedString("Resume", comment: "resume taking samples")
    
    var motionManager = CMMotionManager() //这里使用CoreMotion替代官方原版的UIAcceleration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pause.possibleTitles = [kLocalizedPause,kLocalizedResume]
        
        unfiltered.isAccessibilityElement = true
        unfiltered.accessibilityLabel = NSLocalizedString("unfilteredGraph", comment: "")
        
        filtered.isAccessibilityElement = true
        filtered.accessibilityLabel = NSLocalizedString("filteredGraph", comment: "")
        
        changeFilter(true)
        //判断加速计传感器是否可用
        if motionManager.accelerometerAvailable{
            motionManager.accelerometerUpdateInterval = 1.0 / kUpdateFrequency //更新频率
            //push方式获取数值更新
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { data,error in
                if error == nil{
                    if !self.isPaused{
                        if data != nil{
                            self.filter.addAcceleration(data!.acceleration)
                            self.unfiltered.add(data!.acceleration.x, y: data!.acceleration.y, z: data!.acceleration.z)
                            self.filtered.add(data!.acceleration.x, y: data!.acceleration.y, z: data!.acceleration.z)
                        }
                    }
                }else{
                    print("error\n\(error)")
                }
            })
        }else{
            let alert = UIAlertController(title: "Fail", message: "Accelerometer is not available", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func changeFilter(isLowpass : Bool){
        if isLowpass{
            filter = LowpassFilter(rate: kUpdateFrequency, cutoffFrequency: 5.0)
        }else{
            filter = HighpassFilter(rate: kUpdateFrequency, cutoffFrequency: 5.0)
        }
        filter.adaptive = useAdaptive
        filterLabel.text = filter.name
    }
    
    @IBAction func filterSelect(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0{
            self.changeFilter(true)
        }else{
            self.changeFilter(false)
        }
    }
    
    @IBAction func adaptiveSelect(sender: UISegmentedControl) {
        useAdaptive = sender.selectedSegmentIndex == 1
        filter.adaptive = useAdaptive
        filterLabel.text = filter.name
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
    }
    
    @IBAction func pauseOrResume(sender: UIBarButtonItem) {
        if isPaused{
            isPaused = false
            pause.title = kLocalizedPause
        }else{
            isPaused = true
            pause.title = kLocalizedResume
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

