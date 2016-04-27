//
//  GraphView.swift
//  AccelerometerGraphSwift
//
//  Created by 彭芊 on 16/4/26.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit

var graphBackgroundColor : CGColorRef = deviceGrayColor(0.6, a: 1.0)
var graphLineColor : CGColorRef = deviceGrayColor(0.5, a: 1.0)
var graphXColor : CGColorRef = deviceRGBColor(1.0, g: 0.0, b: 0.0, a: 1.0)
var graphYColor : CGColorRef = deviceRGBColor(0.0, g: 1.0, b: 0.0, a: 1.0)
var graphZColor : CGColorRef = deviceRGBColor(0.0, g: 0.0, b: 1.0, a: 1.0)

func deviceGrayColor(w:CGFloat,a:CGFloat) -> CGColorRef{
    let gray = CGColorSpaceCreateDeviceGray()
    let color = CGColorCreate(gray, [w,a])
    return color!
}

func deviceRGBColor(r:CGFloat,g:CGFloat,b:CGFloat,a:CGFloat) -> CGColorRef{
    let rgb = CGColorSpaceCreateDeviceRGB()
    let color = CGColorCreate(rgb, [r,g,b,a])
    return color!
}

func drawGridLines(context : CGContextRef,x:CGFloat,width:CGFloat){
    //Swift风格的for-in循环,相当于for(CGFloat y = -48.5; y <= 48.5; y += 16.0)
    for y in (-48.5).stride(to: 48.5, by: 16.0){
        CGContextMoveToPoint(context, x, CGFloat(y))
        CGContextAddLineToPoint(context, x + width, CGFloat(y))
    }
    CGContextSetStrokeColorWithColor(context, graphLineColor)
    CGContextStrokePath(context)
}

//
class GraphViewSegment : NSObject{
    var xhistory = [Double](count: 33, repeatedValue: 0.0)
    var yhistory = [Double](count: 33, repeatedValue: 0.0)
    var zhistory = [Double](count: 33, repeatedValue: 0.0)
    var index : Int = 0 //数组索引
    //只读属性layer
    var layer : CALayer{
        get{
            return _layer
        }
    }
    private var _layer : CALayer! = nil
    
    override init(){
        super.init()
        _layer = CALayer()
        _layer.delegate = self //通过协议调用drawLayer(l:CALayer,inContext context:CGContextRef).
        _layer.bounds = CGRectMake(0.0, -56.0, 32.0, 112.0)
        _layer.opaque = true
        index = 33
    }
    
    func reset(){
        //初始化数组
        memset(&xhistory, 0, 33)
        memset(&yhistory, 0, 33)
        memset(&zhistory, 0, 33)
        index = 33
        layer.needsDisplay()
    }
    
    func isFull() -> Bool{
        return index == 0
    }
    
    func isVisibleInRect(r:CGRect) -> Bool{
        return CGRectIntersectsRect(r, _layer.frame)
    }
    
    func add(x:Double,y:Double,z:Double) -> Bool{
        if index > 0{
            index -= 1
            xhistory[index] = x
            yhistory[index] = y
            zhistory[index] = z
            _layer.setNeedsDisplay() //激活调用drawLayer(l:CALayer,inContext context:CGContextRef)
            return true
        }else{
            return false
        }
    }
    
    override func drawLayer(l:CALayer,inContext context:CGContextRef){
        //将背景填充graphBackgroundColor
        CGContextSetFillColorWithColor(context, graphBackgroundColor)
        CGContextFillRect(context, layer.bounds)
        
        drawGridLines(context, x: 0.0, width: 32.0)
        
        var lines = [CGPoint](count: 64, repeatedValue: CGPointZero)
        //设置X
        for i in 0 ..< 32 {
            lines[i*2].x = CGFloat(i)
            lines[i*2].y = CGFloat(-xhistory[i]) * 16.0
            lines[i*2 + 1].x = CGFloat(i) + 1.0
            lines[i*2 + 1].y = CGFloat(-xhistory[i+1]) * 16.0
        }
        CGContextSetStrokeColorWithColor(context, graphXColor)
        CGContextStrokeLineSegments(context, lines, 64)
        //设置Y
        for i in 0 ..< 32 {
            lines[i*2].y = CGFloat(-yhistory[i]) * 16.0
            lines[i*2 + 1].y = CGFloat(-yhistory[i+1]) * 16.0
        }
        CGContextSetStrokeColorWithColor(context, graphYColor)
        CGContextStrokeLineSegments(context, lines, 64)
        //设置Z
        for i in 0 ..< 32 {
            lines[i*2].y = CGFloat(-zhistory[i]) * 16.0
            lines[i*2 + 1].y = CGFloat(-zhistory[i+1]) * 16.0
        }
        CGContextSetStrokeColorWithColor(context, graphZColor)
        CGContextStrokeLineSegments(context, lines, 64)
    }

}

class GraphTextView : UIView{
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        //填充背景颜色
        CGContextSetFillColorWithColor(context, graphBackgroundColor)
        CGContextFillRect(context,self.bounds)
        
//        drawGridLines(context, x: 26.0, width: 6.0)
        
        let systemFont = UIFont.systemFontOfSize(12.0)
        UIColor.whiteColor().set()
        ("+3" as NSString).drawInRect(CGRectMake(2.0, 0.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("+2" as NSString).drawInRect(CGRectMake(2.0, 16.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("+1" as NSString).drawInRect(CGRectMake(2.0, 32.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("0" as NSString).drawInRect(CGRectMake(2.0,  48.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("-1" as NSString).drawInRect(CGRectMake(2.0,  64.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("-2" as NSString).drawInRect(CGRectMake(2.0,  80.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
        ("-3" as NSString).drawInRect(CGRectMake(2.0,  96.0, 24.0, 16.0), withAttributes: [NSFontAttributeName:systemFont])
    }
}


class GraphView: UIView {
    var text : GraphTextView!
    var current : GraphViewSegment!
    var segments : NSMutableArray = NSMutableArray()
    
    let kSegmentInitialPosition = CGPoint(x: 14.0, y: 56.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit(){
        text = GraphTextView(frame: CGRectMake(0.0, 0.0, 32.0, 112.0))
        self.addSubview(text)
        
        self.current = addSegment()
    }
    
    func add(x :Double,y:Double,z:Double){
        if self.current.add(x, y: y, z: z){
            self.recycleSegment()
            //造成移动的效果
            self.current.add(x, y: y, z: z)
        }
        
        for s in self.segments{
            let seg = s as! GraphViewSegment
            var position = seg.layer.position
            position.x += 1.0
            seg.layer.position = position
        }
    }
    
    func addSegment() -> GraphViewSegment{
        let segment = GraphViewSegment()
        segments.insertObject(segment, atIndex: 0)
        self.layer.insertSublayer(segment.layer, below:self.text.layer)
        segment.layer.position = kSegmentInitialPosition
        return segment
    }
    
    //删除最后一个，添加新的一个
    func recycleSegment(){
        let last = self.segments.lastObject! as! GraphViewSegment
        if last.isVisibleInRect(self.layer.bounds){
            self.current = addSegment()
        }else{
            last.reset()
            last.layer.position = kSegmentInitialPosition
            self.segments.insertObject(last, atIndex: 0)
            self.segments.removeLastObject()
            self.current = last
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        CGContextSetFillColorWithColor(context, graphBackgroundColor)
        CGContextFillRect(context, self.bounds)
        
        let width = self.bounds.size.width
        CGContextTranslateCTM(context, 0.0, 56.0)
        
        drawGridLines(context, x: 0.0, width: width)
    }
}
