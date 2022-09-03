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
    var multiEye:CGFloat=100
    var multiFace:CGFloat=100
    var ltEyeVeloX = Array<CGFloat>()
    var faceVeloX = Array<CGFloat>()
    var dateString = Array<String>()
    @IBOutlet weak var saveButton: UIButton!
    var waveBoxView:UIImageView?
    var vhitBoxView:UIImageView?
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var pauseARKitButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var waveSlider: UISlider!
    var displayLinkF:Bool=false
    var displayLink:CADisplayLink?
    var faceAnchorFlag:Bool=false
    var faceX:CGFloat=0
    var ltEyeX:CGFloat=0
    var rtEyeX:CGFloat=0
    private let session = ARSession()
    //vhit
    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var gyroWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
    var tempTuple = Array<(Int,Int,Int,Int)>()

    struct wave {
        var isRight : Bool
        var frameN : Int
        var dispOn : Bool
        var currDispOn : Bool
        var eye = [CGFloat](repeating:0,count:31)
        var face = [CGFloat](repeating:0,count:31)
    }
    var vHITwaves = [wave]()
    var vHITwave = [CGFloat](repeating: 0, count: 31)
    func append_vHITwaves(isRight:Bool,frameN:Int,dispOn:Bool,currDispOn:Bool){
        let temp=wave(isRight: isRight,frameN: frameN, dispOn: dispOn, currDispOn: currDispOn,eye:vHITwave,face:vHITwave)
        vHITwaves.append(temp)
    }
    func init_vHITwaves(num:Int){
        let temp=wave(isRight: true,frameN: 0, dispOn: true, currDispOn: true,eye:vHITwave,face:vHITwave)
        for _ in 0...num{
            vHITwaves.append(temp)
        }
        vHITwaves[0].eye[5]=1
        vHITwaves[0].dispOn=false
        vHITwaves[1].isRight=false
        print(vHITwaves[0])
        print(vHITwaves[1])
    }
//    func g5(st:Int)->CGFloat{
//        if st>3 && st<gyroMoved.count-2{
//            return(gyroMoved[st-2]+gyroMoved[st-1]+gyroMoved[st]+gyroMoved[st+1]+gyroMoved[st+2])*2.0
//        }
//        return 0
//    }
    
    func upDownp(i:Int)->Int{//60hz -> 16.7ms
//        let waveWidth:Int=80 vhitPeakまで
//        let widthRange:Int=30
        let naf:Int=5//84ms  waveWidth*60/1000
        let raf:Int=2//33ms  widthRange*60/1000
        let sl:CGFloat=0//slope
        let g1=faceVeloX[i+1]-faceVeloX[i]// st:i+1)-g5(st:i)
        let g2=faceVeloX[i+2]-faceVeloX[i+1]// st:i+1)-g5(st:i)
        let g3=faceVeloX[i+3]-faceVeloX[i+2]// st:i+1)-g5(st:i)
        let ga=faceVeloX[i+naf-raf+1]-faceVeloX[i+naf-raf]// st:i+1)-g5(st:i)
        let gb=faceVeloX[i+naf-raf+2]-faceVeloX[i+naf-raf+1]// st:i+1)-g5(st:i)
        let gc=faceVeloX[i+naf+raf+1]-faceVeloX[i+naf+raf]// st:i+1)-g5(st:i)
        let gd=faceVeloX[i+naf+raf+2]-faceVeloX[i+naf+raf+1]// st:i+1)-g5(st:i)
//
//        if       g1 > 4  && g2>g1+1 && g3>g2+1 && ga >  sl && gb > sl  && gc < -sl  && gd < -sl  {
//            return -1
//        }else if g1 < -4 && g2<g1+1 && g3<g2+1 && ga < -sl && gb < -sl && gc >  sl  && gd >  sl{
//            return 1
//        }
        //下のように変更すると小さな波も拾える
//        if       g1 > 0  && g2>g1 && g3>g2 {
//            return -1
//        }
        
        if       g1 > 0  && g2>g1 && g3>g2 && ga >  sl && gb > sl  && gc < -sl  && gd < -sl  {
            return -1
        }else if g1 < 0 && g2<g1 && g3<g2 && ga < -sl && gb < -sl && gc >  sl  && gd >  sl{
            return 1
        }
        return 0
    }
    
    func setVHITWaves(number:Int) -> Int {//0:波なし 1:上向き波？ -1:その反対向きの波
        let flatwidth:Int = 3//12frame-50ms
        let t = upDownp(i: number + flatwidth)
        if t != 0 {
            if t==1{
                append_vHITwaves(isRight:true,frameN:number,dispOn:true,currDispOn:false)
            }else{
                append_vHITwaves(isRight:false,frameN:number,dispOn:true,currDispOn:false)
            }
            let n=vHITwaves.count-1
            for i in 0...30{//number..<number + 30{
                vHITwaves[n].eye[i]=ltEyeVeloX[number+i]
                vHITwaves[n].face[i]=faceVeloX[number+i]
            }
        }
        return t
    }
    func getVHITWaves(){
        if faceVeloX.count < 60 {// <1sec 16.7ms*60=1002ms
            return
        }
        var skipCnt:Int = 0
        for vcnt in 30..<(faceVeloX.count - 40) {//501ms 668ms
            if skipCnt > 0{
                skipCnt -= 1
            }else if setVHITWaves(number:vcnt) != 0{
                skipCnt = 30 //16.7ms*30=501ms 間はスキップ
            }
        }
    }
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        getVHITWaves()
        for i in 0..<vHITwaves.count{
            print(vHITwaves[i].frameN,vHITwaves[i].isRight)
        }
        print(vHITwaves.count)
    }
 
    func checksetPos(pos:Int,mode:Bool) -> Int{
        let cnt=vHITwaves.count
        var return_n = -2
        if cnt>0{
            for i in 0..<cnt{
                if vHITwaves[i].frameN<pos && vHITwaves[i].frameN+30>pos{
                    vHITwaves[i].currDispOn = mode //sellected
                    return_n = i
                    break
                }
                vHITwaves[i].currDispOn = false//not sellected
            }
            if return_n > -1 && return_n < cnt{
                for n in (return_n + 1)..<cnt{
                    vHITwaves[n].currDispOn = false
                }
            }
        }else{
            return -1
        }
        return return_n
    }
  /*
    func drawvhitWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        var r:CGFloat=1//r:倍率magnification
        if w==500*4{//mail
           r=4
        }
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
//        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:"// + idString + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        str2.draw(at: CGPoint(x: 5*r, y: 180*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428*r, y: 180*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        
        UIColor.black.setStroke()
        var pList = Array<CGPoint>()
        pList.append(CGPoint(x:0,y:0))
        pList.append(CGPoint(x:0,y:180*r))
        pList.append(CGPoint(x:240*r,y:180*r))
        pList.append(CGPoint(x:240*r,y:0))
        pList.append(CGPoint(x:260*r,y:0))
        pList.append(CGPoint(x:260*r,y:180*r))
        pList.append(CGPoint(x:500*r,y:180*r))
        pList.append(CGPoint(x:500*r,y:0))
        drawPath.lineWidth = 0.1*r
        drawPath.move(to:pList[0])
        drawPath.addLine(to:pList[1])
        drawPath.addLine(to:pList[2])
        drawPath.addLine(to:pList[3])
        drawPath.addLine(to:pList[0])
        drawPath.move(to:pList[4])
        drawPath.addLine(to:pList[5])
        drawPath.addLine(to:pList[6])
        drawPath.addLine(to:pList[7])
        drawPath.addLine(to:pList[4])
        for i in 0...4 {
            drawPath.move(to: CGPoint(x:30*r + CGFloat(i)*48*r,y:0))
            drawPath.addLine(to: CGPoint(x:30*r + CGFloat(i)*48*r,y:180*r))
            drawPath.move(to: CGPoint(x:290*r + CGFloat(i)*48*r,y:0))
            drawPath.addLine(to: CGPoint(x:290*r + CGFloat(i)*48*r,y:180*r))
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        draw1wave(r: r)//just vHIT

//
//        blueGainStr.draw(at: CGPoint(x: 263*r, y: 167*r-167*r), withAttributes: [
//            NSAttributedString.Key.foregroundColor : UIColor.black,
//            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 12*r, weight: UIFont.Weight.regular)])
//        redGainStr.draw(at: CGPoint(x: 3*r, y: 167*r-167*r), withAttributes: [
//            NSAttributedString.Key.foregroundColor : UIColor.black,
//            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 12*r, weight: UIFont.Weight.regular)])
//
//        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func draw1wave(r:CGFloat){//just vHIT
//        var redVORGainArray = Array<Double>()
//        var blueVORGainArray = Array<Double>()

        var pointList = Array<CGPoint>()
        let drawPath = UIBezierPath()
        var rlPt:CGFloat = 0
        //r:4(mail)  r:1(screen)
        var posY0=135*r
        let vHITDisplayMode=0
        if vHITDisplayMode==0{//up down
            posY0=90*r
        }
       //15(+12)frame 62.5msでの値(eyeSpeed/headSpeed)を集める.EyeSeeCamに準じて
        let gainPoint:Int=27
        for i in 0..<waveTuple.count{
            if waveTuple[i].2==0{//hidden vhit
                continue
            }
            let tempGain=Double(-eyeWs[i][gainPoint])/Double(gyroWs[i][gainPoint])
            if waveTuple[i].0==0{//
                redVORGainArray.append(tempGain)
            }else{
                blueVORGainArray.append(tempGain)
            }
        }
        let redGainAv=getAve(array: redVORGainArray)
        let redGainSd=getSD(array:redVORGainArray,svvAv: redGainAv)
        let blueGainAv=getAve(array: blueVORGainArray)
        let blueGainSd=getSD(array:blueVORGainArray,svvAv: blueGainAv)
        redGainStr = String(format: "(%d) Gain at 60ms     %.2f sd:%.2f",redVORGainArray.count,redGainAv,redGainSd)
        blueGainStr = String(format:"(%d) Gain at 60ms     %.2f sd:%.2f",blueVORGainArray.count,blueGainAv,blueGainSd)
*/
        /*
        for i in 0..<waveTuple.count{//blue vHIT
            //if hide or leftside(red) return
//            var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)

            if waveTuple[i].2 == 0 || waveTuple[i].0 == 0{//waveTuple[i].2==0/hide ==1/disp
                continue
            }
            for n in 0..<120 {
                let px = 260*r + CGFloat(n)*2*r//260 or 0
                var py:CGFloat = 0
                if vHITDisplayMode==1{
                    py = -CGFloat(eyeWs[i][n])*r + posY0
                }else{
                    py = CGFloat(eyeWs[i][n])*r + posY0
                }
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.blue.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3*r
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        var py:CGFloat=0
        for i in 0..<waveTuple.count{//red vHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 1{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(n*2)*r//260 or 0
//                var py:CGFloat = 0
                if vHITDisplayMode==1{//up down red
                    py = CGFloat(eyeWs[i][n])*r + posY0//表示変更
                }else{
                    py = CGFloat(eyeWs[i][n])*r + posY0
                }
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.red.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3*r
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左右のgyroWsを表示
            if waveTuple[i].2 == 0{//.2 hide
                continue
            }
            if waveTuple[i].0 == 0{//gyro leftside
                rlPt=0
            }else{
                rlPt=260
            }
            
            for n in 0..<120 {
                let px = rlPt*r + CGFloat(n*2)*r
                if vHITDisplayMode==1{//up up
//                    py = -CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更
                    if waveTuple[i].0 == 0{//left side gyro
                        py = -CGFloat(gyroWs[i][n])*r + posY0
                    }else{//right side gyro
                        py = CGFloat(gyroWs[i][n])*r + posY0

                    }
                }else{//up down
                    py = CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更
                }
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            drawPath.move(to: pointList[0])
            pointList.removeFirst()
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            UIColor.black.setStroke()
            drawPath.lineWidth = 0.3*r
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        if r>3{//mailでは太線なし
            return
        }
        for i in 0..<waveTuple.count{//太く表示する
            if waveTuple[i].3 == 1 || (waveTuple[i].3 == 2 && waveTuple[i].2 == 1){
                if waveTuple[i].0 == 0{//left side gyro
                    rlPt=0
                }else{
                    rlPt=260
                }
                for n in 0..<120 {
                    let px = rlPt*r + CGFloat( n*2)*r
                    if vHITDisplayMode==1{//up up
                        py = CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更
                        if waveTuple[i].0 == 0{
                            py = -CGFloat(gyroWs[i][n])*r + posY0
                        }
                    }else{
                        py = CGFloat(gyroWs[i][n])*r + posY0
                    }
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0*r
                pointList.removeAll()
                for n in 0..<120 {
                    let px = rlPt*r + CGFloat(n*2)*r
                    if vHITDisplayMode==1{//up up
                        py = -CGFloat(eyeWs[i][n])*r + posY0//以下４行　表示変更
                        if waveTuple[i].0 == 0{
                            py = CGFloat(eyeWs[i][n])*r + posY0
                        }
                    }else{
                        py = CGFloat(eyeWs[i][n])*r + posY0
                    }
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0*r
                pointList.removeAll()
            }
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
    }
    
    func drawVHITwaves(){//解析結果のvHITwavesを表示する
        if vhitLineView != nil{
            vhitLineView?.removeFromSuperview()
        }
        //        let drawImage = drawWaves(width:view.bounds.width,height: view.bounds.width*2/5)
        let drawImage = drawvhitWaves(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:vhitBoxHeight))//view.bounds.width*2/5))
        vhitLineView = UIImageView(image: dImage)
        vhitLineView?.center =  CGPoint(x:view.bounds.width/2,y:vhitBoxYcenter)
        // 画面に表示する
        view.addSubview(vhitLineView!)
        //   showVog(f: true)
    }*/
    /*
    func drawRealwave(){//vHIT_eye_head
        if gyroLineView != nil{//これが無いとエラーがでる。
            gyroLineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        var startcnt:Int
        if arrayDataCount < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = arrayDataCount - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:gyroBoxHeight)//180)
        // イメージビューに設定する
        gyroLineView = UIImageView(image: drawImage)
        //       lineView?.center = self.view.center
        gyroLineView?.center = CGPoint(x:view.bounds.width/2,y:gyroBoxYcenter)//340)//ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(gyroLineView!)
        //      showBoxies(f: true)
        //        print("count----" + "\(view.subviews.count)")
    }
    */
    /*
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
    }*/
    /*
     //上に中央vHITwaveをタップで表示させるタップ範囲を設定
     let temp = checksetPos(pos:lastVhitpoint + Int(loc.x),mode: 2)
     if temp >= 0{
         if waveTuple[temp].2 == 1{
             waveTuple[temp].2 = 0//hide
          }else{
             waveTuple[temp].2 = 1//disp
         }
//                    print("waveTuple:",waveTuple[temp].2)
     }
     drawVHITwaves()
     */
    
   
    var arKitFlag:Bool=true
    @IBAction func onPauseARKitButton(_ sender: Any) {
        
        if arKitFlag==true && dateString.count>60{
            arKitFlag=false
            setWaveSlider()
            waveSlider.isEnabled=true
            waveSlider.minimumTrackTintColor=UIColor.blue

        }else{
            arKitFlag=true
            waveSlider.isEnabled=false
            waveSlider.minimumTrackTintColor=UIColor.systemGray5
        }
    }
    
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
//        print("sublayer2:",view.layer.sublayers?.count)
    }
    func drawOneWave(){
        let endCnt = faceVeloX.count
        var startCnt = endCnt-60//点の数
       
        if startCnt<0{
            startCnt=0
        }
        //波形を時間軸で表示
        let drawImage = drawLine(startCnt:startCnt,endCnt:endCnt)
        // イメージビューに設定する
        waveBoxView = UIImageView(image: drawImage)
        view.addSubview(waveBoxView!)
     }

    override func viewDidLoad() {
        super.viewDidLoad()
        ltEyeVeloX.removeAll()
        faceVeloX.removeAll()
        dateString.removeAll()
        multiEye = iroiro.getUserDefaultCGFloat(str: "multiEye", ret: 100)
        multiFace = iroiro.getUserDefaultCGFloat(str: "multiFace", ret: 100)
 
        displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkUpdate))
        displayLink!.preferredFramesPerSecond = 60//120
//        view.addSubview(lookAtPointView)
        session.delegate = self
        displayLink?.add(to: RunLoop.main, forMode: .common)
        displayLinkF=true
//        waveSlider.minimumTrackTintColor=UIColor.blue
        waveSlider.minimumTrackTintColor=UIColor.systemGray5
        waveSlider.maximumTrackTintColor=UIColor.systemGray5
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
    var initFlag:Bool=true
    @objc func displayLinkUpdate() {
        if arKitFlag==false{
            return
        }
        if initFlag==true{
            initFlag=false
        }else{
            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
        }
        let y0:CGFloat=view.bounds.height/4-50
        let dy:CGFloat=50

        if faceAnchorFlag==true{//} && faceAnchorFlag == lastFlag{
            let date = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            print(df.string(from: date))
            // 2019-10-19 17:01:09
            dateString.append(df.string(from: date))
            faceVeloX.append(faceVeloX0)
            ltEyeVeloX.append(ltEyeVeloX0)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceVeloX0*multiFace,y:y0),30,UIColor.red.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+ltEyeVeloX0*multiEye,y:y0+dy),30,UIColor.red.cgColor)
        }else{//検出できていない時はappendしない
//            faceVelocityX.append(faceVeloX)
//            eyeVelocityX.append(ltEyeVeloX)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+faceVeloX0,y:y0),30,UIColor.brown.cgColor)
            drawCircle(cPoint:CGPoint(x:view.bounds.width/2+ltEyeVeloX0,y:y0+dy),30,UIColor.brown.cgColor)
        }
        if faceVeloX.count>60*60*2{//2min
            faceVeloX.remove(at: 0)
            ltEyeVeloX.remove(at: 0)
            dateString.remove(at: 0)
        }
        drawOneWave()
    }

    func setButtons(){
//        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))

        let vw=view.bounds.width
        let sp=vw/36
        let bw=vw/6
        let bh=bw*2/3
        let by=view.bounds.height-bottom-sp-bh
        myFunctions().setButtonProperty(mailButton,x:sp*1+bw*0,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(saveButton,x:sp*2+bw*1,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(pauseARKitButton,x:sp*3+bw*2,y:by,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(settingButton,x:sp*4+bw*3,y:by,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(helpButton,x:sp*5+bw*4,y:by,w:bw,h: bh,UIColor.systemBlue)
        waveSlider.frame=CGRect(x:sp,y:by-bh,width: vw-sp*2,height:20)//とりあえず
        let sliderHeight=waveSlider.frame.height
        let sliderY=by-sp*2-sliderHeight
        waveSlider.frame=CGRect(x:sp,y:sliderY,width: vw-sp*2,height:sliderHeight)

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

    @objc func onWaveSliderValueChange(){
        let endCnt=Int(waveSlider.value)
        view.layer.sublayers?.removeLast()
        
        let startCnt = endCnt-60//点の数
        
        //波形を時間軸で表示
        let drawImage = drawLine(startCnt:startCnt,endCnt:endCnt)
        // イメージビューに設定する
        waveBoxView = UIImageView(image: drawImage)
        view.addSubview(waveBoxView!)
    }
    
    func setWaveSlider(){
        waveSlider.minimumValue = 60
        waveSlider.maximumValue = Float(faceVeloX.count)
        waveSlider.value=Float(faceVeloX.count)
        waveSlider.addTarget(self, action: #selector(onWaveSliderValueChange), for: UIControl.Event.valueChanged)
    }
    func drawLine(startCnt:Int,endCnt:Int) -> UIImage {
        let size = CGSize(width:view.bounds.width, height:view.bounds.width*18/32)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // 折れ線にする点の配列
        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let pointCount:CGFloat = 60 // 点の個数
        // xの間隔
        let dx:CGFloat = view.bounds.width/pointCount
        let y1=view.bounds.width*18/32*2/6
        let y2=view.bounds.width*18/32*4/6
        var py1:CGFloat=0
        var py2:CGFloat=0
        if endCnt>5{
            for n in startCnt..<endCnt{
                let px = dx * CGFloat(n-startCnt)
                py1 = faceVeloX[n] * multiFace + y1
                py2 = ltEyeVeloX[n] * multiEye + y2
                let point1 = CGPoint(x: px, y: py1)
                let point2 = CGPoint(x: px, y: py2)
                pointList1.append(point1)
                pointList2.append(point2)
            }
            
            //        print("count:",startCnt,endCnt,pointList1.count)
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
            var text=dateString[endCnt-1]
            if arKitFlag==false{
                text += "  face:" + Int(-faceVeloX[endCnt-1]*100000).description + " eye:" + Int(-ltEyeVeloX[endCnt-1]*100000).description + " n:" + endCnt.description
            }
            text.draw(at:CGPoint(x:3,y:3),withAttributes: [
                NSAttributedString.Key.foregroundColor : UIColor.black,
                NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        }
        //イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }

    var tapPosleftRight:Int=0//left-eye,right=head最初にタップした位置で

    var moveThumX:CGFloat=0
    var moveThumY:CGFloat=0
    var startMultiFace:CGFloat=0
    var startMultiEye:CGFloat=0
    var startCnt:Int=0
    
    @IBAction func panGesture1(_ sender: UIPanGestureRecognizer) {
        let move:CGPoint = sender.translation(in: self.view)
        if sender.state == .began {
            moveThumX=0
            moveThumY=0
            
            if sender.location(in: view).y>view.bounds.height*2/5{
                if sender.location(in: view).x<view.bounds.width/3{
                    tapPosleftRight=0
                    print("left")
                }else if sender.location(in: view).x<view.bounds.width*2/3{
                    tapPosleftRight=1
                }else{
                    tapPosleftRight=2
                    print("right")
                }
                startMultiEye=multiEye
                startMultiFace=multiFace
                startCnt=Int(waveSlider.value)
            }
        } else if sender.state == .changed {
            if sender.location(in: view).y>view.bounds.height*2/5{
                
                moveThumX += move.x*move.x
                moveThumY += move.y*move.y
                
                moveThumX += move.x*move.x
                moveThumY += move.y*move.y
                if moveThumX>moveThumY{//横移動の和＞縦移動の和
//                    var endCnt=Int(waveSlider.value)
                    var endCnt=startCnt + Int(move.x/10)
                    if endCnt>faceVeloX.count-1{
                        endCnt=faceVeloX.count-1
                    }else if endCnt<60{
                        endCnt=60
                    }
//                    print("x:",move.x)
                    waveSlider.value=Float(endCnt)
                }else{
                
                
                if tapPosleftRight==0{
                    multiEye=startMultiEye - move.y
                }else if tapPosleftRight==1{
                    multiFace=startMultiFace - move.y
                    multiEye=startMultiEye - move.y
                }else{
                    multiFace=startMultiFace - move.y
                }
                
                if multiFace>4000{
                    multiFace=4000
                }else if multiFace<10{
                    multiFace=10
                }
                
                if multiEye>4000{
                    multiEye=4000
                }else if multiEye<10{
                    multiEye=10
                }
                }
                onWaveSliderValueChange()
                //            drawOnewave(startcount: vhitCurpoint)
            }
            
        }else if sender.state == .ended{
            UserDefaults.standard.set(multiFace, forKey: "multiFace")
            UserDefaults.standard.set(multiEye, forKey: "multiEye")
        }
//        print("multiEye:",multiEye,multiFace)
    }

    var lastTime=CFAbsoluteTimeGetCurrent()
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
        let lag=CFAbsoluteTimeGetCurrent()-lastTime
//        print(lag)
        lastTime=CFAbsoluteTimeGetCurrent()

        //        let logger = Logger()
        //face, rightEye, leftEyeのx,y軸方向の回転角を出力
        //        logger.log("fh=\(asin(faceAnchor.transform.columns.2.x))")//",fv=\(asin(faceAnchor.transform.columns.1.z))")
        //        logger.log("rh=\(asin(faceAnchor.rightEyeTransform.columns.2.x))")
        //        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x))")
        //",rv=\(asin(faceAnchor.rightEyeTransform.columns.1.z))")
        //        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x)),lv=\(asin(faceAnchor.leftEyeTransform.columns.1.z))")
        
    }
    
}
