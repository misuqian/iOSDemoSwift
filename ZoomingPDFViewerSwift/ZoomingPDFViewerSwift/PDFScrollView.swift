//
//  PDFScrollView.swift
//  ZoomingPDFViewerSwift
//
//  Created by 彭芊 on 16/4/25.
//  Copyright © 2016年 彭芊. All rights reserved.
//

import UIKit

class PDFScrollView: UIScrollView,UIScrollViewDelegate{
    var pageRect : CGRect = CGRectZero
    var scaled : CGFloat = 1.0
    var page : CGPDFPageRef! = nil
    var pdfView : TiledPDFView! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initScrollView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initScrollView()
    }
    
    private func initScrollView(){
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.layer.borderWidth = 5.0
        self.minimumZoomScale = 0.25
        self.maximumZoomScale = 3.0
    }
    
    //计算缩放比例并创建TiledPDFView
    func setPDFPage(page : CGPDFPageRef){
        self.page = page
        
        self.pageRect = CGPDFPageGetBoxRect(page, CGPDFBox.MediaBox)
        self.scaled = self.frame.size.width / self.pageRect.size.width
        self.pageRect.size = CGSize(width: self.pageRect.width * self.scaled, height: self.pageRect.height*self.scaled)
        
        createPDFView(pageRect)
    }
    
    //重写layout将pdfView居中
    override func layoutSubviews() {
        super.layoutSubviews()
        let boundsSize = self.bounds.size
        var frameToCenter = self.pdfView.frame
        
        //水平居中对齐
        if frameToCenter.width < boundsSize.width{
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2.0
        }else{
            frameToCenter.origin.x = 0.0
        }
        
        //垂直居中对齐
        if frameToCenter.height < boundsSize.height{
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2.0
        }else{
            frameToCenter.origin.y = 0.0
        }
        
        self.pdfView.frame = frameToCenter
        self.pdfView.contentScaleFactor = 1.0
    }
    
    /**
     UIScrollViewDelegate
     */
    //使用ScrollView来缩放PDF
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return pdfView
    }
    
    //缩放结束后自动还原
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        if scale != 1.0{
            self.setZoomScale(1.0, animated: true)
        }
    }
    
    func createPDFView(frame : CGRect){
        let tiled = TiledPDFView(frame: frame, scaled: scaled)
        tiled.page = self.page
        self.addSubview(tiled)
        self.pdfView = tiled
    }
}

//PDF绘制层View
class TiledPDFView : UIView{
    var scaled : CGFloat = 1.0 //缩放比例
    var page : CGPDFPageRef! = nil
    
    init(frame: CGRect,scaled : CGFloat) {
        super.init(frame: frame)
        //layer设置
        let tiledLayer = self.layer as! CATiledLayer //重写layerClass才能转型成功
        tiledLayer.levelsOfDetail = 4
        tiledLayer.levelsOfDetailBias = 3
        tiledLayer.tileSize = CGSize(width: 512, height: 512)
        tiledLayer.borderColor = UIColor.lightGrayColor().CGColor
        tiledLayer.borderWidth = 5.0
        
        self.scaled = scaled
    }
    
    //重写静态方法layerClass,自定义layer类型
    override class func layerClass() -> AnyClass{
        return CATiledLayer.classForCoder()
    }
    
    //绘制CGPDF
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        //绘制白色底色
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(ctx, self.bounds)
        //page为Nil将显示底色
        if page == nil{
            return
        }
        
        CGContextSaveGState(ctx)
        //CGPDF为原本PDF倒转图像,转向并缩放大小适配
        CGContextTranslateCTM(ctx, 0.0, self.bounds.size.height)
        CGContextScaleCTM(ctx,self.scaled,-self.scaled)
        
        CGContextDrawPDFPage(ctx, self.page)
        CGContextRestoreGState(ctx)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
