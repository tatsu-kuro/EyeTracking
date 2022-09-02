//
//  myFunction.swift
//  EyeTracking
//
//  Created by 黒田建彰 on 2022/08/30.
//

import UIKit
import Photos
import AVFoundation

class myFunctions: NSObject, AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let g:Int=0
    }
    
    let tempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "Fushiki"
    var videoDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession!
    var fileOutput = AVCaptureMovieFileOutput()
    var soundIdx:SystemSoundID = 0
    var saved2album:Bool = false
    var videoDate = Array<String>()
    var videoPHAsset = Array<PHAsset>()

    var recordStartTime=CFAbsoluteTimeGetCurrent()

    var albumExistFlag:Bool = false
    var dialogStatus:Int=0
    var fpsCurrent:Int=0
    var widthCurrent:Int=0
    var heightCurrent:Int=0
    var cameraMode:Int=0
    //ジワーッと文字を表示するため
    func updateRecClarification(tm: Int)->CGFloat {
        var cnt=tm%40
        if cnt>19{
            cnt = 40 - cnt
        }
        var alpha=CGFloat(cnt)*0.9/20.0//少し目立たなくなる
        alpha += 0.05
        return alpha
    }
    func getRecClarificationRct(width:CGFloat,height:CGFloat)->CGRect{
        let w=width/100
        let left=CGFloat( UserDefaults.standard.float(forKey: "left"))
        if left==0{
            return CGRect(x:width-w,y:height-w,width:w,height:w)
        }else{
            return CGRect(x:left/6,y:height-height/5.5,width:w,height:w)
        }
    }
//    func checkEttString(ettStr:String)->Bool{//ettTextがちゃんと並んでいるか like as 1,2:3:20,3:2:20
//        let ettTxtComponents = ettStr.components(separatedBy: ",")
//        let widthCnt = ettTxtComponents[0].components(separatedBy: ":").count
//        var paramCnt = 3
//        if ettTxtComponents.count<2{
//            return false
//        }
//        for i in 1...ettTxtComponents.count-1{//3個以外の時はその数値をセット
//            let str = ettTxtComponents[i].components(separatedBy: ":")
//            if str.count != 3{
//                paramCnt = str.count
//            }
//        }
//
//        if widthCnt == 1 && paramCnt == 3 && ettStr.isAlphanumeric(){
//            return true
//        }else{
//            return false
//        }
//    }
    func albumExists() -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
            PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumName {
                return true
            }
        }
        return false
    }
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum( callback: @escaping (Bool) -> Void) {
        if self.albumExists() {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({ [self] in
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
    func makeAlbum(){
        if albumExists()==false{
            createNewAlbum() { [self] (isSuccess) in
                if isSuccess{
                    print(albumName," can be made,")
                } else{
                    print(albumName," can't be made.")
                }
            }
        }else{
            print(albumName," exist already.")
        }
    }
    func getPHAssetcollection()->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        //アルバムはviewdidloadで作っているのであるはず？
//        if (assetCollections.count > 0) {
        //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
        return assetCollections.object(at:0)
    }
    func requestAVAsset(asset: PHAsset)-> AVAsset? {
        guard asset.mediaType == .video else { return nil }
        let phVideoOptions = PHVideoRequestOptions()
        phVideoOptions.version = .original
        let group = DispatchGroup()
        let imageManager = PHImageManager.default()
        var avAsset: AVAsset?
        group.enter()
        imageManager.requestAVAsset(forVideo: asset, options: phVideoOptions) { (asset, _, _) in
            avAsset = asset
            group.leave()
            
        }
        group.wait()
        
        return avAsset
    }
    var gettingAlbumF:Bool = false

    func getAlbumAssets_last(){
        gettingAlbumF = true
        getAlbumAssets_last_sub()
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
    }
    
    func getAlbumAssets_last_sub(){
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = false//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在しない時
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            for i in (assets.count-2)..<assets.count{
                let asset=assets[0]
                if asset.duration>0{//静止画を省く
                    videoPHAsset.insert(asset,at:0)
//                    print("asset:",asset)
//                    videoURL.append(nil)
                    let date_sub = asset.creationDate
                    let date = formatter.string(from: date_sub!)
                    let duration = String(format:"%.1fs",asset.duration)
                    videoDate.insert(date + "(" + duration + ")",at:0)
//                    asset.video
//                    videoDura.append(duration)
                }
//            }
            gettingAlbumF = false
        }else{
            gettingAlbumF = false
        }
    }

    func getAlbumAssets(){
        gettingAlbumF = true
        getAlbumAssets_sub()
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
        for i in (0..<videoDate.count).reversed(){//cloudのは見ない・削除する
            let avasset = requestAVAsset(asset: videoPHAsset[i])
            if avasset == nil{
                videoPHAsset.remove(at: i)
                videoDate.remove(at: i)
            }
        }
    }
    
    func getAlbumAssets_sub(){
        let requestOptions = PHImageRequestOptions()
        videoPHAsset.removeAll()
        videoDate.removeAll()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在しない時
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in 0..<assets.count{
                let asset=assets[i]
                if asset.duration>0{//静止画を省く
                    videoPHAsset.append(asset)
                    let date_sub = asset.creationDate
                    let date = formatter.string(from: date_sub!)
                    let duration = String(format:"%.1fs",asset.duration)
                    videoDate.append(date + "(" + duration + ")")
                }
            }
            gettingAlbumF = false
        }else{
            gettingAlbumF = false
        }
    }
 
    func setZoom(level:Float){//
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        if let device = videoDevice {
        do {
            try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(level) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
            device.unlockForConfiguration()
            } catch {
                print("Failed to change zoom.")
            }
        }
    }
    var focusChangeable:Bool=true
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        focusChangeable=false
        if let device = videoDevice{
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                print("focus_supported")
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                    device.unlockForConfiguration()
                    focusChangeable=true
                }
                catch {
                    // just ignore
                    print("focuserror")
                }
            }else{
                print("focus_not_supported")

//                if cameraType==2{
//                    setZoom(level: focus*4/10)//vHITに比べてすでに1/4にしてあるので
//                    return
//                }
            }
        }
    }
    func setFocus1(focus:Float){//focus 0:最接近　0-1.0
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        if let device = videoDevice {
            do {
                try! device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported{
                    //Add Focus on Point
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    func eraseVideo(number:Int) {
        dialogStatus=0
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
//        print("asset:",assetCollections.count)
        //アルバムが存在しない事もある？
        
        if (assetCollections.count > 0) {
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            var eraseAssetDate=assets[0].creationDate
//            var eraseAssetPngNumber=0
            for i in 0..<assets.count{
                let date_sub=assets[i].creationDate
                let date = formatter.string(from:date_sub!)
                if videoDate[number].contains(date){
                    if !assets[i].canPerform(.delete) {
                        return
                    }
                    var delAssets=Array<PHAsset>()
                    delAssets.append(assets[i])
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.deleteAssets(NSArray(array: delAssets))
                    }, completionHandler: { [self] success,error in//[self] _, _ in
                        if success==true{
                            dialogStatus = 1//YES
                        }else{
                            dialogStatus = -1//NO
                        }
                        // 削除後の処理
                    })
//                    break
                }
            }
        }
    }

    func setLabelProperty(_ label:UILabel,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,_ color:UIColor){
        label.frame = CGRect(x:x, y:y, width: w, height: h)
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.backgroundColor = color
    }
 
    func setButtonProperty(_ button:UIButton,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,_ color:UIColor){
        button.frame   = CGRect(x:x, y:y, width: w, height: h)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5
        button.backgroundColor = color
    }
    func getUserDefaultInt(str:String,ret:Int) -> Int{
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultBool(str:String,ret:Bool) -> Bool{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.bool(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultFloat(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultCGFloat(str:String,ret:CGFloat) -> CGFloat{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return CGFloat(UserDefaults.standard.float(forKey: str))
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultString(str:String,ret:String) -> String{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.string(forKey:str)!
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func setLedLevel_NewDevice(_ level: Float){//videoDeviceがない時はこちらを使う
//          let level = Float(sl.value)
          if let avDevice = AVCaptureDevice.default(for: AVMediaType.video){
              
              if avDevice.hasTorch {
                  do {
                      // torch device lock on
                      try avDevice.lockForConfiguration()
                      
                      if (level > 0.0){
                          do {
                              try avDevice.setTorchModeOn(level: level)
                          } catch {
                              print("error")
                          }
                          
                      } else {
                          // flash LED OFF
                          // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
                          avDevice.torchMode = AVCaptureDevice.TorchMode.off
                      }
                      // torch device unlock
                      avDevice.unlockForConfiguration()
                      
                  } catch {
                      print("Torch could not be used")
                  }
              } else {
                  print("Torch is not available")
              }
          }
          else{
              // no support
          }
      }
    
    func setLedLevel(_ level:Float){
        
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        if let device = videoDevice{
            do {
                if device.hasTorch {
                    do {
                        // torch device lock on
                        try device.lockForConfiguration()
                        
                        if (level > 0.0){
                              do {
                                try device.setTorchModeOn(level: level)
                            } catch {
                                print("error")
                            }
                            
                        } else {
                            // flash LED OFF
                            // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
                            device.torchMode = AVCaptureDevice.TorchMode.off
                        }
                        // torch device unlock
                        device.unlockForConfiguration()
                        
                    } catch {
                        print("Torch could not be used")
                    }
                }
            }
        }
    }
}


