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
//        liveness.setContentType(.form_data)
//        if livenessConfigs.index(forKey: "contentType") != nil {
//            let type = livenessConfigs["contentType"] as! String
//            liveness.setContentType( type == "raw_data" ? .raw_data : .form_data)
//        }
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
        
//        liveness.saveImageinDocumentDirectory(LivenessConfigs.isSaveImage)
//        if livenessConfigs.index(forKey: "isSaveImage") != nil {
//            liveness.saveImageinDocumentDirectory(livenessConfigs["isSaveImage"] as! Bool)
//        }
        
        var isRecVid = LivenessConfigs.isRecordVideo
        if livenessConfigs.index(forKey: "isRecordVideo") != nil {
            isRecVid = livenessConfigs["isRecordVideo"] as! Bool
        }
        if isRecVid && LivenessConfigs.isLivenessGetVideo {
            if(FileManager.default.fileExists(atPath: LivenessConfigs.livenessVideo)) {
                isRecVid = false
            }
        }
        
//        New changes by ANIL => Start
        
//        liveness.setFeedBackLookLeftMessage(LivenessConfigs.feedBackLookLeftMessage)
//        if livenessConfigs.index(forKey: "feedBackLookLeftMessage") != nil {
//            liveness.setFeedBackLookRightMessage(livenessConfigs["feedBackLookLeftMessage"] as! String)
//        }
//
//        liveness.setFeedBackLookRightMessage(LivenessConfigs.feedBackLookRightMessage)
//        if livenessConfigs.index(forKey: "feedBackLookRightMessage") != nil {
//            liveness.setFeedBackLookRightMessage(livenessConfigs["feedBackLookRightMessage"] as! String)
//        }
//
//        liveness.setLowLightThreshHold(LivenessConfigs.feedbackLowLightTolerence)
//        if livenessConfigs.index(forKey: "feedbackLowLightTolerence") != nil {
//            liveness.setLowLightThreshHold(livenessConfigs["feedbackLowLightTolerence"] as! Int32)
//        }
//
//        liveness.setFeedBackFaceInsideOvalMessage(LivenessConfigs.feedBackStartMessage)
//        if livenessConfigs.index(forKey: "feedBackStartMessage") != nil {
//            liveness.setFeedBackFaceInsideOvalMessage(livenessConfigs["feedBackStartMessage"] as! String)
//        }
//
//        liveness.setFeedBackProcessingMessage(LivenessConfigs.feedBackProcessingMessage)
//        if livenessConfigs.index(forKey: "feedBackProcessingMessage") != nil {
//            liveness.setFeedBackProcessingMessage(livenessConfigs["feedBackProcessingMessage"] as! String)
//        }
//
//        liveness.isShowLogo(LivenessConfigs.isShowLogo)
//        if livenessConfigs.index(forKey: "isShowLogo") != nil {
//            liveness.isShowLogo(livenessConfigs["isShowLogo"] as! Bool)
//        }
//        liveness.setLogoImage("ic_logo.png")
//
//        liveness.enableOralVerification(LivenessConfigs.enableOralVerification)
//        if livenessConfigs.index(forKey: "enableOralVerification") != nil {
//            liveness.enableOralVerification(livenessConfigs["enableOralVerification"] as! Bool)
//        }
//        liveness.setButtonStartRecordingIcon("ic_mic.png")
//
//        //set GIF name with extension. make sure GIF files are added in your project root directory.
//        liveness.gifImageName(forLeftMoveFaceAnimation: "accura_liveness_face_left.gif")
//        liveness.gifImageName(forRightMoveFaceAnimation: "accura_liveness_face_Right.gif")
        
//        liveness.setfeedBackVideoRecordingMessage(LivenessConfigs.feedBackVideoRecordingMessage)
//        if livenessConfigs.index(forKey: "feedBackVideoRecordingMessage") != nil {
//            liveness.setfeedBackVideoRecordingMessage(livenessConfigs["feedBackVideoRecordingMessage"] as! String)
//        }
//        liveness.setRecordingMessage(LivenessConfigs.recordingMessage)
//        if livenessConfigs.index(forKey: "recordingMessage") != nil {
//            liveness.setRecordingMessage(livenessConfigs["recordingMessage"] as! String)
//        }

//        liveness.setVideoLengthInSecond(LivenessConfigs.videoLengthInSecond)
//        if livenessConfigs.index(forKey: "videoLengthInSecond") != nil {
//            liveness.setVideoLengthInSecond(livenessConfigs["videoLengthInSecond"] as! Int32)
//        }
//
//        liveness.setfeedBackFMFailMessage(LivenessConfigs.feedbackFMFailed)
//        if livenessConfigs.index(forKey: "feedbackFMFailed") != nil {
//            liveness.setfeedBackFMFailMessage(livenessConfigs["feedbackFMFailed"] as! String)
//        }
//
//        liveness.saveVideoinDocumentDirectory(isRecVid)
//
//        liveness.enableFaceDetect(LivenessConfigs.enableFaceDetect)
//        if livenessConfigs.index(forKey: "enableFaceDetect") != nil {
//            liveness.enableFaceDetect(livenessConfigs["enableFaceDetect"] as! Bool)
//        }
//        liveness.enableFaceMatch(LivenessConfigs.enableFaceMatch)
//        if livenessConfigs.index(forKey: "enableFaceMatch") != nil {
//            liveness.enableFaceMatch(livenessConfigs["enableFaceMatch"] as! Bool)
//        }
//        liveness.fmScoreThreshold(Int32(LivenessConfigs.fmScoreThreshold))
//        if livenessConfigs.index(forKey: "fmScoreThreshold") != nil {
//            liveness.fmScoreThreshold(livenessConfigs["fmScoreThreshold"] as! Int32)
//        }
//
//        liveness.setRecordingTimerTextSize(LivenessConfigs.recordingTimerTextSize)
//        if livenessConfigs.index(forKey: "recordingTimerTextSize") != nil {
//            liveness.setRecordingTimerTextSize(CGFloat(livenessConfigs["recordingTimerTextSize"] as! Float))
//        }
//        liveness.setRecordingTimerTextColor(LivenessConfigs.livenessRecordingTimerColor)
//        if livenessConfigs.index(forKey: "livenessRecordingTimerColor") != nil {
//            liveness.setRecordingTimerTextColor(livenessConfigs["livenessRecordingTimerColor"] as! String)
//        }
//        liveness.setRecordingMessageTextSize(LivenessConfigs.recordingMessageTextSize)
//        if livenessConfigs.index(forKey: "recordingMessageTextSize") != nil {
//            liveness.setRecordingMessageTextSize(livenessConfigs["recordingMessageTextSize"] as! CGFloat)
//        }
//        liveness.setRecordingMessageTextColor(LivenessConfigs.livenessRecordingTextColor)
//        if livenessConfigs.index(forKey: "livenessRecordingTextColor") != nil {
//            liveness.setRecordingMessageTextColor(livenessConfigs["livenessRecordingTextColor"] as! String)
//        }
        
        
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
//            if videoPath != "" {
                results["video_uri"] = ""
//            }
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
    
//    func livenessViewDisappear() {
//        if !isLivenessDone {
//            closeMe()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                if (!self.isCalledCallBack) {
//                    self.isCalledCallBack = true
//                    self.callBack!(["User decline face match" as Any, NSNull()])
//                }
//            }
//        }
//    }
//
//    func livenessData(_ stLivenessValue: String!, livenessImage: UIImage!, status: Bool, imagePath: String!) {
//
//        isCalledCallBack = true
//        isLivenessDone = true
//        var results:[String: Any] = [:]
//        LivenessConfigs.isLivenessGetVideo = false
//        LivenessConfigs.livenessVideo = ""
//        if status == true {
//            print(stLivenessValue)
//            results["status"] = true
//            results["score"] = stLivenessValue.replacingOccurrences(of: " %", with: "")
//            results["with_face"] = gl.withFace
//            results["fm_score"] = 0.0
//            if gl.face1 != nil {
//                gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
//                if gl.face1Detect != nil {
//                    gl.face2Detect = EngineWrapper.detectTargetFaces(livenessImage, feature1: gl.face1Detect!.feature)
//                    results["fm_score"] = EngineWrapper.identify(gl.face1Detect!.feature, featurebuff2: gl.face2Detect!.feature) * 100
//                }
//            }
//            if gl.face2Detect != nil {
//                results["detect"] = KycPl.getImageUri(img: KycPl.resizeImage(image: livenessImage, targetSize: gl.face2Detect!.bound), name: nil)
//            } else {
//                results["detect"] = KycPl.getImageUri(img: livenessImage, name: nil)
//            }
//            if imagePath != "" {
//                results["image_uri"] = "file://\(imagePath!)"
//            }
////            if videoPath != "" {
//                results["video_uri"] = ""
////            }
//            callBack!([NSNull(), KycPl.convertJSONString(results: results)])
//        } else {
//            callBack!(["Failed to get liveness. Please try again", NSNull()])
//        }
//        closeMe()
//    }
//
//    func didChangedLivenessState(_ livenessState: LivenessType) {
//        if(livenessState == .LOOK_RIGHT || livenessState == .APPROVED) {
//            //play Sound
//            playSound()
//        }
//    }
//
//    func livenessData(_ stLivenessValue: String!, livenessImage: UIImage!, status: Bool, videoPath: String!, imagePath: String!) {
//        isLivenessDone = true
//        var results:[String: Any] = [:]
//        if status == false && videoPath != "" {
//            LivenessConfigs.isLivenessGetVideo = true
//            LivenessConfigs.livenessVideo = videoPath!.replacingOccurrences(of: "file://", with: "")
//        } else {
//            LivenessConfigs.isLivenessGetVideo = false
//            LivenessConfigs.livenessVideo = ""
//        }
//        if status == true {
//            print(stLivenessValue)
//            results["status"] = true
//            results["score"] = stLivenessValue.replacingOccurrences(of: " %", with: "")
//            results["with_face"] = gl.withFace
//            results["fm_score"] = 0.0
//            if gl.face1 != nil {
//                gl.face1Detect = EngineWrapper.detectSourceFaces(gl.face1)
//                if gl.face1Detect != nil {
//                    gl.face2Detect = EngineWrapper.detectTargetFaces(livenessImage, feature1: gl.face1Detect!.feature)
//                    results["fm_score"] = EngineWrapper.identify(gl.face1Detect!.feature, featurebuff2: gl.face2Detect!.feature) * 100
//                }
//            }
//            if gl.face2Detect != nil {
//                results["detect"] = KycPl.getImageUri(img: KycPl.resizeImage(image: livenessImage, targetSize: gl.face2Detect!.bound), name: nil)
//            } else {
//                results["detect"] = KycPl.getImageUri(img: livenessImage, name: nil)
//            }
//            if imagePath != "" {
//                results["image_uri"] = "file://\(imagePath!)"
//            }
//            if videoPath != "" {
//                results["video_uri"] = videoPath!
//            }
//            callBack!([NSNull(), KycPl.convertJSONString(results: results)])
//        } else {
//            callBack!(["Failed to get liveness. Please try again", NSNull()])
//        }
//        closeMe()
//    }
}

var player: AVAudioPlayer?
func playSound() {
    guard let url = Bundle.main.url(forResource: "accura_liveness_verified", withExtension: "mp3") else { return }

    do {
        let player = AVPlayer(url: url)
        player.isMuted = false
        player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            player.pause()
        })

    } catch let error {
        print(error.localizedDescription)
    }
}
