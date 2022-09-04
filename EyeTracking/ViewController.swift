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
extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

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
    var vhitBoxViewImage:UIImage?
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
        let flatwidth:Int = 2//12frame-50ms
        let t = upDownp(i: number + flatwidth)
        if t != 0 {
            if t==1{
                append_vHITwaves(isRight:true,frameN:number,dispOn:true,currDispOn:false)
            }else{
                append_vHITwaves(isRight:false,frameN:number,dispOn:true,currDispOn:false)
            }
            let n=vHITwaves.count-1
            for i in 0..<31{//number..<number + 30{
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
//            print(vHITwaves[i].face)
        }
        print(vHITwaves.count)
        drawVHITBox()
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
  
    func drawVHIT(width w:CGFloat,height h:CGFloat) -> UIImage {
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
//        draw1wave(r: r)//just vHIT
        
        var pointListEye = Array<CGPoint>()
        var pointListFace = Array<CGPoint>()
        let dx0=CGFloat(245.0/30.0)
//        var rlPt:CGFloat = 0
        //r:4(mail)  r:1(screen)
        var posY0=135*r
        let vHITDisplayMode=0
        if vHITDisplayMode==0{//up down
            posY0=90*r
        }
        
        let drawPathEye = UIBezierPath()
        let drawPathFace = UIBezierPath()
        var rightCnt:Int=0
        var leftCnt:Int=0
        for i in 0..<vHITwaves.count{
//            if vHITwaves[i].isRight == false{//}
//                continue
//            }
            pointListEye.removeAll()
            pointListFace.removeAll()
            var dx:CGFloat=0
            if vHITwaves[i].isRight==true{
                dx=0
                rightCnt += 1
            }else{
                dx=260*r
                leftCnt += 1
            }
            for n in 0..<30{
                let px = dx + CGFloat(n)*dx0*r
                let py1 = -vHITwaves[i].eye[n]*r*1000 + posY0
                let py2 = -vHITwaves[i].face[n]*r*1000 + posY0
                let point1 = CGPoint(x:px,y:py1)
                let point2 = CGPoint(x:px,y:py2)
                pointListEye.append(point1)
                pointListFace.append(point2)
            }
            // イメージ処理の開始
            // パスの初期化
               // 始点に移動する
            drawPathEye.move(to: pointListEye[0])
            // 配列から始点の値を取り除く
            pointListEye.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointListEye {
                drawPathEye.addLine(to: pt)
            }
            drawPathFace.move(to: pointListFace[0])
            // 配列から始点の値を取り除く
            pointListFace.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointListFace {
                drawPathFace.addLine(to: pt)
            }
              // 線の色
            if vHITwaves[i].isRight==true{
                UIColor.red.setStroke()
            }else{
                UIColor.blue.setStroke()
            }
            // 線幅
            drawPathEye.lineWidth = 0.3
            drawPathFace.lineWidth = 0.3
            drawPathEye.stroke()
            drawPathEye.removeAllPoints()
            UIColor.black.setStroke()
            drawPathFace.stroke()
            drawPathFace.removeAllPoints()
        }
        rightCnt.description.draw(at: CGPoint(x: 3*r, y: 0), withAttributes: [
               NSAttributedString.Key.foregroundColor : UIColor.black,
               NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
           
        leftCnt.description.draw(at: CGPoint(x: 263*r, y: 0), withAttributes: [
               NSAttributedString.Key.foregroundColor : UIColor.black,
               NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
   
//        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }

 
  
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
 

    override func viewDidLoad() {
        super.viewDidLoad()
        ltEyeVeloX.removeAll()
        faceVeloX.removeAll()
        dateString.removeAll()
        multiEye = iroiro.getUserDefaultCGFloat(str: "multiEye", ret: 100)
        multiFace = iroiro.getUserDefaultCGFloat(str: "multiFace", ret: 100)
 
        displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkUpdate))
        displayLink!.preferredFramesPerSecond = 120
//        view.addSubview(lookAtPointView)
        session.delegate = self
        displayLink?.add(to: RunLoop.main, forMode: .common)
        displayLinkF=true
//        waveSlider.minimumTrackTintColor=UIColor.blue
        waveSlider.minimumTrackTintColor=UIColor.systemGray5
        waveSlider.maximumTrackTintColor=UIColor.systemGray5
        let drawImage = drawVHIT(width:500,height:200)
        vhitBoxViewImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*2/5))
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
        drawWaveBox()
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
        let drawImage = drawWave(startCnt:startCnt,endCnt:endCnt)
        // イメージビューに設定する
        waveBoxView = UIImageView(image: drawImage)
        view.addSubview(waveBoxView!)
    }
    func drawVHITBox(){//解析結果のvHITwavesを表示する
//        view.layer.sublayers?.removeLast()
//        onWaveSliderValueChange()
        let drawImage = drawVHIT(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*2/5))
        vhitBoxView = UIImageView(image: dImage)
        // 画面に表示する
        view.addSubview(vhitBoxView!)
    }
    func drawVHITBox_first(){//解析結果のvHITwavesを表示する
        let drawImage = drawVHIT(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*2/5))
        vhitBoxView = UIImageView(image: dImage)
        // 画面に表示する
        view.addSubview(vhitBoxView!)
    }
    func drawWaveBox(){
        let endCnt = faceVeloX.count
        var startCnt = endCnt-60//点の数
        if startCnt<0{
            startCnt=0
        }
        //波形を時間軸で表示
        let drawImage = drawWave(startCnt:startCnt,endCnt:endCnt)
        // イメージビューに設定する
        waveBoxView = UIImageView(image: drawImage)
//        vhitBoxView = UIImageView(image: vhitBoxViewImage)
        view.addSubview(waveBoxView!)
        print(view.subviews.count)
    }
    
    func setWaveSlider(){
        waveSlider.minimumValue = 60
        waveSlider.maximumValue = Float(faceVeloX.count)
        waveSlider.value=Float(faceVeloX.count)
        waveSlider.addTarget(self, action: #selector(onWaveSliderValueChange), for: UIControl.Event.valueChanged)
    }
    func drawWave(startCnt:Int,endCnt:Int) -> UIImage {
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
            // イメージ処理の開始
            // パスの初期化
            let drawPath1 = UIBezierPath()
            // 始点に移動する
            drawPath1.move(to: pointList1[0])
            // 配列から始点の値を取り除く
            pointList1.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList1 {
                drawPath1.addLine(to: pt)
            }
            // 線幅
            drawPath1.lineWidth = 0.3
            // 線の色
            UIColor.black.setStroke()
            // 線を描く
            drawPath1.stroke()
            
            let drawPath2 = UIBezierPath()
            drawPath2.move(to: pointList2[0])
            // 配列から始点の値を取り除く
            pointList2.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList2 {
                drawPath2.addLine(to: pt)
            }
            drawPath2.lineWidth = 0.3
            UIColor.red.setStroke()
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
        //60hz前後の様だが、少し遅れると同じものを２回拾いそう、どうするか？

        //        let logger = Logger()
        //face, rightEye, leftEyeのx,y軸方向の回転角を出力
        //        logger.log("fh=\(asin(faceAnchor.transform.columns.2.x))")//",fv=\(asin(faceAnchor.transform.columns.1.z))")
        //        logger.log("rh=\(asin(faceAnchor.rightEyeTransform.columns.2.x))")
        //        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x))")
        //",rv=\(asin(faceAnchor.rightEyeTransform.columns.1.z))")
        //        logger.log("lh=\(asin(faceAnchor.leftEyeTransform.columns.2.x)),lv=\(asin(faceAnchor.leftEyeTransform.columns.1.z))")
        
    }
    
}
