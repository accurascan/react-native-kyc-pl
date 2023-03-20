import UIKit
import AccuraLiveness_fm

//View controller for check face match between two faces.
class FMController: UIViewController {
    
    var livenessConfigs:[String: Any] = [:]
    var callBack: RCTResponseSenderBlock? = nil
    var reactViewController:UIViewController? = nil
    var audioPath: URL? = nil
    var isFacematchDone = false
    var isCalledCallBack = false
    
    func closeMe() {
        self.win!.rootViewController = reactViewController!
    }
    var win: UIWindow? = nil
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if ScanConfigs.accuraConfigs.index(forKey: "with_face") != nil {
            gl.withFace = ScanConfigs.accuraConfigs["with_face"] as! Bool
            if gl.withFace {
                if ScanConfigs.accuraConfigs.index(forKey: "face_uri") != nil {
                    if let face = KycPl.getImageFromUri(path: ScanConfigs.accuraConfigs["face_uri"] as! String) {
                        gl.face1 = face
                        gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
                    }
                }
                if ScanConfigs.accuraConfigs.index(forKey: "face_base64") != nil {
                    let newImageData = Data(base64Encoded: ScanConfigs.accuraConfigs["face_base64"] as! String)
                    if let newImageData = newImageData {
                        gl.face1 = UIImage(data: newImageData)
                        gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
                    }
                }
            } else {
                if ScanConfigs.accuraConfigs.index(forKey: "face1") == nil {
                    
                    callBack!(["Missing face1 configration" as Any, NSNull()])
                    closeMe()
                    return
                }
                if ScanConfigs.accuraConfigs.index(forKey: "face2") != nil {
                    let isFace2 = ScanConfigs.accuraConfigs["face2"] as! Bool
                    if isFace2 {
                        if gl.face1 == nil {
                            
                            callBack!(["Please first take Face1 Photo" as Any, NSNull()])
                            closeMe()
                            return
                        } else {
                            gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
                        }
                    }
                } else {
                    
                    callBack!(["Missing face2 configration" as Any, NSNull()])
                    closeMe()
                    return
                }
            }
            
        } else {
            
            callBack!(["Missing with_face configration" as Any, NSNull()])
            closeMe()
            return
        }
        startFC()
    }
    
    func startFC() {
        let liveness = Facematch()
        // To customize your screen theme and feed back messages
        liveness.setBackGroundColor(FaceMatchConfigs.backgroundColor)
        if livenessConfigs["livenessBackground"] != nil {
            liveness.setBackGroundColor(livenessConfigs["livenessBackground"] as! String)
        }
        liveness.setCloseIconColor(LivenessConfigs.livenessCloseIconColor)
        if livenessConfigs["livenessCloseIconColor"] != nil {
            liveness.setCloseIconColor(livenessConfigs["livenessCloseIconColor"] as! String)
        }
        liveness.setFeedbackBackGroundColor(LivenessConfigs.livenessfeedbackBackground)
        if livenessConfigs["livenessfeedbackBackground"] != nil {
            liveness.setFeedbackBackGroundColor(livenessConfigs["livenessfeedbackBackground"] as! String)
        }
        liveness.setFeedbackTextColor(LivenessConfigs.livenessfeedbackTextColor)
        if livenessConfigs["livenessfeedbackTextColor"] != nil {
            liveness.setFeedbackTextColor(livenessConfigs["livenessfeedbackTextColor"] as! String)
        }
        liveness.setFeedbackTextSize(Float(LivenessConfigs.feedbackTextSize))
        if livenessConfigs["feedbackTextSize"] != nil {
            liveness.setFeedbackTextSize(livenessConfigs["feedbackTextSize"] as! Float)
        }
        liveness.setFeedBackframeMessage(LivenessConfigs.feedBackframeMessage)
        if livenessConfigs["feedBackframeMessage"] != nil {
            liveness.setFeedBackframeMessage(livenessConfigs["feedBackframeMessage"] as! String)
        }
        liveness.setFeedBackAwayMessage(LivenessConfigs.feedBackAwayMessage)
        if livenessConfigs["feedBackAwayMessage"] != nil {
            liveness.setFeedBackAwayMessage(livenessConfigs["feedBackAwayMessage"] as! String)
        }
        liveness.setFeedBackOpenEyesMessage(LivenessConfigs.feedBackOpenEyesMessage)
        if livenessConfigs["feedBackOpenEyesMessage"] != nil {
            liveness.setFeedBackOpenEyesMessage(livenessConfigs["feedBackOpenEyesMessage"] as! String)
        }
        liveness.setFeedBackCloserMessage(LivenessConfigs.feedBackCloserMessage)
        if livenessConfigs["feedBackCloserMessage"] != nil {
            liveness.setFeedBackCloserMessage(livenessConfigs["feedBackCloserMessage"] as! String)
        }
        liveness.setFeedBackCenterMessage(LivenessConfigs.feedBackCenterMessage)
        if livenessConfigs["feedBackCenterMessage"] != nil {
            liveness.setFeedBackCenterMessage(livenessConfigs["feedBackCenterMessage"] as! String)
        }
        liveness.setFeedbackMultipleFaceMessage(LivenessConfigs.feedBackMultipleFaceMessage)
        if livenessConfigs["feedBackMultipleFaceMessage"] != nil {
            liveness.setFeedbackMultipleFaceMessage(livenessConfigs["feedBackMultipleFaceMessage"] as! String)
        }
        liveness.setFeedBackFaceSteadymessage(LivenessConfigs.feedBackHeadStraightMessage)
        if livenessConfigs["feedBackHeadStraightMessage"] != nil {
            liveness.setFeedBackFaceSteadymessage(livenessConfigs["feedBackHeadStraightMessage"] as! String)
        }
        liveness.setFeedBackLowLightMessage(LivenessConfigs.feedBackLowLightMessage)
        if livenessConfigs["feedBackLowLightMessage"] != nil {
            liveness.setFeedBackLowLightMessage(livenessConfigs["feedBackLowLightMessage"] as! String)
        }
        liveness.setFeedBackBlurFaceMessage(LivenessConfigs.feedBackBlurFaceMessage)
        if livenessConfigs["feedBackBlurFaceMessage"] != nil {
            liveness.setFeedBackBlurFaceMessage(livenessConfigs["feedBackBlurFaceMessage"] as! String)
        }
        liveness.setFeedBackGlareFaceMessage(LivenessConfigs.feedBackGlareFaceMessage)
        if livenessConfigs["feedBackGlareFaceMessage"] != nil {
            liveness.setFeedBackGlareFaceMessage(livenessConfigs["feedBackGlareFaceMessage"] as! String)
        }
        // 0 for clean face and 100 for Blurry face
        liveness.setBlurPercentage(Int32(LivenessConfigs.setBlurPercentage)) // set blure percentage -1 to remove this filter
        
        if livenessConfigs["setBlurPercentage"] != nil {
            liveness.setBlurPercentage(livenessConfigs["setBlurPercentage"] as! Int32)
        }
        
        var glarePerc0 = Int32(LivenessConfigs.setGlarePercentage_0)
        if livenessConfigs["setGlarePercentage_0"] != nil {
            glarePerc0 = livenessConfigs["setGlarePercentage_0"] as! Int32
        }
        var glarePerc1 = Int32(LivenessConfigs.setGlarePercentage_1)
        if livenessConfigs["setGlarePercentage_1"] != nil {
            glarePerc1 = livenessConfigs["setGlarePercentage_1"] as! Int32
        }
        // Set min and max percentage for glare
        liveness.setGlarePercentage(glarePerc0, glarePerc1) //set glaremin -1 and glaremax -1 to remove this filter
        // Do any additional setup after loading the view.
        liveness.setFacematch(self)
    }
}

extension FMController: FacematchData {
    
    func facematchViewDisappear() {
        print("CALL facematchViewDisappear")
        if !isFacematchDone {
            closeMe()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if (!self.isCalledCallBack) {
                    self.isCalledCallBack = true
                    self.callBack!(["User decline face match" as Any, NSNull()])
                }
            }
        }
        if gl.face2 != nil {
            EngineWrapper.faceEngineClose()
        }
    }
    
    func facematchData(_ FaceImage: UIImage!) {
        
        print("CALL facematchData")
        isCalledCallBack = true
        isFacematchDone = true
        if gl.face1 == nil {
            var results:[String: Any] = [:]
            results["status"] = false
            results["with_face"] = gl.withFace
            gl.face1 = FaceImage
            if gl.face1Detect == nil {
                if let img1 = KycPl.getImageUri(img: gl.face1!, name: nil) {
                    results["img_1"] = img1
                }
            } else {
                if let img1 = KycPl.getImageUri(img: KycPl.resizeImage(image: gl.face1!, targetSize: gl.face1Detect!.bound), name: nil) {
                    results["img_1"] = img1
                }
            }
            if results.index(forKey: "img_1") != nil {
                
                callBack!([NSNull(), KycPl.convertJSONString(results: results)])
            } else {
                
                callBack!(["Error found in data. Please try again" as Any, NSNull()])
            }
            closeMe()
            
        } else {
            gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
            gl.face2 = FaceImage
            gl.face2Detect = EngineWrapper.detectTargetFaces(FaceImage, feature1: gl.face1Detect!.feature)
            let score = EngineWrapper.identify(gl.face1Detect!.feature, featurebuff2: gl.face2Detect!.feature)
            var results:[String: Any] = [:]
            results["status"] = true
            results["score"] = score*100
            results["with_face"] = gl.withFace
            if !gl.withFace {
                if let img1 = KycPl.getImageUri(img: gl.face1!, name: nil) {
                    results["img_1"] = img1
                }
                if let img2 = KycPl.getImageUri(img: gl.face2!, name: nil) {
                    results["img_2"] = img2
                }
            } else {
                if let img1 = KycPl.getImageUri(img: KycPl.resizeImage(image: gl.face2!, targetSize: gl.face2Detect!.bound), name: nil) {
                    results["detect"] = img1
                }
            }
            
            callBack!([NSNull(), results])
            KycPl.cleanFaceData()
            closeMe()
        }
    }
}
