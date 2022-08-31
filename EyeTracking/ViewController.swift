//
//  ViewController.swift
//  EyeTracking
//
//  Created by Ken Kuroda on 8/28/22.
//
import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MessageUI
import ARKit
import os

final class ViewController: UIViewController {
    let iroiro = myFunctions()
    var ltEyeVeloX = Array<CGFloat>()
    var faceVeloX = Array<CGFloat>()
    @IBOutlet weak var saveButton: UIButton!
    var waveBoxView:UIImageView?
    var vhitBoxView:UIImageView?
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var waveSlider: UISlider!
    var displayLinkF:Bool=false
    var displayLink:CADisplayLink?
    var faceAnchorFlag:Bool=false
    var faceX:CGFloat=0
    var ltEyeX:CGFloat=0
    var rtEyeX:CGFloat=0
    private let session = ARSession()
//    private var lookAtPointView: UIImageView = {
//         let image = UIImageView(image: .init(systemName: "eye"))
//         image.frame = .init(origin: .zero, size: CGSize(width: 30, height: 30))
//         image.contentMode = .scaleAspectFit
//         return image
//     }()
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    func drawCircle(cPoint:CGPoint,_ diameter:CGFloat,_ color:CGColor){
    
        /* --- 円を描画 --- */
        let circleLayer = CAShapeLayer.init()
        let circleFrame = CGRect.init(x:cPoint.x-diameter/2,y:cPoint.y-diameter/2,width:diameter,height:diameter)
        circleLayer.frame = circleFrame
        // 輪郭の色
        circleLayer.strokeColor = UIColor.white.cgColor
        // 円の中の色
        circleLayer.fillColor = color
        // 輪郭の太さ
        circleLayer.lineWidth = 0.5
        // 円形を描画
        circleLayer.path = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: circleFrame.size.width, height: circleFrame.size.height)).cgPath
        self.view.layer.addSublayer(circleLayer)
    }
    var initDrawOneWave:Bool=true
    func drawOneWave(){
        let endCnt = faceVeloX.count
        if endCnt<61{
            return
        }
        var startCnt = endCnt-60//点の数
       
        if startCnt<0{
            startCnt=0
        }
        //波形を時間軸で表示
        let drawImage = drawLine(startCnt:startCnt,endCnt:endCnt)
        // イメージビューに設定する
        waveBoxView = UIImageView(image: drawImage)
        if initDrawOneWave==true{
            view.addSubview(waveBoxView!)
            initDrawOneWave=false
        }else{
//            view.removeFromSuperview()
            view.addSubview(waveBoxView!)
        }
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ltEyeVeloX.removeAll()
        faceVeloX.removeAll()
        displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkUpdate))
        displayLink!.preferredFramesPerSecond = 120
//        view.addSubview(lookAtPointView)
        session.delegate = self
        displayLink?.add(to: RunLoop.main, forMode: .common)
        displayLinkF=true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    var lastRtEyeX:CGFloat=0
    var lastLtEyeX:CGFloat=0
    var lastFaceX:CGFloat=0
    var faceVeloX0:CGFloat=0
    var ltEyeVeloX0:CGFloat=0
    var rtEyeVeloX0:CGFloat=0
//    var lastFlag:Bool=true
    var initFlag:Bool=true
    @objc func displayLinkUpdate() {
        if initFlag==true{
            initFlag=false
        }else{
            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
        }
        let y0:CGFloat=view.bounds.height/4-50
        let dy:CGFloat=50

        if faceAnchorFlag==true{//} && faceAnchorFlag == lastFlag{
            faceVeloX.append(faceVeloX0)
            ltEyeVeloX.append(ltEyeVeloX0)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceVeloX0*100,y:y0),30,UIColor.red.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+ltEyeVeloX0*100,y:y0+dy),30,UIColor.red.cgColor)
        }else{//検出できていない時はappendしない
//            faceVelocityX.append(faceVeloX)
//            eyeVelocityX.append(ltEyeVeloX)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceVeloX0,y:y0),30,UIColor.brown.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+ltEyeVeloX0,y:y0+dy),30,UIColor.brown.cgColor)
        }
        if faceVeloX.count>60*60*5{//5min
            faceVeloX.remove(at: 0)
            ltEyeVeloX.remove(at: 0)
        }

        drawOneWave()
    }

    func setButtons(){
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))

        let vw=view.bounds.width
        let sp=vw/36
        let bw=vw/6
        let bh=bw*2/3
        let by=view.bounds.height-bottom-sp-bh
        myFunctions().setButtonProperty(mailButton,x:sp*1+bw*0,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(saveButton,x:sp*2+bw*1,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(clearButton,x:sp*3+bw*2,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(settingButton,x:sp*4+bw*3,y:by,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(helpButton,x:sp*5+bw*4,y:by,w:bw,h: bh,UIColor.systemBlue)
        waveSlider.frame=CGRect(x:sp,y:by-bh,width: vw-sp*2,height:20)//とりあえず
        let sliderHeight=waveSlider.frame.height
        let sliderY=by-sp*2-sliderHeight
        waveSlider.frame=CGRect(x:sp,y:sliderY,width: vw-sp*2,height:sliderHeight)
//        makeBoxies()
        waveBoxView?.frame=CGRect(x:0,y:sliderY-vw*180/320-sp*2,width:vw,height: vw*180/320)
        vhitBoxView?.frame=CGRect(x:0,y:sliderY-vw*180/320-sp*2-vw*2/5-sp*2,width :vw,height:vw*2/5)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        if #available(iOS 11.0, *) {
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            let topPadding = self.view.safeAreaInsets.top
            let bottomPadding = self.view.safeAreaInsets.bottom
//            let leftPadding = self.view.safeAreaInsets.left
//            let rightPadding = self.view.safeAreaInsets.right
//            print("in viewDidLayoutSubviews")
            UserDefaults.standard.set(topPadding, forKey: "top")
            UserDefaults.standard.set(bottomPadding, forKey: "bottom")
//            UserDefaults.standard.set(leftPadding, forKey: "left")
//            UserDefaults.standard.set(rightPadding, forKey: "right")
//            print(topPadding,bottomPadding,leftPadding,rightPadding)    // iPhoneXなら44, その他は20.0
//        }
        setButtons()
    }
}

extension ViewController: ARSessionDelegate {
     func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let faceAnchor = frame.anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else {
            return
        }
        faceAnchorFlag=faceAnchor.isTracked
          let faceXTemp=CGFloat(asin(faceAnchor.transform.columns.2.x))
         let rtEyeXTemp=CGFloat(asin(faceAnchor.rightEyeTransform.columns.2.x))
         let ltEyeXTemp=CGFloat(asin(faceAnchor.leftEyeTransform.columns.2.x))
         faceVeloX0=faceXTemp-lastFaceX
         rtEyeVeloX0=rtEyeXTemp-lastRtEyeX
         ltEyeVeloX0=ltEyeXTemp-lastLtEyeX
         lastFaceX=faceXTemp
         lastLtEyeX=ltEyeXTemp
         lastRtEyeX=rtEyeXTemp
 
//        let logger = Logger()
        //face, rightEye, leftEyeのx,y軸方向の回転角を出力
//        logger.log("fh=\(asin(faceAnchor.transform.columns.2.x))")//",fv=\(asin(faceAnchor.transform.columns.1.z))")
//        logger.log("rh=\(asin(faceAnchor.rightEyeTransform.columns.2.x))")
//        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x))")
        //",rv=\(asin(faceAnchor.rightEyeTransform.columns.1.z))")
//        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x)),lv=\(asin(faceAnchor.leftEyeTransform.columns.1.z))")
        
    }
    /*
     var timercnt:Int = 0
     var lastArraycount:Int = 0
     var elapsedTime:Double=0
     @objc func update_vog(tm: Timer) {
         timercnt += 1
         if timercnt == 1{//vogImageの背景の白、縦横線を作る
             vogImage = initVogImage(width:mailWidth*18,height:mailHeight)//枠だけ
 //            vogImageViewFlag=true
             vogCurPoint=0
         }
 //        static ela time = CFAbsoluteTimeGetCurrent() - startTime
         if calcFlag == true{
             elapsedTime=CFAbsoluteTimeGetCurrent()-startTime
         }
         currTimeLabel.text=String(format:"%.1f/%.1f",Float(eyePosXOrig.count)/videoFps,elapsedTime)
         if eyePosXFiltered.count < 5 {
             return
         }
         var calcFlagTemp=true
         if calcFlag == false {//終わったらここだが取り残しがある
             calcFlagTemp=false
         }
         let cntTemp=eyePosXOrig.count
         vogImage=addVogWave(startingImage: vogImage!, startn: lastArraycount-1, end:cntTemp)
         lastArraycount=cntTemp
 //        drawVogall_new()
         #if DEBUG
 //        print("debug-update",timercnt,calcFlagTemp)
         #endif
         //            print("veloCount:",eyeVeloOrig.count)
         drawVogOnePage(count: cntTemp)
         //ここでcalcFlagをチェックするとデータを撮り損なうか
         if calcFlagTemp == false{//timer に入るときに終わっていた
             UIApplication.shared.isIdleTimerDisabled = false//スリープする
             drawVogOnePage(count: 0)
             print("calcend")
             timer_vog!.invalidate()
             setButtons(flag: true)
         }
     }

     */
 
    /*
    func update_vHIT(tm: Timer) {
        
        arrayDataCount = getArrayData()
        if arrayDataCount < 5 {
            return
        }

        if calcFlag == false {
            vhitCurpoint=0
            //if timer?.isValid == true {
            timerCalc.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
             
            averagingData()//結局ここでスムーズになる？
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
            setWaveSlider()
        }
//        let tmpCount=getPosXFilteredCount()
        vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount, end: arrayDataCount)
        lastArraycount=arrayDataCount
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        calcDrawVHIT(tuple: true)//waveTupleは更新する。
        if calcFlag==false{
            drawOnewave(startcount: 0)
        }
    }
 
*/
    func drawLine(startCnt:Int,endCnt:Int) -> UIImage {
        let size = CGSize(width:view.bounds.width, height:view.bounds.width*18/32)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // 折れ線にする点の配列
        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()

        let pointCount:CGFloat = 60 // 点の個数
        // xの間隔
        let dx:CGFloat = view.bounds.width/pointCount
//        let gyroMovedCnt=face.count
        let y1=view.bounds.width*18/32*2/6
        let y2=view.bounds.width*18/32*4/6
        var py1:CGFloat=0
        var py2:CGFloat=0
      
        for n in startCnt-1..<endCnt{//stride(from: 1, to: pointCount, by: step){
                let px = dx * CGFloat(n-startCnt+1)
                py1 = faceVeloX[n] * 300 + y1
                py2 = ltEyeVeloX[n] * 300 + y2
                let point1 = CGPoint(x: px, y: py1)
                let point2 = CGPoint(x: px, y: py2)
                pointList1.append(point1)
                pointList2.append(point2)
//            }
        }
        print("count:",startCnt,endCnt,pointList1.count)
        // イメージ処理の開始
        // パスの初期化
        let drawPath1 = UIBezierPath()
        let drawPath2 = UIBezierPath()
        // 始点に移動する
        drawPath1.move(to: pointList1[0])
        // 配列から始点の値を取り除く
        pointList1.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList1 {
            drawPath1.addLine(to: pt)
        }
        drawPath2.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            drawPath2.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線幅
        drawPath1.lineWidth = 0.3
        drawPath2.lineWidth = 0.3
        // 線を描く
        UIColor.red.setStroke()
        drawPath1.stroke()

        UIColor.black.setStroke()
        drawPath2.stroke()
//        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",arrayDataCount,CGFloat(arrayDataCount)/240.0,videoDura[videoCurrent],timercnt+1)
//        //print(timetxt)
//        timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
//            NSAttributedString.Key.foregroundColor : UIColor.black,
//            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        
        //イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
 /*
    func makeBox(width w:CGFloat,height h:CGFloat) -> UIImage{//vHITとVOG同じ
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRect(x:0, y:0, width:w, height:h)
        let drawPath = UIBezierPath(rect:drawRect)
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        drawPath.fill()
        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawPath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func makeBoxies(){//

        let vw=view.bounds.width
//        let vh=view.bounds.height
        if waveBoxView0 == nil {
            var boxImage = makeBox(width: vw, height: vw*180/320)
            waveBoxView0 = UIImageView(image: boxImage)
            waveBoxView0!.frame=CGRect(x:0,y:20,width:vw,height: vw*180/320)
            view.addSubview(waveBoxView0!)
            boxImage = makeBox(width: vw, height: vw*2/5)
            vhitBoxView0 = UIImageView(image: boxImage)
            vhitBoxView0!.frame=CGRect(x:0,y:420,width:vw,height: vw*2/5)
            view.addSubview(vhitBoxView0!)
        }
    }*/
}
