import UIKit
import AccuraLiveness_fm
import AVFoundation

//View controller for check liveness.
class LVController: UIViewController
{
    var livenessConfigs:[String: Any] = [:]
    var callBack: RCTResponseSenderBlock? = nil
    var reactViewController:UIViewController? = nil
    var win: UIWindow? = nil
    var audioPath: URL? = nil
    var isLivenessDone = false
    var isCalledCallBack = false
    
    func closeMe() {
        self.win!.rootViewController = reactViewController!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!EngineWrapper.isEngineInit()) {
            EngineWrapper.faceEngineInit()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startLV()
    }
    
    func startLV() {
        let liveness = Liveness()
        
        if ScanConfigs.accuraConfigs.index(forKey: "with_face") != nil {
            gl.withFace = true
            if ScanConfigs.accuraConfigs.index(forKey: "face_uri") != nil {
                if let face = KycPl.getImageFromUri(path: ScanConfigs.accuraConfigs["face_uri"] as! String) {
                    gl.face1 = face
                    
                }
            }
            if ScanConfigs.accuraConfigs.index(forKey: "face_base64") != nil {
                let newImageData = Data(base64Encoded: ScanConfigs.accuraConfigs["face_base64"] as! String)
                if let newImageData = newImageData {
                    gl.face1 = UIImage(data: newImageData)
                }
            }
        } else {
            gl.withFace = true
            if ScanConfigs.accuraConfigs.index(forKey: "face_uri") != nil {
                if let face = KycPl.getImageFromUri(path: ScanConfigs.accuraConfigs["face_uri"] as! String) {
                    gl.face1 = face
                    
                }
            }
            if ScanConfigs.accuraConfigs.index(forKey: "face_base64") != nil {
                let newImageData = Data(base64Encoded: ScanConfigs.accuraConfigs["face_base64"] as! String)
                if let newImageData = newImageData {
                    gl.face1 = UIImage(data: newImageData)
                }
            }
        }
        // To customize your screen theme and feed back messages
        liveness.setLivenessURL(LivenessConfigs.liveness_url)
        if livenessConfigs.index(forKey: "liveness_url") != nil {
            liveness.setLivenessURL(livenessConfigs["liveness_url"] as! String)
        }
        // To customize your screen theme and feed back messages
        liveness.setBackGroundColor(LivenessConfigs.livenessBackground)
        if livenessConfigs.index(forKey: "livenessBackground") != nil {
            liveness.setBackGroundColor(livenessConfigs["livenessBackground"] as! String)
        }
        liveness.setCloseIconColor(LivenessConfigs.livenessCloseIconColor)
        if livenessConfigs.index(forKey: "livenessCloseIconColor") != nil {
            liveness.setCloseIconColor(livenessConfigs["livenessCloseIconColor"] as! String)
        }
        liveness.setFeedbackBackGroundColor(LivenessConfigs.livenessfeedbackBackground)
        if livenessConfigs.index(forKey: "livenessfeedbackBackground") != nil {
            liveness.setFeedbackBackGroundColor(livenessConfigs["livenessfeedbackBackground"] as! String)
        }
        liveness.setFeedbackTextColor(LivenessConfigs.livenessfeedbackTextColor)
        if livenessConfigs.index(forKey: "livenessfeedbackTextColor") != nil {
            liveness.setFeedbackTextColor(livenessConfigs["livenessfeedbackTextColor"] as! String)
        }
        liveness.setFeedBackframeMessage(LivenessConfigs.feedBackframeMessage)
        if livenessConfigs.index(forKey: "feedBackframeMessage") != nil {
            liveness.setFeedBackframeMessage(livenessConfigs["feedBackframeMessage"] as! String)
        }
        liveness.setFeedBackAwayMessage(LivenessConfigs.feedBackAwayMessage)
        if livenessConfigs.index(forKey: "feedBackAwayMessage") != nil {
            liveness.setFeedBackAwayMessage(livenessConfigs["feedBackAwayMessage"] as! String)
        }
        liveness.setFeedBackOpenEyesMessage(LivenessConfigs.feedBackOpenEyesMessage)
        if livenessConfigs.index(forKey: "feedBackOpenEyesMessage") != nil {
            liveness.setFeedBackOpenEyesMessage(livenessConfigs["feedBackOpenEyesMessage"] as! String)
        }
        liveness.setFeedBackCloserMessage(LivenessConfigs.feedBackCloserMessage)
        if livenessConfigs.index(forKey: "feedBackCloserMessage") != nil {
            liveness.setFeedBackCloserMessage(livenessConfigs["feedBackCloserMessage"] as! String)
        }
        liveness.setFeedBackCenterMessage(LivenessConfigs.feedBackCenterMessage)
        if livenessConfigs.index(forKey: "feedBackCenterMessage") != nil {
            liveness.setFeedBackCenterMessage(livenessConfigs["feedBackCenterMessage"] as! String)
        }
        liveness.setFeedbackMultipleFaceMessage(LivenessConfigs.feedBackMultipleFaceMessage)
        if livenessConfigs.index(forKey: "feedBackMultipleFaceMessage") != nil {
            liveness.setFeedbackMultipleFaceMessage(livenessConfigs["feedBackMultipleFaceMessage"] as! String)
        }
        liveness.setFeedBackFaceSteadymessage(LivenessConfigs.feedBackHeadStraightMessage)
        if livenessConfigs.index(forKey: "feedBackHeadStraightMessage") != nil {
            liveness.setFeedBackFaceSteadymessage(livenessConfigs["feedBackHeadStraightMessage"] as! String)
        }
        liveness.setFeedBackLowLightMessage(LivenessConfigs.feedBackLowLightMessage)
        if livenessConfigs.index(forKey: "feedBackLowLightMessage") != nil {
            liveness.setFeedBackLowLightMessage(livenessConfigs["feedBackLowLightMessage"] as! String)
        }
        liveness.setFeedBackBlurFaceMessage(LivenessConfigs.feedBackBlurFaceMessage)
        if livenessConfigs.index(forKey: "feedBackBlurFaceMessage") != nil {
            liveness.setFeedBackBlurFaceMessage(livenessConfigs["feedBackBlurFaceMessage"] as! String)
        }
        liveness.setFeedBackGlareFaceMessage(LivenessConfigs.feedBackGlareFaceMessage)
        if livenessConfigs.index(forKey: "feedBackGlareFaceMessage") != nil {
            liveness.setFeedBackGlareFaceMessage(livenessConfigs["feedBackGlareFaceMessage"] as! String)
        }
        liveness.setFeedbackTextSize(LivenessConfigs.feedbackTextSize)
        if livenessConfigs.index(forKey: "feedbackTextSize") != nil {
            liveness.setFeedbackTextSize(livenessConfigs["feedbackTextSize"] as! Float)
        }
        
        liveness.setBlurPercentage(LivenessConfigs.setBlurPercentage) // set blure percentage -1 to remove this filter
        
        if livenessConfigs.index(forKey: "setBlurPercentage") != nil {
            liveness.setBlurPercentage(livenessConfigs["setBlurPercentage"] as! Int32)
        }
        
        var glarePerc0 = LivenessConfigs.setGlarePercentage_0
        if livenessConfigs.index(forKey: "setGlarePercentage_0") != nil {
            glarePerc0 = livenessConfigs["setGlarePercentage_0"] as! Int32
        }
        var glarePerc1 = Int32(LivenessConfigs.setGlarePercentage_1)
        if livenessConfigs.index(forKey: "setGlarePercentage_1") != nil {
            glarePerc1 = livenessConfigs["setGlarePercentage_1"] as! Int32
        }
        liveness.setGlarePercentage(glarePerc0, glarePerc1) //set glaremin -1 and glaremax -1 to remove this filter
        
        var isRecVid = LivenessConfigs.isRecordVideo
        if livenessConfigs.index(forKey: "isRecordVideo") != nil {
            isRecVid = livenessConfigs["isRecordVideo"] as! Bool
        }
        if isRecVid && LivenessConfigs.isLivenessGetVideo {
            if(FileManager.default.fileExists(atPath: LivenessConfigs.livenessVideo)) {
                isRecVid = false
            }
        }
        
//        New changes by ANIL => End
//        liveness.evaluateServerTrustWIthSSLPinning(false)
        liveness.setLiveness(self)
    }
    
}

extension LVController: LivenessData {
    
    func livenessData(_ stLivenessValue: String!, livenessImage: UIImage!, status: Bool) {
            
        isCalledCallBack = true
        isLivenessDone = true
        var results:[String: Any] = [:]
        LivenessConfigs.isLivenessGetVideo = false
        LivenessConfigs.livenessVideo = ""
        if status == true {
            print(stLivenessValue)
            results["status"] = true
            results["score"] = stLivenessValue.replacingOccurrences(of: " %", with: "")
            results["with_face"] = gl.withFace
            results["fm_score"] = 0.0
            if gl.face1 != nil {
                gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
                if gl.face1Detect != nil {
                    gl.face2Detect = EngineWrapper.detectTargetFaces(livenessImage, feature1: gl.face1Detect!.feature)
                    results["fm_score"] = EngineWrapper.identify(gl.face1Detect!.feature, featurebuff2: gl.face2Detect!.feature) * 100
                }
            }
            if gl.face2Detect != nil {
                results["detect"] = KycPl.getImageUri(img: KycPl.resizeImage(image: livenessImage, targetSize: gl.face2Detect!.bound), name: nil)
            } else {
                results["detect"] = KycPl.getImageUri(img: livenessImage, name: nil)
            }
            results["video_uri"] = ""

            callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        } else {
            callBack!(["Failed to get liveness. Please try again", NSNull()])
        }
        closeMe()
    }
    
    func livenessViewDisappear() {
        if !isLivenessDone {
            closeMe()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if (!self.isCalledCallBack) {
                    self.isCalledCallBack = true
                    self.callBack!(["User decline face match" as Any, NSNull()])
                }
            }
        }
    }   
}
