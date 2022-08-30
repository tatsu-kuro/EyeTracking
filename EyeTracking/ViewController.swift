//
//  ViewController.swift
//  EyeTracking
//
//  Created by Ken Kuroda on 8/28/22.
//

import UIKit
import ARKit
import os

final class ViewController: UIViewController {
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var vhitBoxView: UIImageView!
    @IBOutlet weak var waveBoxView: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var waveSlider: UISlider!
    var displayLinkF:Bool=false
    var displayLink:CADisplayLink?
    var faceAnchorFlag:Bool=false
    var faceHorizon:CGFloat=0
    var leftEyeHorizon:CGFloat=0
    var rightEyeHorizon:CGFloat=0
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
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLink = CADisplayLink(target: self, selector: #selector(self.update))
        displayLink!.preferredFramesPerSecond = 120
        drawCircle(cPoint:CGPoint(x:view.bounds.width/2,y:view.bounds.height/2),10,UIColor.red.cgColor)
        drawCircle(cPoint:CGPoint(x:view.bounds.width/2,y:view.bounds.height/2),10,UIColor.red.cgColor)
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
    @objc func update() {//pursuit
        view.layer.sublayers?.removeLast()
        view.layer.sublayers?.removeLast()
        let y0=view.bounds.height/4-50
        let dy:CGFloat=50
        if faceAnchorFlag==true{
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceHorizon,y:y0),30,UIColor.red.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+leftEyeHorizon,y:y0+dy),30,UIColor.red.cgColor)
        }else{
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceHorizon,y:y0),30,UIColor.brown.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+leftEyeHorizon,y:y0+dy),30,UIColor.brown.cgColor)
        }
    }
    let iroiro = myFunctions()

    func setButtons(){
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))

        let vw=view.bounds.width
        let sp=vw/36
        let bw=vw/6
        let bh=bw/2
        let by=view.bounds.height-bottom-sp-bh
        let sliderHeight:CGFloat=20
        let sliderY=by-sp*2-sliderHeight
//        UserDefaults.standard.set(sliderY, forKey: "sliderY")
 
//        var bw=(ww-30)/4*//vhit,camera,vogのボタンの幅
//        let distance:CGFloat=4//最下段のボタンとボタンの距離
        
//        let bh:CGFloat=(ww-20-6*distance)/7//最下段のボタンの高さ、幅と同じ
//        let bh1=bottomY-5-bh-bh//2段目
//        let bh2=bottomY-10-2.9*bh//videoSlider
//        backButton.layer.cornerRadius = 5
//        nextButton.layer.cornerRadius = 5
//        videoSlider.frame = CGRect(x: 10, y:bh2, width: ww - 20, height: bh)
//        videoSlider.thumbTintColor=UIColor.systemYellow
//        waveSlider.frame = CGRect(x: 10, y:bh2, width: ww - 20, height: bh)
//        waveSlider.thumbTintColor=UIColor.systemBlue
//        bw=bh//bhは冒頭で決めている。上２段のボタンの高さと同じ。
//        let bwd=bw+distance
//        let bh0=bottomY-bh//wh-10-bw/2
        iroiro.setButtonProperty(mailButton,x:sp*1+bw*0,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(saveButton,x:sp*2+bw*1,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(clearButton,x:sp*3+bw*2,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(settingButton,x:sp*4+bw*3,y:by,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(helpButton,x:sp*5+bw*4,y:by,w:bw,h: bh,UIColor.systemBlue)
        waveSlider.frame=CGRect(x:sp,y:sliderY,width: vw-sp*2,height:20)
        waveBoxView.frame=CGRect(x:0,y:sliderY-vw*180/320-sp*2,width:vw,height: vw*180/320)
        vhitBoxView.frame=CGRect(x:0,y:sliderY-vw*180/320-sp*2-vw*2/5-sp*2,width :vw,height:vw*2/5)
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
//            faceAnchorFlag=false
            return
        }
        faceAnchorFlag=faceAnchor.isTracked
        //faceの向きだけからlookingPointを出している。
//        let lookingPoint = frame.camera.projectPoint(faceAnchor.lookAtPoint,
//                                                     orientation: .portrait,
//                                                     viewportSize: view.bounds.size)
//        DispatchQueue.main.async {
//            self.lookAtPointView.center = lookingPoint
//        }
        faceHorizon=CGFloat(asin(faceAnchor.transform.columns.2.x))*100
        rightEyeHorizon=CGFloat(asin(faceAnchor.rightEyeTransform.columns.2.x))*100
        leftEyeHorizon=CGFloat(asin(faceAnchor.leftEyeTransform.columns.2.x))*100

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
    func onCalcButton(_ sender: Any) {
        if zoomNum != 1{
            return
        }
        var debugMode:Bool=true
        let backCameraFps=album.getUserDefaultFloat(str: "backCameraFps", ret:240.0)
        if  UserDefaults.standard.integer(forKey: "showRect") == 0{
            debugMode=false
        }
        if debugMode==false{
            debugFaceWaku_image.isHidden=true
            debugEyeWaku_imge.isHidden=true
        }else{
            debugEyeWaku_imge.isHidden=false
            if faceMark==false{
                debugFaceWaku_image.isHidden=true
//                debugFace.isHidden=true
            }else{
                debugFaceWaku_image.isHidden=false
//                debugFace.isHidden=false
            }
        }
        seekBar.isHidden=true
        if calcFlag == true{
            calcFlag=false
            setButtons(flag: true)
            UIApplication.shared.isIdleTimerDisabled = false//sleepする
            return
        }
//        var cvError:Int = 0
        startTime=CFAbsoluteTimeGetCurrent()
        setButtons(flag: false)
        setUserDefaults()//eyeCenter,faceCenter
        lastArraycount=0
        calcFlag = true
        eyePosXOrig.removeAll()
        eyePosXFiltered.removeAll()
        eyePosYOrig.removeAll()
        eyePosYFiltered.removeAll()
        eyeVeloXFiltered.removeAll()
        eyeVeloYFiltered.removeAll()
  
        eyePosXOrig.append(0)
        eyePosXFiltered.append(0)
        eyePosYOrig.append(0)
        eyePosYFiltered.append(0)
        eyeVeloXFiltered.append(0)
        eyeVeloYFiltered.append(0)
        
        KalmanInit()
        UIApplication.shared.isIdleTimerDisabled = true//sleepしない
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        startTimer()//resizerectのチェックの時はここをコメントアウト*********************
//        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        let avAsset = AVURLAsset(url: videoURL!, options: options)

        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avasset!)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return
        }
        guard let videoTrack = avasset!.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader.add(readerOutput)
        let startTime = CMTime(value: CMTimeValue(currFrameNumber/*CGFloat(24+currFrameNumber)*getFpsZureRate(fps: videoFps)*/), timescale: CMTimeScale(videoFps))
//        let startTime = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(videoFps))
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
//        print("currFrameNumber:",currFrameNumber)
//        if currFrameNumber>0{
//            //下行は訳わかっていないが、getFpsZureRateで割り、さらにもう一度割る。
////            let n=Int(CGFloat(currFrameNumber)/getFpsZureRate(fps: videoFps)/getFpsZureRate(fps: videoFps))
//            let n=currFrameNumber
//            for _ in 0..<n {
//            eyePosXOrig.append(0)
//            eyePosXFiltered.append(0)
//            eyePosYOrig.append(0)
//            eyePosYFiltered.append(0)
//            eyeVeloXFiltered.append(0)
//            eyeVeloYFiltered.append(0)
//            }
//        }
        // UnsafeとMutableはまあ調べてもらうとして、eX, eY等は<Int32>が一つ格納されている場所へのポインタとして宣言される。
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        //        var eyeCGImage:CGImage!
        //        let eyeUIImage:UIImage!
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        //        var faceCGImage:CGImage!
        //        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        let eyeRectOnScreen=getRectFromCenter(center: eyeCenter, len: wakuLength)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        let faceRectOnScreen=getRectFromCenter(center: faceCenter, len: 3/*wakuLength*/)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: 6/*eyeborder*/)
        
        let context:CIContext = CIContext.init(options: nil)
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        var ciImage:CIImage!
        if videoFps<backCameraFps-10{//cameraType == 0{//front Camera ここは画面表示とは関係なさそう
            ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.down)
        }else{
            ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)
        }
        videoWidth=ciImage.extent.width
        videoHeight=ciImage.extent.height
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:getVideoRectOnScreen(), image:ciImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:getVideoRectOnScreen(), image:ciImage)
        let faceRect = resizeR2(faceRectOnScreen, viewRect:getVideoRectOnScreen(), image:ciImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:getVideoRectOnScreen()/*view.frame*/, image:ciImage)
        //eyeWithBorderRectとeyeRect の差、faceでの差も同じ
//        let borderRectDiffer=faceWithBorderRect.width-faceRect.width
        let eyeCGImage = context.createCGImage(ciImage, from: eyeRect)!
        let eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        let faceCGImage = context.createCGImage(ciImage, from: faceRect)!
        let faceUIImage = UIImage.init(cgImage:faceCGImage)
        
        faceWithBorderCGImage = context.createCGImage(ciImage, from:faceWithBorderRect)!
        faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
      
        let offsetEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0//上下方向への差
        let offsetEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0//左右方向への差
        let offsetFaceX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0//上下方向への差
        let offsetFaceY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0//左右方向への差
        //   "ofset:" osEyeX=osFac,osEyeY=osFacY eyeとface同じ
        let xDiffer = faceWithBorderRect.origin.x - eyeWithBorderRect.origin.x
        let yDiffer = faceWithBorderRect.origin.y - eyeWithBorderRect.origin.y
        var maxEyeV:Double = 0
        var maxFaceV:Double = 0
        //        var frameCnt:Int=0
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
//        var currNumber=currFrameNumber+1
        DispatchQueue.global(qos: .default).async { [self] in
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var eyeX:CGFloat = 0
                var eyeY:CGFloat = 0
                var faceX:CGFloat = 0
                var faceY:CGFloat = 0
                
                var x:CGFloat = 50.0
//                currNumber -= 1
//                if currNumber>0{
//                    eyePosXOrig.append(0)
//                    eyePosXFiltered.append(0)
//                    eyePosYOrig.append(0)
//                    eyePosYFiltered.append(0)
//                    eyeVeloXFiltered.append(0)
//                    eyeVeloYFiltered.append(0)
//                    continue
//                }
        
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!
                    
                    if faceMark == true{
                        if faceWithBorderRect.minX>0 && faceWithBorderRect.maxX<videoWidth && faceWithBorderRect.minY>0 && faceWithBorderRect.maxY<videoHeight{
                            maxFaceV=openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                            if maxFaceV>0.91{
                                faceX = CGFloat(fX.pointee) - offsetFaceX
                                faceY = -CGFloat(fY.pointee) + offsetFaceY
                            }else{
                                faceX=0
                                faceY=0
                            }
                        }else{
                            faceX=0
                            faceY=0
                        }
                        faceWithBorderRect.origin.x += faceX
                        faceWithBorderRect.origin.y += faceY
                    }
                    eyeWithBorderRect.origin.x = faceWithBorderRect.origin.x - xDiffer
                    eyeWithBorderRect.origin.y = faceWithBorderRect.origin.y - yDiffer
                    if eyeWithBorderRect.minX<0 || eyeWithBorderRect.maxX>videoWidth || eyeWithBorderRect.minY<0 || eyeWithBorderRect.maxY>videoHeight{
                        eyeWithBorderRect.origin.x=0
                        eyeWithBorderRect.origin.y=0
                    }
                    if videoFps<backCameraFps-10{//cameraType == 0
                        ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.down)
                    }else{
                        ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)
                    }

                    eyeWithBorderCGImage = context.createCGImage(ciImage, from: eyeWithBorderRect)!
                    eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                    
                    if debugMode == true{
                        //画面表示はmain threadで行う
                        DispatchQueue.main.async {
                            debugEyeWaku_imge.image=eyeWithBorderUIImage
                            view.bringSubviewToFront(debugEyeWaku_imge)
                            x += eyeWithBorderRect.size.width + 5
                        }
                    }
                    if eyeWithBorderRect.minX<0 || eyeWithBorderRect.maxX>videoWidth || eyeWithBorderRect.minY<0 || eyeWithBorderRect.maxY>videoHeight{
                        eyeX=0
                        eyeY=0
                    }else{
                        maxEyeV=openCV.matching(eyeWithBorderUIImage,narrow: eyeUIImage,x: eX,y: eY)
                        if maxEyeV < 0.7{
                            eyeX = 0
                            eyeY = 0
                        }else{//検出できた時
                            //eXはポインタなので、".pointee"でそのポインタの内容が取り出せる。Cでいうところの"*"
                            //上で宣言しているとおりInt32が返ってくるのでCGFloatに変換して代入
                            eyeX = CGFloat(eX.pointee) - offsetEyeX
                            eyeY = CGFloat(eY.pointee) - offsetEyeY
                        }
                    }
                    faceWithBorderCGImage = context.createCGImage(ciImage, from:faceWithBorderRect)!
                    faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                    if debugMode == true && faceMark==true{
                        DispatchQueue.main.async {
                            debugFaceWaku_image.image=faceWithBorderUIImage
                            view.bringSubviewToFront(debugFaceWaku_image)
                        }
                    }
                    context.clearCaches()
                    while handlingDataNowFlag==true{
                        sleep(UInt32(0.1))
                    }
                    eyePosXOrig.append(eyeX)
                    eyePosYOrig.append(eyeY)
                    eyePosXFiltered.append(-1*Kalman(value: eyeX,num: 0))
                    eyePosYFiltered.append(-1*Kalman(value: eyeY,num: 1))
                    let cnt=eyePosXOrig.count
                    eyeVeloXFiltered.append(Kalman(value:eyePosXFiltered[cnt-1]-eyePosXFiltered[cnt-2],num:2))
                    eyeVeloYFiltered.append(Kalman(value:eyePosYFiltered[cnt-1]-eyePosYFiltered[cnt-2],num:3))
                    
                    while reader.status != AVAssetReader.Status.reading {
                        sleep(UInt32(0.1))
                    }
                    if debugMode == true{
                        usleep(200)
                    }
                }//autoReleasePool
            }
            calcFlag = false
        }
    }
     */
    /*
    @objc func update_vHIT(tm: Timer) {
        
        if matchingTestMode==true{
            if calcFlag == false{
                timerCalc.invalidate()
                setButtons(mode: true)
                setVideoButtons(mode: true)
                videoSlider.isEnabled=true
                nextButton.isHidden=false
                backButton.isHidden=false
                matchingTestMode=false
            }
            return
        }
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
            //            makeBoxies()
            //            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
//            print("facevelo x:",faceVeloXFiltered4update.count)
//            print("facevelo y:",faceVeloYFiltered4update.count)
//            print("eyevelo x:",eyeVeloXFiltered4update.count)
            
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
    }*/
//    func makeBoxies(){
//        let vw=view.bounds.width
//        let vh=view.bounds.height
//        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
//        let sliderY=CGFloat(UserDefaults.standard.float(forKey: "sliderY"))
//        waveBoxView.frame=CGRect(x:0,y:sliderY-vw*180/320-5,width:vw,height: vw*180/320)
//        vhitBoxView.frame=CGRect(x:0,y:sliderY-vw*180/320-5-vw*2/5-5,width :vw,height:vw*2/5)
//    }
/*
    func drawLine(num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
#if DEBUG
     print("drawLine:",num,w,h)
#endif
        // 折れ線にする点の配列
        var pointList0 = Array<CGPoint>()
//        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
//        var py1:CGFloat?
//        var point1:CGPoint?
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx:CGFloat = 1//Int(w)/pointCount
//        let posXCount=getPosXFilteredCount()// eyeVeloXFiltered.count
        let gyroMovedCnt=gyroMoved.count
//        let y0=gyroBoxHeight*2/6
        let y1=gyroBoxHeight*3/6
//        let y2=gyroBoxHeight*4/6
        var py0:CGFloat=0
        var step:Int = 1
        if fpsIs120==true{
            step=2
        }
        for n in stride(from: 1, to: pointCount, by: step){
//        for n in 1...(pointCount) {
            if num + n < arrayDataCount && num + n < gyroMovedCnt {
                let px = dx * CGFloat(n)
                 if calcMode==0{
                    py0 = eyeVeloXFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y1
                }else{
                    py0 = eyeVeloYFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y1
                }
//                if faceMark==true{
//                    if calcMode==0{
//                        py1 = faceVeloXFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y2
//                    }else{
//                        py1 = faceVeloYFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y2
//                    }
//                }
                let py2 = -gyroMoved[num + n] * CGFloat(gyroRatio)/150.0 + y1
                let point0 = CGPoint(x: px, y: py0)
//                if faceMark==true{
//                    point1 = CGPoint(x: px, y: py1!)
//                }
                let point2 = CGPoint(x: px, y: py2)
                pointList0.append(point0)
//                if faceMark==true{
//                    pointList1.append(point1!)
//                }
                pointList2.append(point2)
            }
        }
        
        // イメージ処理の開始
//        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath0 = UIBezierPath()
        let drawPath1 = UIBezierPath()
        let drawPath2 = UIBezierPath()
        // 始点に移動する
        drawPath0.move(to: pointList0[0])
        // 配列から始点の値を取り除く
        pointList0.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList0 {
            drawPath0.addLine(to: pt)
        }
//        if faceMark==true{
//            drawPath1.move(to: pointList1[0])
//            // 配列から始点の値を取り除く
//            pointList1.removeFirst()
//            // 配列から点を取り出して連結していく
//            for pt in pointList1 {
//                drawPath1.addLine(to: pt)
//            }
//        }
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
        drawPath0.lineWidth = 0.3
        drawPath1.lineWidth = 0.3
        drawPath2.lineWidth = 0.3
        // 線を描く
        UIColor.red.setStroke()
        drawPath0.stroke()
//        if faceMark == true{
//            UIColor.black.setStroke()
//            drawPath1.stroke()
//        }
        UIColor.black.setStroke()
        drawPath2.stroke()
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",arrayDataCount,CGFloat(arrayDataCount)/240.0,videoDura[videoCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        
        //イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
     func drawRealwave(){//vHIT_eye_head
//         if gyroLineView != nil{//これが無いとエラーがでる。
//             gyroLineView?.removeFromSuperview()
//             //            lineView?.isHidden = false
//         }
         var startcnt:Int
         if arrayDataCount < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
             startcnt = 0
         }else{//横幅超えたら、新しい横幅分を表示
             startcnt = arrayDataCount - Int(self.view.bounds.width)
         }
         //波形を時間軸で表示
         let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:gyroBoxHeight)//180)
         // イメージビューに設定する
         waveBoxView = UIImageView(image: drawImage)
         //       lineView?.center = self.view.center
//         gyroLineView?.center = CGPoint(x:view.bounds.width/2,y:gyroBoxYcenter)//340)//ここらあたりを変更se~7plusの大きさにも対応できた。
//         view.addSubview(gyroLineView!)
         //      showBoxies(f: true)
         //        print("count----" + "\(view.subviews.count)")
     }
     
     func drawOnewave(startcount:Int){//vHIT_eye_head
         var startcnt = startcount
         if startcnt < 0 {
             startcnt = 0
         }
         if gyroLineView != nil{//これが無いとエラーがでる。
             gyroLineView?.removeFromSuperview()
             //            lineView?.isHidden = false
         }
 //        let posXCount=getPosXFilteredCount()
         if arrayDataCount < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
             startcnt = 0
         }else if startcnt > arrayDataCount - Int(self.view.bounds.width){
             startcnt = arrayDataCount - Int(self.view.bounds.width)
         }
         //波形を時間軸で表示
         let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:gyroBoxHeight)// 180)
         // イメージビューに設定する
         gyroLineView = UIImageView(image: drawImage)
         //       lineView?.center = self.view.center
         gyroLineView?.center = CGPoint(x:view.bounds.width/2,y:gyroBoxYcenter)// 340)
         //ここらあたりを変更se~7plusの大きさにも対応できた。
         view.addSubview(gyroLineView!)
         //        print("count----" + "\(view.subviews.count)")
     }
     */
}
