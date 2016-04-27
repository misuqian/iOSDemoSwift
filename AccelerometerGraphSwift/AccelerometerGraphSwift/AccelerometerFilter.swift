//
//  AccelerometerFilter.swift
//  AccelerometerGraphSwift
//
//  Created by 彭芊 on 16/4/27.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit
import CoreMotion

//滤波器的父类
class AccelerometerFilter{
    var adaptive = false
    //加速计的数据
    var x = 0.0
    var y = 0.0
    var z = 0.0
    var name : String{
        return ""
    }
    
    let kAccelerometerMinStep = 0.02
    let kAccelerometerNoiseAttenuation = 3.0
    
    func addAcceleration(accel : CMAcceleration){
        x = accel.x
        y = accel.y
        z = accel.z
    }
    
    func norm(x : Double,y : Double,z : Double) -> Double{
        return sqrt(x * x + y * y + z * z)
    }
    
    func clamp(v : Double,min:Double,max:Double) -> Double{
        if v > max{
            return max
        }else if v < min{
            return min
        }else{
            return v
        }
    }
}

//Low-pass filter.维基介绍:http://en.wikipedia.org/wiki/Low-pass_filter
class LowpassFilter : AccelerometerFilter{
    var filterConstant : Double = 0.0
    override var name: String{
        return adaptive ? "Adaptive Lowpass Filter" : "Lowpass Filter";
    }
    //构造器
    init(rate:Double,cutoffFrequency freq:Double){
        super.init()
        let dt = 1.0 / rate
        let rc = 1.0 / freq
        filterConstant = dt / (dt + rc)
    }
    
    override func addAcceleration(accel: CMAcceleration) {
        var alpha = filterConstant
        if adaptive{
            let d = clamp(fabs(norm(x, y: y, z: z) - norm(accel.x, y: accel.y, z: accel.z)) / kAccelerometerMinStep - 1.0, min: 0.0, max: 1.0)
            alpha = (1.0 - d) * filterConstant / kAccelerometerNoiseAttenuation + d * filterConstant
        }
        x = alpha * accel.x + x * (1.0 - alpha)
        y = alpha * accel.y + y * (1.0 - alpha)
        z = alpha * accel.z + z * (1.0 - alpha)
    }
}

//High-pass filter.维基介绍:http://en.wikipedia.org/wiki/High-pass_filter
class HighpassFilter: AccelerometerFilter {
    var filterConstant : Double = 0.0
    var lastX = 0.0
    var lastY = 0.0
    var lastZ = 0.0
    override var name: String{
        return adaptive ? "Adaptive Highpass Filter" : "Highpass Filter"
    }
    //构造器
    init(rate:Double,cutoffFrequency freq:Double){
        super.init()
        let dt = 1.0 / rate
        let rc = 1.0 / freq
        filterConstant = dt / (dt + rc)
    }
    
    override func addAcceleration(accel: CMAcceleration) {
        var alpha = filterConstant
        if adaptive{
            let d = clamp(fabs(norm(x, y: y, z: z) - norm(accel.x, y: accel.y, z: accel.z)) / kAccelerometerMinStep - 1.0, min: 0.0, max: 1.0)
            alpha = d * filterConstant / kAccelerometerNoiseAttenuation + (1.0 - d) * filterConstant
        }
        x = alpha * (x + accel.x - lastX)
        y = alpha * (y + accel.y - lastY)
        z = alpha * (z + accel.z - lastZ)
        
        lastX = accel.x
        lastY = accel.y
        lastZ = accel.z
    }

}

