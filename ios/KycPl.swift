import Foundation
import UIKit
import AccuraOCR
import AccuraLiveness_fm

struct gl {
    static var livenessConf:[String: Any] = [:]
    static var ocrClId = "0"
    static var face1: UIImage? = nil
    static var face2: UIImage? = nil
    static var face1Detect: NSFaceRegion? = nil
    static var face2Detect: NSFaceRegion? = nil
    static var withFace = false
    static var type = ""
    static var audio: URL? = nil
    static var PDFDetectFace: UIImage? = nil
    static var PDFFrontSide: UIImage? = nil
    static var PDFBackSide: UIImage? = nil
}

@objc(KycPl)
class KycPl: NSObject {

    var goNativeCallBack: RCTResponseSenderBlock? = nil
    var goNativeAction: String = ""
    var goNativeArgs: NSArray = []
    var viewController: UIViewController? = nil;
    var viewControllerWindow: UIWindow? = nil;
    var defaultAppOriantation: String = "portrait";

    @objc
       func constantsToExport() -> [String: Any]! {
       return ["is_active_accura_kyc_pl": true]
    }

    static func cleanFaceData() {
        gl.face1 = nil
        gl.face2 = nil
        gl.face1Detect = nil
        gl.face2Detect = nil
        gl.withFace = false
        LivenessConfigs.isLivenessGetVideo = false
        print(LivenessConfigs.livenessVideo)
        if LivenessConfigs.livenessVideo != "" {
            if FileManager.default.fileExists(atPath: LivenessConfigs.livenessVideo) {
                do {
                    try FileManager.default.removeItem(atPath: LivenessConfigs.livenessVideo)
                } catch {
                    print(error.localizedDescription)
                }

            } else {
                print(LivenessConfigs.livenessVideo)
            }
        }

        LivenessConfigs.livenessVideo = ""
    }
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    static func getImageFromUri(path: String) -> UIImage? {
        print(path)
        if let img = UIImage.init(contentsOfFile: path.replacingOccurrences(of: "file://", with: "")) {
            return img;
        }
        return nil
    }
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    static func getImageUri(img: UIImage, name: String?) -> String? {
        var file = randomString(length: 6)
        if let filename = name {
            file = filename
        }
        if let data = img.jpegData(compressionQuality: 1.0) {
            let filename = getDocumentsDirectory().appendingPathComponent("\(file).jpg")
            try? data.write(to: filename)
            print(filename.absoluteString)
            return filename.absoluteString
        }

        return nil
    }
    static func resizeImage(image: UIImage, targetSize: CGRect) -> UIImage {
       let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
       var newX = targetSize.origin.x - (targetSize.size.width * 0.4)
       var newY = targetSize.origin.y - (targetSize.size.height * 0.4)
       var newWidth = targetSize.size.width * 1.8
       var newHeight = targetSize.size.height * 1.8
       if newX < 0 {
           newX = 0
       }
       if newY < 0 {
           newY = 0
       }
       if newX + newWidth > image.size.width{
           newWidth = image.size.width - newX
       }
       if newY + newHeight > image.size.height{
           newHeight = image.size.height - newY
       }
       // This is the rect that we've calculated out and this is what is actually used below
       let rect = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
       let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
       let image1: UIImage = UIImage(cgImage: imageRef)
       return image1
   }

    //Code for clear facematch data
    @objc(cleanFaceMatch:)
    func cleanFM(callBack: RCTResponseSenderBlock) {
        KycPl.cleanFaceData()
    }

    //Code for get license info from framework.
    @objc(getMetaData:)
    func getMetaData(_ callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        
        var accuraCameraWrapper: AccuraCameraWrapper? = nil
        var results:[String: Any] = [:]
        results["isValid"] = false
        accuraCameraWrapper = AccuraCameraWrapper.init()
        DispatchQueue.main.async {
            self.viewController = RCTPresentedViewController()!
            self.viewControllerWindow = RCTKeyWindow()!
            
            let sdkModel = accuraCameraWrapper!.loadEngine(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String)
            if sdkModel!.i > 0 {
                var countries:[Any] = []
                results["sdk_version"] = ""
                results["isValid"] = true
                results["isOCR"] = sdkModel!.isOCREnable
                results["isOCREnable"] = sdkModel!.isOCREnable
                results["isBarcode"] = sdkModel!.isBarcodeEnable
                results["isBankCard"] = sdkModel!.isBankCardEnable
                results["isMRZ"] = sdkModel!.isMRZEnable

                let countryListStr = accuraCameraWrapper!.getOCRList();
                for item in countryListStr ?? [] {
                    let cntry = item as! NSDictionary
                    var country:[String: Any] = [:]

                    country["name"] = cntry.value(forKey: "country_name")
                    country["id"] = cntry.value(forKey: "country_id")
                    var cards:[[String: Any]] = []
                    for cd in cntry.value(forKey: "cards") as! NSArray {
                        let cardF = cd as! NSDictionary
                        var card:[String: Any] = [:]
                        card["name"] = cardF.value(forKey:"card_name")
                        card["id"] = cardF.value(forKey:"card_id")
                        card["type"] = cardF.value(forKey:"card_type")
                        cards.append(card)
                    }
                    country["cards"] = cards
                    countries.append(country)
                }
                results["countries"] = countries
                if  sdkModel!.isBarcodeEnable {
                    var barcodes:[[String: String]] = []
                    barcodes.append(["name": "ALL FORMATS","type": "ALL FORMATS"])
                    barcodes.append(["name": "EAN-8", "type": "EAN-8"])
                    barcodes.append(["name": "EAN-13", "type": "EAN-13"])
                    barcodes.append(["name": "PDF417", "type": "PDF417"])
                    barcodes.append(["name": "AZTEC", "type": "AZTEC"])
                    barcodes.append(["name": "CODE 128", "type": "CODE 128"])
                    barcodes.append(["name": "CODE 39", "type": "CODE 39"])
                    barcodes.append(["name": "CODE 93", "type": "CODE 93"])
                    barcodes.append(["name": "DATA MATRIX", "type": "DATA MATRIX"])
                    barcodes.append(["name": "QR CODE", "type": "QR CODE"])
                    barcodes.append(["name": "UPC-E", "type": "UPC-E"])
                    barcodes.append(["name": "UPC-A", "type": "UPC-A"])
                    barcodes.append(["name": "CODABAR", "type": "CODABAR"])
                    results["barcodes"] = barcodes
                }
            }
            self.goNativeCallBack!([NSNull(), KycPl.convertJSONString(results: results)])
        }
    }

    //Code for setup custom messages and config.
    @objc(setupAccuraConfig:callback:)
    func setupAccuraConfig(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;

        ScanConfigs.accuraMessagesConfigs = self.goNativeArgs[0] as! [String: Any]
        self.goNativeCallBack!([NSNull(), "Messages setup successfully"])
    }
    
    //Code for start MRZ document scanning with document type.
    @objc(startMRZ:callback:)
    func startMRZ(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.mrzType = self.goNativeArgs[1] as! String
        ScanConfigs.mrzCountryList = self.goNativeArgs[2] as! String
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 3 ? self.goNativeArgs[3] as! String : self.defaultAppOriantation
        gl.type = "mrz"
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
            viewController.callBack = self.goNativeCallBack
            viewController.isCheckScanOCR = false
            viewController.isCheckCardMRZ = true
            viewController.countryid = 0
            if ScanConfigs.mrzType == "passport_mrz" {
                viewController.MRZDocType = 1
            } else if ScanConfigs.mrzType == "id_mrz" {
                viewController.MRZDocType = 2
            } else if ScanConfigs.mrzType == "visa_mrz" {
                viewController.MRZDocType = 3
            } else {
                viewController.MRZDocType = 0
            }
            viewController.reactViewController = self.viewController
            viewController.win = self.viewControllerWindow
            self.checkForDownloadMedia(vc: viewController)
        }
    }
    
    //Code for start bank card scanning.
    @objc(startBankCard:callback:)
    func startBankCard(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        gl.type = "bankcard"
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 1 ? self.goNativeArgs[1] as! String : self.defaultAppOriantation
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
            viewController.callBack = self.goNativeCallBack
            viewController.isCheckScanOCR = true
            viewController.cardType = 3
            viewController.reactViewController = self.viewController
            viewController.win = self.viewControllerWindow
            self.checkForDownloadMedia(vc: viewController)
        }
    }

    //Code for start barcode scanning with type.
    @objc(startBarcode:callback:)
    func startBarcode(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        gl.type = "barcode"
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.barcodeType = self.goNativeArgs[1] as! String
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 2 ? self.goNativeArgs[2] as! String : self.defaultAppOriantation
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
            viewController.callBack = self.goNativeCallBack
            viewController.isBarCode = true
            viewController.reactViewController = self.viewController
            viewController.win = self.viewControllerWindow
            self.checkForDownloadMedia(vc: viewController)
        }
    }

    //Code for start OCR document scanning with country & card info.
    @objc(startOcrWithCard:callback:)
    func startOcrWithCard(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        gl.type = "ocr"
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.CountryId = self.goNativeArgs[1] as! Int
        ScanConfigs.CardId = self.goNativeArgs[2] as! Int
        ScanConfigs.CardName = self.goNativeArgs[3] as! String
        ScanConfigs.CardType = self.goNativeArgs[4] as! Int
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 5 ? self.goNativeArgs[5] as! String : self.defaultAppOriantation
        DispatchQueue.main.async {
            let viewController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
            viewController.cardType = self.goNativeArgs[4] as! Int
            viewController.callBack = self.goNativeCallBack
            viewController.isCheckScanOCR = true
            viewController.countryid = self.goNativeArgs[1] as! Int
            viewController.cardid = self.goNativeArgs[2] as! Int
            viewController.docName = self.goNativeArgs[3] as! String
            if viewController.cardType == 1 {
                viewController.isBarCode = true
            }
            viewController.reactViewController = self.viewController
            viewController.win = self.viewControllerWindow
            self.checkForDownloadMedia(vc: viewController)
        }
    }

    //Code for start liveness check.
    @objc(startLiveness:callback:)
    func startLiveness(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        //set liveness url
        gl.type = "lv"
        gl.face1 = nil
        gl.face2 = nil
        gl.face1Detect = nil
        gl.face2Detect = nil
        gl.withFace = true
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 2 ? self.goNativeArgs[2] as! String : self.defaultAppOriantation
        DispatchQueue.main.async {
            let LVController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "LVController") as! LVController
            LVController.callBack = self.goNativeCallBack
            LVController.livenessConfigs = self.goNativeArgs[1] as! [String: Any]
            LVController.reactViewController = self.viewController
            LVController.win = self.viewControllerWindow
            let nav = NavigationController(rootViewController: LVController)
            self.viewControllerWindow?.rootViewController = nav
        }
    }

    //Code for start face match check.
    @objc(startFaceMatch:callback:)
    func startFaceMatch(_ argsNew: NSArray, callback: @escaping RCTResponseSenderBlock) {

        self.goNativeCallBack = callback;
        self.goNativeArgs = argsNew;
        gl.type = "fm"
        gl.withFace = true
        let fmInit = EngineWrapper.isEngineInit()
        if !fmInit{
            EngineWrapper.faceEngineInit()
        }
        let fmValue = EngineWrapper.getEngineInitValue() //get engineWrapper load status
        if fmValue == -20{
            sendError(msg: "Key not found")
            return
        }else if fmValue == -15{
            sendError(msg: "License Invalid")
            return
        }
        ScanConfigs.accuraConfigs = self.goNativeArgs[0] as! [String: Any]
        ScanConfigs.accuraConfigs["app_orientation"] = self.goNativeArgs.count > 2 ? self.goNativeArgs[2] as! String : self.defaultAppOriantation
        DispatchQueue.main.async {
            let FMController = UIStoryboard(name: "MainStoryboard_iPhone", bundle: nil).instantiateViewController(withIdentifier: "FMController") as! FMController
            FMController.callBack = self.goNativeCallBack
            FMController.livenessConfigs = self.goNativeArgs[1] as! [String: Any]
            FMController.reactViewController = self.viewController
            FMController.win = self.viewControllerWindow

            let nav = NavigationController(rootViewController: FMController)
            self.viewControllerWindow?.rootViewController = nav
        }
    }
    
    func checkForDownloadMedia(vc: UIViewController) {
        gl.audio = nil
        if ScanConfigs.accuraConfigs.index(forKey: "rg_customMediaURL") != nil{
            let audioUrl = URL(string: ScanConfigs.accuraConfigs["rg_customMediaURL"] as! String)
            if let url = audioUrl {
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
                loadingIndicator.center = self.viewController!.view.center
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = UIActivityIndicatorView.Style.gray
                loadingIndicator.startAnimating();
                self.viewController!.view.addSubview(loadingIndicator)
                let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

                // lets create your destination file url
                let destinationUrl = documentsDirectoryURL.appendingPathComponent("alert.mp3")
                print(destinationUrl)

                // to check if it exists before downloading it
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    do {
                        try FileManager.default.removeItem(at: destinationUrl)
                    } catch {
                        loadingIndicator.removeFromSuperview()
                    }
                    
                }
                URLSession.shared.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                    guard let location = location, error == nil else { return }
                    do {
                        // after downloading your file you need to move it to your destination url
                        try FileManager.default.moveItem(at: location, to: destinationUrl)
                        
                        gl.audio = destinationUrl
                        DispatchQueue.main.async { [self] in
                            loadingIndicator.removeFromSuperview()
                            let nav = UINavigationController(rootViewController: vc)
                            self.viewControllerWindow?.rootViewController = nav
                        }
                    } catch let error as NSError {
                        gl.audio = nil
                        DispatchQueue.main.async { [self] in
                            loadingIndicator.removeFromSuperview()
                            let nav = NavigationController(rootViewController: vc)
                            self.viewControllerWindow?.rootViewController = nav
                        }
                    }
                }).resume()
            } else {
                let nav = NavigationController(rootViewController: vc)
                self.viewControllerWindow?.rootViewController = nav
            }

        } else {
            let nav = NavigationController(rootViewController: vc)
            self.viewControllerWindow?.rootViewController = nav
        }
    }
    
    static func convertJSONString(results: [String: Any]) -> String {
        
        if let theJSONData = try?  JSONSerialization.data( withJSONObject: results, options: .prettyPrinted ),
          let theJSONText = String(data: theJSONData, encoding: String.Encoding.ascii) {
              print("JSON string = \n\(theJSONText)")
            return theJSONText.components(separatedBy: .newlines).joined();
        }
        return "{}"
    }
    
    func sendError(msg: String) {
        
        self.goNativeCallBack!([msg as Any, NSNull()])
    }
}

class NavigationController: UINavigationController {

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return getCurrentOrientation(isMask: true) as! UIInterfaceOrientationMask
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return getCurrentOrientation(isMask: false) as! UIInterfaceOrientation
    }
    
    func getCurrentOrientation(isMask: Bool) -> Any {
        let orientastion = ScanConfigs.accuraConfigs["app_orientation"] as! String
        if gl.type == "fm" || gl.type == "lv" {
            if isMask {
                return UIInterfaceOrientationMask.portrait
            } else {
                return UIInterfaceOrientation.portrait
            }
        }
        if(orientastion.contains("portrait")) {
            if isMask {
                return UIInterfaceOrientationMask.portrait
            } else {
                return UIInterfaceOrientation.portrait
            }
        } else {
            if isMask {
                return UIInterfaceOrientationMask.landscape
            } else {
                return UIInterfaceOrientation.landscapeRight
            }
        }
    }

}
