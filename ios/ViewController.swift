
import UIKit
import AVFoundation
import AccuraOCR
import AccuraLiveness_fm

//View controller for scanning document window.
class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var _viewLayer: UIView!
    @IBOutlet weak var _viewImageLayer: UIView!
    @IBOutlet weak var _imageView: UIImageView!
    @IBOutlet weak var _imgFlipView: UIImageView!
    @IBOutlet weak var _lblTitle: UILabel!
    @IBOutlet weak var _constant_height: NSLayoutConstraint!
    @IBOutlet weak var _constant_width: NSLayoutConstraint!
    
    @IBOutlet weak var AspectRatio: NSLayoutConstraint!
    @IBOutlet weak var lblOCRMsg: UILabel!
    @IBOutlet weak var lblTitleCountryName: UILabel!
    
    @IBOutlet weak var viewStatusBar: UIView!
    @IBOutlet weak var viewNavigationBar: UIView!
    var isCloseMe = false;
    var accuraCameraWrapper: AccuraCameraWrapper? = nil
    
    var isbothSideAvailable = false
    
    var shareScanningListing: NSMutableDictionary = [:]
    
    var documentImage: UIImage? = nil
    var docfrontImage: UIImage? = nil
    
    var frontImageRotation = ""
    var backImageRotation = ""
    
    var docName = "Document"
    var reactViewController:UIViewController? = nil
    var win: UIWindow? = nil
    //MARK:- Variable
    var cardid : Int = 0
    var countryid : Int = 0
    var imgViewCard : UIImage?
    var isCheckCard : Bool = false
    var isCheckCardMRZ : Bool = false
    var isCheckcardBack : Bool = false
    var isCheckCardBackFrint : Bool = false
    var isCheckScanOCR : Bool = false
    var arrCardSide : [String] = [String]()
    var isCardSide : Bool?
    var isBack : Bool?
    var isFront : Bool?
    var isConnection : Bool?
    var imgViewCardFront : UIImage?
    var dictSecuretyData : NSMutableDictionary = [:]
    var dictFaceDataFront: NSMutableDictionary = [:]
    var dictFaceDataBack: NSMutableDictionary = [:]
    var dictOCRTypeData:NSMutableDictionary = [:]
    var arrBackFrontImage : [UIImageView] = [UIImageView]()
    
    var stUrl : String?
    var arrimgCountData = [String]()
    var cardType: Int = 0
    var MRZDocType:Int = 0
    
    var arrImageName : [String] = [String]()
    
    var dictScanningData:NSDictionary = NSDictionary()
    
    var isflipanimation : Bool?
    
    var isChangeMRZ : Bool?
    var imgPhoto : UIImage?
    
    var isCheckFirstTime : Bool?
    var mrzElementName: String = ""
    var dictScanningMRZData: NSMutableDictionary = [:]
    var setImage : Bool?
    var isFrontDataComplate: Bool?
    var isBackDataComplate: Bool?
    var stCountryCardName: String?
    var cardImage: UIImage?
    var isBackSide: Bool?
    
    var arrFrontResultKey : [String] = []
    var arrFrontResultValue : [String] = []
    var arrBackResultKey : [String] = []
    var arrBackResultValue : [String] = []
    var isCheckMRZData: Bool?
    var secondCallData: Bool?
    
    var isFirstTimeStartCamara: Bool?
    var countface = 0
    var statusBarRect = CGRect()
    var bottomPadding:CGFloat = 0.0
    var topPadding: CGFloat = 0.0
    var callBack: RCTResponseSenderBlock? = nil
    var isBarCode = false
    var audioPath: URL? = nil
    
    var recogFace: UIImage?
    var recogFront: UIImage?
    var recogBack: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ScanConfigs.accuraMessagesConfigs.index(forKey: "IS_SHOW_LOGO") != nil {
            let isShow = ScanConfigs.accuraMessagesConfigs["IS_SHOW_LOGO"] as? Bool ?? true
            _viewImageLayer.isHidden = !isShow
        }
        // Do any additional setup after loading the view.
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        statusBarRect = UIApplication.shared.statusBarFrame
        let window = UIApplication.shared.windows.first
        
        if #available(iOS 11.0, *) {
            bottomPadding = window!.safeAreaInsets.bottom
            topPadding = window!.safeAreaInsets.top
        } else {
            // Fallback on earlier versions
        }
        shareScanningListing = [:]
        isFirstTimeStartCamara = false
        isCheckFirstTime = false
        viewStatusBar.backgroundColor = UIColor(red: 231.0 / 255.0, green: 52.0 / 255.0, blue: 74.0 / 255.0, alpha: 1.0)
        viewNavigationBar.backgroundColor = UIColor(red: 231.0 / 255.0, green: 52.0 / 255.0, blue: 74.0 / 255.0, alpha: 1.0)
        _imageView.layer.masksToBounds = false
        _imageView.clipsToBounds = true
        ChangedOrientation()
        width = UIScreen.main.bounds.size.width
        height = UIScreen.main.bounds.size.height
        width = width * 0.95
        height = height * 0.35
        //        _constant_width.constant = width
        //        _constant_height.constant = height
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        _viewLayer.layer.borderColor = UIColor.red.cgColor
        _viewLayer.layer.borderWidth = 3.0
        self._imgFlipView.isHidden = true
        if status == .authorized {
            isCheckFirstTime = true
            self.setOCRData()
            let shortTap = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:)))
            shortTap.numberOfTapsRequired = 1
            shortTap.numberOfTouchesRequired = 1
            self.view.addGestureRecognizer(shortTap)
        } else if status == .denied {
            let alert = UIAlertController(title: "AccuraSdk", message: "It looks like your privacy settings are preventing us from accessing your camera.", preferredStyle: .alert)
            let yesButton = UIAlertAction(title: "OK", style: .default) { _ in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
            alert.addAction(yesButton)
            self.present(alert, animated: true, completion: nil)
        } else if status == .restricted {
        } else if status == .notDetermined  {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.isCheckFirstTime = true
                    self.isFirstTimeStartCamara = true
                    DispatchQueue.main.async {
                        self._imageView.setNeedsLayout()
                        self._imageView.layoutSubviews()
                        self.setOCRData()
                        self.ChangedOrientation()
                        self.accuraCameraWrapper?.startCamera()
                    }
                    let shortTap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapToFocus(_:)))
                    shortTap.numberOfTapsRequired = 1
                    shortTap.numberOfTouchesRequired = 1
                } else {
                    // print("Not granted access")
                }
            }
        }
        if(isCheckCardMRZ) {
            
            let orientastion = UIApplication.shared.statusBarOrientation
           if(orientastion ==  UIInterfaceOrientation.portrait) {
               width = UIScreen.main.bounds.size.width * 0.95
               
               height  = (UIScreen.main.bounds.size.height - (self.bottomPadding + self.topPadding + self.statusBarRect.height)) * 0.35
           } else {
               height = UIScreen.main.bounds.size.height * 0.62
               width = UIScreen.main.bounds.size.width * 0.51
           }
            print("layer", width)
            DispatchQueue.main.async {
                self._constant_width.constant = width
                self._constant_height.constant = height
            }
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self._imageView.setNeedsLayout()
        self._imageView.layoutSubviews()
        self._imageView.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        EngineWrapper.faceEngineClose()
        countface = 0
        self.shareScanningListing.removeAllObjects()
        isBackSide = false
        isCheckMRZData = false
        recogFace = nil
        recogFront = nil
        recogBack = nil
        //         self.ChangedOrientation()
        if self.accuraCameraWrapper == nil {
            setOCRData()
        }
        
        if isFirstTimeStartCamara!{
            accuraCameraWrapper?.startCamera()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isFirstTimeStartCamara! && isCheckFirstTime!{
            isFirstTimeStartCamara = true
            accuraCameraWrapper?.startCamera()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !isFirstTimeStartCamara! && isCheckFirstTime!{
            
            isFirstTimeStartCamara = true
            accuraCameraWrapper?.startCamera()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        accuraCameraWrapper?.stopCamera()
        accuraCameraWrapper?.closeOCR()
        accuraCameraWrapper = nil
        _imageView.image = nil
        super.viewWillDisappear(animated)
    }
    
    @IBAction func backAction(_ sender: Any) {
        accuraCameraWrapper?.stopCamera()
        accuraCameraWrapper?.closeOCR()
        arrFrontResultKey.removeAll()
        arrBackResultKey.removeAll()
        arrFrontResultValue.removeAll()
        arrBackResultValue.removeAll()
        dictSecuretyData.removeAllObjects()
        dictFaceDataBack.removeAllObjects()
        dictFaceDataFront.removeAllObjects()
        dictScanningMRZData.removeAllObjects()
        self.win!.rootViewController = reactViewController!
        if (!isCloseMe) {
            callBack!(["User decline scanning of document" as Any, NSNull()])
        }
    }
    @IBAction func buttonFlipAction(_ sender: UIButton) {
        accuraCameraWrapper?.switchCamera()
    }
    func closeMe() {
        self.isCloseMe = true
        backAction("")
    }
    var selectedTypes: BarcodeType = .all
    func setSelectedTypes(types: String) {
        print("set selected")
        switch types
        {
        case "ALL FORMATS":
            self.selectedTypes = .all
        case "EAN-8":
            self.selectedTypes = .ean8
        case "EAN-13":
            self.selectedTypes = .ean13
        case "PDF417":
            self.selectedTypes = .pdf417
        case "AZTEC":
            self.selectedTypes = .aztec
        case "CODE 128":
            self.selectedTypes = .code128
        case "CODE 39":
            self.selectedTypes = .code39
        case "CODE 93":
            self.selectedTypes = .code93
        case "DATA MATRIX":
            self.selectedTypes = .dataMatrix
        case "ITF":
            self.selectedTypes = .itf
        case "QR CODE":
            self.selectedTypes = .qrcode
        case "UPC-E":
            self.selectedTypes = .upce
        case "UPC-A":
            self.selectedTypes = .upca
        case "CODABAR":
            self.selectedTypes = .codabar
        default:
            break
        }
    }
    
    var isBarcodeEnabled: Bool = false
    //MARK:- Other Method
    func setOCRData(){
        arrFrontResultKey.removeAll()
        arrBackResultKey.removeAll()
        arrFrontResultValue.removeAll()
        arrBackResultValue.removeAll()
        dictSecuretyData.removeAllObjects()
        dictFaceDataBack.removeAllObjects()
        dictFaceDataFront.removeAllObjects()
        dictScanningMRZData.removeAllObjects()
        isCheckCard = false
        isCheckcardBack = false
        isCheckCardBackFrint = false
        isflipanimation = false
        imgPhoto = nil
        isFrontDataComplate = false
        isBackDataComplate = false
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setBackSide") == nil) {
//            ScanConfigs.accuraConfigs["rg_setBackSide"] = true
        }
        
        if isBarCode {
            isBarcodeEnabled = true
//            if ScanConfigs.barcodeType == "PDF417" {
//                isBarcodeEnabled = false
//            }
            
            if cardType == 1 {
                isBarcodeEnabled = false
                selectedTypes = .all
            } else {
                setSelectedTypes(types: ScanConfigs.barcodeType!)
            }
            accuraCameraWrapper = AccuraCameraWrapper.init(delegate: self, andImageView: _imageView, andLabelMsg: self.lblOCRMsg, andurl: 1, isBarcodeEnable: self.isBarcodeEnabled, countryID: Int32(self.countryid), setBarcodeType: self.selectedTypes)
            
        } else {
            startOCRCamera()
            if (isNeedBackSideFirst()) {
                accuraCameraWrapper!.cardSide(.BACK_CARD_SCAN)
            } else {
                accuraCameraWrapper!.cardSide(.FRONT_CARD_SCAN)
            }
        }
        
        if (ScanConfigs.accuraConfigs.index(forKey: "enableLogs") != nil) {
            if let needLogs = ScanConfigs.accuraConfigs["enableLogs"] as? Bool {
                self.accuraCameraWrapper?.showLogFile(needLogs)
            }
        }
    }
    
    func startOCRCamera() {
        accuraCameraWrapper = AccuraCameraWrapper.init(delegate: self, andImageView: _imageView, andLabelMsg: lblOCRMsg, andurl: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String, cardId: Int32(cardid), countryID: Int32(countryid), isScanOCR: isCheckScanOCR, andcardName: docName, andcardType: Int32(cardType), andMRZDocType: Int32(MRZDocType))
        
//        if (isCheckCardMRZ) {
//            accuraCameraWrapper?.setMRZCountryCodeList(ScanConfigs.mrzCountryList)
//            self.accuraCameraWrapper?.setMRZCountryCodeList(ScanConfigs.mrzCountryList)
//        }
        accuraCameraWrapper?.setMinFrameForValidate(5)
        self.accuraCameraWrapper?.setBlurPercentage(EnginConfigs.rg_setBlurPercentage)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setBlurPercentage") != nil) {
            self.accuraCameraWrapper?.setBlurPercentage(ScanConfigs.accuraConfigs["rg_setBlurPercentage"] as! Int32)
        }
        
        self.accuraCameraWrapper?.setFaceBlurPercentage(EnginConfigs.rg_setFaceBlurPercentage)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setFaceBlurPercentage") != nil) {
            self.accuraCameraWrapper?.setFaceBlurPercentage(ScanConfigs.accuraConfigs["rg_setFaceBlurPercentage"] as! Int32)
        }
        
        self.accuraCameraWrapper?.setFaceBlurPercentage(EnginConfigs.rg_setFaceBlurPercentage)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setFaceBlurPercentage") != nil) {
            self.accuraCameraWrapper?.setFaceBlurPercentage(ScanConfigs.accuraConfigs["rg_setFaceBlurPercentage"] as! Int32)
        }
        var gl_0 = EnginConfigs.rg_setGlarePercentage_0
        var gl_1 = EnginConfigs.rg_setGlarePercentage_1
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setGlarePercentage_0") != nil) {
            gl_0 = ScanConfigs.accuraConfigs["rg_setGlarePercentage_0"] as! Int32
        }
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setGlarePercentage_1") != nil) {
            gl_1 = ScanConfigs.accuraConfigs["rg_setGlarePercentage_1"] as! Int32
        }
        self.accuraCameraWrapper?.setGlarePercentage(gl_0, intMax: gl_1)
        
        self.accuraCameraWrapper?.setCheckPhotoCopy(EnginConfigs.rg_isCheckPhotoCopy)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_isCheckPhotoCopy") != nil) {
            self.accuraCameraWrapper?.setCheckPhotoCopy(ScanConfigs.accuraConfigs["rg_isCheckPhotoCopy"] as! Bool)
        }
        
        self.accuraCameraWrapper?.setHologramDetection(EnginConfigs.rg_SetHologramDetection)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_SetHologramDetection") != nil) {
            self.accuraCameraWrapper?.setCheckPhotoCopy(ScanConfigs.accuraConfigs["rg_SetHologramDetection"] as! Bool)
        }
        
        self.accuraCameraWrapper?.setLowLightTolerance(EnginConfigs.rg_setLowLightTolerance)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setLowLightTolerance") != nil) {
            self.accuraCameraWrapper?.setLowLightTolerance(ScanConfigs.accuraConfigs["rg_setLowLightTolerance"] as! Int32)
        }
        
        self.accuraCameraWrapper?.setMotionThreshold(EnginConfigs.rg_setMotionThreshold)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setMotionThreshold") != nil) {
            self.accuraCameraWrapper?.setMotionThreshold(ScanConfigs.accuraConfigs["rg_setMotionThreshold"] as! Int32)
        }
        

        
        self.accuraCameraWrapper?.setMotionThreshold(EnginConfigs.rg_setMotionThreshold)
        if (ScanConfigs.accuraConfigs.index(forKey: "rg_setMotionThreshold") != nil) {
            self.accuraCameraWrapper?.setMotionThreshold(ScanConfigs.accuraConfigs["rg_setMotionThreshold"] as! Int32)
        }
    }

    @objc private func ChangedOrientation() {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        
        let orientastion = ScanConfigs.accuraConfigs["app_orientation"] as! String
        if(orientastion.contains("portrait")) {
            width = UIScreen.main.bounds.size.width * 0.95
            
            height  = (UIScreen.main.bounds.size.height - (self.bottomPadding + self.topPadding + self.statusBarRect.height)) * 0.35
            viewNavigationBar.backgroundColor = UIColor(red: 231.0 / 255.0, green: 52.0 / 255.0, blue: 74.0 / 255.0, alpha: 1.0)
        } else {
            self.viewNavigationBar.backgroundColor = .clear
            height = UIScreen.main.bounds.size.height * 0.62
            width = UIScreen.main.bounds.size.width * 0.51
        }
        
        _constant_width.constant = width
        if(self.cardType == 2) {
            self._constant_height.constant = height / 2
        } else {
            self._constant_height.constant = height
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }) { _ in
                
            }
        }
    }
    
    @objc func handleTapToFocus(_ tapGesture: UITapGestureRecognizer?) {
        let acd = AVCaptureDevice.default(for: .video)
        if tapGesture!.state == .ended {
            let thisFocusPoint = tapGesture!.location(in: _viewLayer)
            let focus_x = Double(thisFocusPoint.x / _viewLayer.frame.size.width)
            let focus_y = Double(thisFocusPoint.y / _viewLayer.frame.size.height)
            if acd?.isFocusModeSupported(.autoFocus) ?? false && acd?.isFocusPointOfInterestSupported != nil {
                do {
                    try acd?.lockForConfiguration()
                    
                    if try acd?.lockForConfiguration() != nil {
                        acd?.focusMode = .autoFocus
                        acd?.focusPointOfInterest = CGPoint(x: CGFloat(focus_x), y: CGFloat(focus_y))
                        acd?.unlockForConfiguration()
                    }
                } catch {
                }
            }
        }
    }
    
    func flipAnimation() {
        self._imgFlipView.isHidden = false
        UIView.animate(withDuration: 1.5, animations: { [self] in
            UIView.setAnimationTransition(.flipFromLeft, for: self._imgFlipView, cache: true)
            playSound()
        }) { _ in
            self._imgFlipView.isHidden = true
        }
    }
    var mutableArray: NSMutableArray = []
    var keyArr: NSMutableArray = []
    var valueArr: NSMutableArray = []
    func decodework (type: String) -> Bool {
        keyArr.removeAllObjects()
        valueArr.removeAllObjects()
        let Customer_Family_Name = "DCS"
        let Family_Name = "DAB"
        
        let Customer_Given_Name =  "DCT"
        let Name_Suffix = "DCU"
        let Street_Address_1 = "DAG"
        let City = "DAI"
        let Jurisdction_Code = "DAJ"
        let ResidenceJurisdictionCode = "DAO"
        let MedicalIndicatorCodes = "DBG"
        let NonResidentIndicator = "DBI"
        let  SocialSecurityNumber = "DBK"
        let  DateOfBirth = "DBL"
        
        let Postal_Code = "DAK"
        let Customer_Id_Number = "DAQ"
        let Expiration_Date = "DBA"
        let Sex = "DBC"
        let Customer_Full_Name = "DAA"
        let Customer_First_Name = "DAC"
        let Customer_Middle_Name = "DAD"
        let Street_Address_2 = "DAH"
        let Street_Address_1_optional = "DAL"
        let Street_Address_2_optional = "DAM"
        let Date_Of_Birth = "DBB"
        let  NameSuff = "DAE"
        let  NamePref = "DAF"
        let LicenseClassification = "DAR"
        let  LicenseRestriction = "DAS"
        let LicenseEndorsement = "DAT"
        let  IssueDate = "DBD"
        let OrganDonor = "DBH"
        let HeightFT = "DAU"
        let  FullName = "DAA"
        let  GivenName = "DAC"
        let HeightCM = "DAV"
        let WeightLBS = "DAW"
        let WeightKG = "DAX"
        let EyeColor = "DAY"
        let HairColor = "DAZ"
        let IssueTimeStemp = "DBE"
        let NumberDuplicate = "DBF"
        let UniqueCustomerId = "DBJ"
        let SocialSecurityNo = "DBM"
        let Under18 = "DDH"
        let Under19 = "DDI"
        let Under21 = "DDJ"
        let PermitClassification = "PAA"
        let VeteranIndicator = "DDL"
        let  PermitIssue = "PAD"
        let PermitExpire = "PAB"
        let PermitRestriction = "PAE"
        let PermitEndorsement = "PAF"
        let CourtRestriction = "ZVA"
        let InventoryControlNo = "DCK"
        let  RaceEthnicity = "DCL"
        let StandardVehicleClass = "DCM"
        let DocumentDiscriminator = "DCF"
        let VirginiaSpecificClass = "DCA"
        let VirginiaSpecificRestrictions = "DCB"
        let PhysicalDescriptionWeight =  "DCD"
        let CountryTerritoryOfIssuance = "DCG"
        let FederalCommercialVehicleCodes = "DCH"
        let  PlaceOfBirth =  "DCI"
        let AuditInformation = "DCJ"
        let StandardEndorsementCode = "DCN"
        let StandardRestrictionCode = "DCO"
        let JurisdictionSpecificVehicleClassificationDescription = "DCP"
        let  JurisdictionSpecific = "DCQ"
        let JurisdictionSpecificRestrictionCodeDescription = "DCR"
        let  ComplianceType = "DDA"
        let CardRevisionDate = "DDB"
        let  HazMatEndorsementExpiryDate = "DDC"
        let  LimitedDurationDocumentIndicator = "DDD"
        let FamilyNameTruncation = "DDE"
        let   FirstNamesTruncation = "DDF"
        let MiddleNamesTruncation = "DDG"
        let OrganDonorIndicator =  "DDK"
        let  PermitIdentifier = "PAC"
        
        
        mutableArray.add(Customer_Full_Name)
        mutableArray.add(Customer_Family_Name)
        mutableArray.add(Family_Name)
        
        mutableArray.add(Customer_Given_Name)
        mutableArray.add(Name_Suffix)
        mutableArray.add(Street_Address_1)
        mutableArray.add(City)
        mutableArray.add(Jurisdction_Code)
        mutableArray.add(ResidenceJurisdictionCode)
        mutableArray.add(MedicalIndicatorCodes)
        mutableArray.add(NonResidentIndicator)
        mutableArray.add(SocialSecurityNumber)
        mutableArray.add(DateOfBirth)
        mutableArray.add(VirginiaSpecificClass)
        mutableArray.add(VirginiaSpecificRestrictions)
        mutableArray.add(PhysicalDescriptionWeight)
        mutableArray.add(CountryTerritoryOfIssuance)
        mutableArray.add(FederalCommercialVehicleCodes)
        mutableArray.add(PlaceOfBirth)
        mutableArray.add(AuditInformation)
        mutableArray.add(StandardEndorsementCode)
        mutableArray.add(JurisdictionSpecificVehicleClassificationDescription)
        mutableArray.add(JurisdictionSpecific)
        mutableArray.add(PermitIdentifier)
        mutableArray.add(OrganDonorIndicator)
        mutableArray.add(MiddleNamesTruncation)
        mutableArray.add(FirstNamesTruncation)
        mutableArray.add(FamilyNameTruncation)
        mutableArray.add(HazMatEndorsementExpiryDate)
        mutableArray.add(LimitedDurationDocumentIndicator)
        mutableArray.add(CardRevisionDate)
        mutableArray.add(ComplianceType)
        mutableArray.add(JurisdictionSpecificRestrictionCodeDescription)
        mutableArray.add(StandardRestrictionCode)
        
        mutableArray.add(Postal_Code)
        mutableArray.add(Customer_Id_Number)
        mutableArray.add(Expiration_Date)
        mutableArray.add(Sex)
        mutableArray.add(Customer_First_Name)
        mutableArray.add(Customer_Middle_Name)
        mutableArray.add(Street_Address_2)
        mutableArray.add(Street_Address_1_optional)
        mutableArray.add(Street_Address_2_optional)
        mutableArray.add(Date_Of_Birth)
        mutableArray.add(NameSuff)
        mutableArray.add(NamePref)
        mutableArray.add(LicenseClassification)
        mutableArray.add(LicenseRestriction)
        mutableArray.add(LicenseEndorsement)
        mutableArray.add(IssueDate)
        mutableArray.add(OrganDonor)
        mutableArray.add(HeightFT)
        mutableArray.add(FullName)
        mutableArray.add(GivenName)
        mutableArray.add(HeightCM)
        mutableArray.add(WeightLBS)
        mutableArray.add(WeightKG)
        mutableArray.add(EyeColor)
        mutableArray.add(HairColor)
        mutableArray.add(IssueTimeStemp)
        mutableArray.add(NumberDuplicate)
        mutableArray.add(UniqueCustomerId)
        mutableArray.add(SocialSecurityNo)
        mutableArray.add(Under18)
        mutableArray.add(Under19)
        mutableArray.add(Under21)
        mutableArray.add(PermitClassification)
        mutableArray.add(VeteranIndicator)
        mutableArray.add(PermitIssue)
        mutableArray.add(PermitExpire)
        mutableArray.add(PermitRestriction)
        mutableArray.add(PermitEndorsement)
        mutableArray.add(CourtRestriction)
        mutableArray.add(InventoryControlNo)
        mutableArray.add(RaceEthnicity)
        mutableArray.add(StandardVehicleClass)
        mutableArray.add(DocumentDiscriminator)
        
        var emptyDictionary = [String: String]()
        var passDict = [String: String]()
        
        let fullstrArr = type.components(separatedBy: "\n")
        for object in fullstrArr {
            var str = object as String
            if str.contains("ANSI")  {
                let parts = str.components(separatedBy: "DL")
                if parts.count > 1 {
                    str = parts[parts.count-1]
                }
                
                
            }
            let count = str.count
            
            if count > 3 {
                (str as NSString).substring(with: NSRange(location: 0, length: 3))
                let key  = str.index(str.startIndex, offsetBy:3)
                let key1 = String(str[..<key])
                
                let indexsd = str.index(str.startIndex, offsetBy: 3)
                let tempstr = str[indexsd...]  // "Hello>>>"
                if (tempstr != "NONE") {
                    emptyDictionary.updateValue(String(tempstr), forKey: key1)
                    
                }
                
            }
        }
        if((emptyDictionary["DAA"]) != nil) {
            passDict.updateValue(emptyDictionary["DAA"]!, forKey: "FULL NAME: ")
            if(keyArr .contains("FULL NAME: ")) {
            }
            else {
                valueArr.add(emptyDictionary["DAA"]!)
                keyArr.add("FULL NAME: ")
            }
        }
        
        if((emptyDictionary["DAB"]) != nil) {
            passDict.updateValue(emptyDictionary["DAB"]!, forKey: "LAST NAME:")
            if(keyArr .contains("LAST NAME:")) {
            }
            else {
                valueArr.add(emptyDictionary["DAB"]!)
                keyArr.add("LAST NAME:")
            }
            
            
        }
        
        if((emptyDictionary["DAC"]) != nil) {
            passDict.updateValue(emptyDictionary["DAC"]!, forKey: "FIRST NAME:")
            if(keyArr .contains("FIRST NAME: ") ) {
                
            }
            else {
                valueArr.add(emptyDictionary["DAC"]!)
                keyArr.add("FIRST NAME: ")
            }
            
            
        }
        
        
        if((emptyDictionary["DAD"]) != nil) {
            passDict.updateValue(emptyDictionary["DAD"]!, forKey: "MIDDLE NAME:")
            if(keyArr .contains("MIDDLE NAME:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAD"]!)
                keyArr.add("MIDDLE NAME:")
            }
            
            
        }
        
        if((emptyDictionary["DAE"]) != nil) {
            passDict.updateValue(emptyDictionary["DAE"]!, forKey: "NAME SUFFIX: ")
            if(keyArr .contains("NAME SUFFIX: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAE"]!)
                keyArr.add("NAME SUFFIX: ")
            }
        }
        
        if((emptyDictionary["DAF"]) != nil) {
            passDict.updateValue(emptyDictionary["DAF"]!, forKey: "NAME PREFIX: ")
            if(keyArr .contains("NAME PREFIX: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAF"]!)
                keyArr.add("NAME PREFIX: ")
            }
        }
        
        if((emptyDictionary["DAG"]) != nil) {
            passDict.updateValue(emptyDictionary["DAG"]!, forKey: "MAILING STREET ADDRESS1: ")
            if(keyArr .contains("MAILING STREET ADDRESS1: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAG"]!)
                keyArr.add("MAILING STREET ADDRESS1: ")
            }
            
        }
        
        if((emptyDictionary["DAH"]) != nil) {
            passDict.updateValue(emptyDictionary["DAH"]!, forKey: "MAILING STREET ADDRESS2: ")
            if(keyArr .contains("MAILING STREET ADDRESS2: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAH"]!)
                keyArr.add("MAILING STREET ADDRESS2: ")
            }
        }
        
        if((emptyDictionary["DAI"]) != nil) {
            passDict.updateValue(emptyDictionary["DAI"]!, forKey: "MAILING CITY:")
            if(keyArr .contains("MAILING CITY:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAI"]!)
                keyArr.add("MAILING CITY:")
            }
            
        }
        
        
        if((emptyDictionary["DAJ"]) != nil) {
            passDict.updateValue(emptyDictionary["DAJ"]!, forKey: "MAILING JURISDICTION CODE: ")
            if(keyArr .contains("MAILING JURISDICTION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAJ"]!)
                keyArr.add("MAILING JURISDICTION CODE: ")
            }
            
        }
        
        if((emptyDictionary["DAK"]) != nil) {
            passDict.updateValue(emptyDictionary["DAK"]!, forKey: "MAILING POSTAL CODE:")
            if(keyArr .contains("MAILING POSTAL CODE:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAK"]!)
                keyArr.add("MAILING POSTAL CODE: ")
            }
            
            
        }
        
        if((emptyDictionary["DAL"]) != nil) {
            passDict.updateValue(emptyDictionary["DAL"]!, forKey: "RESIDENCE STREET ADDRESS1: ")
            if(keyArr .contains("RESIDENCE STREET ADDRESS1: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAL"]!)
                keyArr.add("RESIDENCE STREET ADDRESS1: ")
            }
        }
        
        if((emptyDictionary["DAM"]) != nil) {
            passDict.updateValue(emptyDictionary["DAM"]!, forKey: "RESIDENCE STREET ADDRESS2: ")
            if(keyArr .contains("RESIDENCE STREET ADDRESS2: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAM"]!)
                keyArr.add("RESIDENCE STREET ADDRESS2: ")
            }
        }
        
        if((emptyDictionary["DAN"]) != nil) {
            passDict.updateValue(emptyDictionary["DAN"]!, forKey: "RESIDENCE CITY: ")
            if(keyArr .contains("RESIDENCE CITY: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAN"]!)
                keyArr.add("RESIDENCE CITY: ")
            }
        }
        
        if((emptyDictionary["DAO"]) != nil) {
            passDict.updateValue(emptyDictionary["DAO"]!, forKey: "RESIDENCE JURISDICTION CODE: ")
            if(keyArr .contains("RESIDENCE JURISDICTION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAO"]!)
                keyArr.add("RESIDENCE JURISDICTION CODE: ")
            }
            
        }
        
        if((emptyDictionary["DAP"]) != nil) {
            passDict.updateValue(emptyDictionary["DAP"]!, forKey: "RESIDENCE POSTAL CODE: ")
            if(keyArr .contains("RESIDENCE POSTAL CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAP"]!)
                keyArr.add("RESIDENCE POSTAL CODE: ")
            }
            
        }
        
        if((emptyDictionary["DAQ"]) != nil) {
            passDict.updateValue(emptyDictionary["DAQ"]!, forKey: "LICENCE OR ID NUMBER: ")
            if(keyArr .contains("LICENCE OR ID NUMBER: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAQ"]!)
                keyArr.add("LICENCE OR ID NUMBER: ")
            }
        }
        
        if((emptyDictionary["DAR"]) != nil) {
            passDict.updateValue(emptyDictionary["DAR"]!, forKey: "LICENCE CLASSIFICATION CODE: ")
            if(keyArr .contains("LICENCE CLASSIFICATION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAR"]!)
                keyArr.add("LICENCE CLASSIFICATION CODE: ")
            }
        }
        
        if((emptyDictionary["DAS"]) != nil) {
            passDict.updateValue(emptyDictionary["DAS"]!, forKey: "LICENCE RESTRICTION CODE: ")
            if(keyArr .contains("LICENCE RESTRICTION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAS"]!)
                keyArr.add("LICENCE RESTRICTION CODE: ")
            }
        }
        
        if((emptyDictionary["DAT"]) != nil) {
            passDict.updateValue(emptyDictionary["DAT"]!, forKey: "LICENCE ENDORSEMENT CODE: ")
            if(keyArr .contains("LICENCE ENDORSEMENT CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAT"]!)
                keyArr.add("LICENCE ENDORSEMENT CODE: ")
            }
        }
        
        if((emptyDictionary["DAU"]) != nil) {
            passDict.updateValue(emptyDictionary["DAU"]!, forKey: "HEIGHT IN FT_IN: ")
            if(keyArr .contains("HEIGHT IN FT_IN: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAU"]!)
                keyArr.add("HEIGHT IN FT_IN:")
            }
        }
        
        if((emptyDictionary["DAV"]) != nil) {
            passDict.updateValue(emptyDictionary["DAV"]!, forKey: "HEIGHT IN CM: ")
            if(keyArr .contains("HEIGHT IN CM: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAV"]!)
                keyArr.add("HEIGHT IN CM: ")
            }
        }
        
        if((emptyDictionary["DAW"]) != nil) {
            passDict.updateValue(emptyDictionary["DAW"]!, forKey: "WEIGHT IN LBS: ")
            if(keyArr .contains("WEIGHT IN LBS: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAW"]!)
                keyArr.add("WEIGHT IN LBS: ")
            }
            
            
        }
        
        if((emptyDictionary["DAX"]) != nil) {
            passDict.updateValue(emptyDictionary["DAX"]!, forKey: "WEIGHT IN KG:")
            if(keyArr .contains("WEIGHT IN KG:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAX"]!)
                keyArr.add("WEIGHT IN KG:")
            }
        }
        
        if((emptyDictionary["DAY"]) != nil) {
            passDict.updateValue(emptyDictionary["DAY"]!, forKey: "EYE COLOR: ")
            if(keyArr .contains("EYE COLOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAY"]!)
                keyArr.add("EYE COLOR:")
            }
            
        }
        
        if((emptyDictionary["DAZ"]) != nil) {
            passDict.updateValue(emptyDictionary["DAZ"]!, forKey: "HAIR COLOR: ")
            if(keyArr .contains("HAIR COLOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DAZ"]!)
                keyArr.add("HAIR COLOR:")
            }
            
            
            
        }
        
        if((emptyDictionary["DBA"]) != nil) {
            passDict.updateValue(emptyDictionary["DBA"]!, forKey: "LICENSE EXPIRATION DATE: ")
            if(keyArr .contains("LICENSE EXPIRATION DATE: ")) {
            }
            else {
                
                var  str = emptyDictionary["DBA"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                keyArr.add("LICENSE EXPIRATION DATE: ")
            }
        }
        if((emptyDictionary["DBB"]) != nil) {
            passDict.updateValue(emptyDictionary["DBB"]!, forKey:  "DATE OF BIRTH: ")
            if(keyArr .contains("DATE OF BIRTH: ")) {
            }
            else {
                var  str = emptyDictionary["DBB"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                keyArr.add("DATE OF BIRTH:")
            }
            
            
            
        }
        
        if((emptyDictionary["DBC"]) != nil) {
            passDict.updateValue(emptyDictionary["DBC"]!, forKey: "SEX: ")
            if(keyArr .contains("SEX: ")) {
            }
            else {
                if(emptyDictionary["DBC"] == "1") {
                    
                    valueArr.add("MALE")
                }
                else  {
                    valueArr.add("FEMALE")
                }
                
                keyArr.add("SEX: ")
            }
            
            
            
        }
        
        if((emptyDictionary["DBD"]) != nil) {
            passDict.updateValue(emptyDictionary["DBD"]!, forKey: "LICENSE OR ID DOCUMENT ISSUE DATE: ")
            if(keyArr .contains("LICENSE OR ID DOCUMENT ISSUE DATE: ")) {
            }
            else {
                
                var  str = emptyDictionary["DBD"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                keyArr.add("LICENSE OR ID DOCUMENT ISSUE DATE: ")
            }
        }
        
        if((emptyDictionary["DBE"]) != nil) {
            passDict.updateValue(emptyDictionary["DBE"]!, forKey:  "ISSUE TIMESTAMP: ")
            if(keyArr .contains("ISSUE TIMESTAMP: ")) {
            }
            else {
                valueArr.add(emptyDictionary["DBE"]!)
                keyArr.add("ISSUE TIMESTAMP:")
            }
        }
        
        if((emptyDictionary["DBF"]) != nil) {
            passDict.updateValue(emptyDictionary["DBF"]!, forKey: "NUMBER OF DUPLICATES: ")
            if(keyArr .contains("NUMBER OF DUPLICATES: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBF"]!)
                keyArr.add("NUMBER OF DUPLICATES: ")
            }
            
        }
        
        if((emptyDictionary["DBG"]) != nil) {
            passDict.updateValue(emptyDictionary["DBG"]!, forKey: "RMEDICAL INDICATOR CODES: ")
            if(keyArr .contains("MEDICAL INDICATOR CODES: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBG"]!)
                keyArr.add("MEDICAL INDICATOR CODES: ")
            }
            
        }
        
        if((emptyDictionary["DBH"]) != nil) {
            passDict.updateValue(emptyDictionary["DBH"]!, forKey: "ORGAN DONOR: ")
            if(keyArr .contains("ORGAN DONOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBH"]!)
                keyArr.add("ORGAN DONOR: ")
            }
        }
        
        if((emptyDictionary["DBI"]) != nil) {
            passDict.updateValue(emptyDictionary["DBI"]!, forKey: "NON-RESIDENT INDICATOR: ")
            if(keyArr .contains("NON-RESIDENT INDICATOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBI"]!)
                keyArr.add("NON-RESIDENT INDICATOR: ")
            }
            
        }
        
        if((emptyDictionary["DBJ"]) != nil) {
            passDict.updateValue(emptyDictionary["DBJ"]!, forKey: "UNIQUE CUSTOMER IDENTIFIER: ")
            if(keyArr .contains("UNIQUE CUSTOMER IDENTIFIER: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBJ"]!)
                keyArr.add("UNIQUE CUSTOMER IDENTIFIER: ")
            }
        }
        
        if((emptyDictionary["DBK"]) != nil) {
            passDict.updateValue(emptyDictionary["DBK"]!, forKey: "SOCIAL SECURITY NUMBER: ")
            if(keyArr .contains("SOCIAL SECURITY NUMBER: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBK"]!)
                keyArr.add("SOCIAL SECURITY NUMBER: ")
            }
            
        }
        if((emptyDictionary["DBL"]) != nil) {
            passDict.updateValue(emptyDictionary["DBL"]!, forKey: "DATE OF BIRTH: ")
            if(keyArr .contains("DATE OF BIRTH: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBL"]!)
                keyArr.add("DATE OF BIRTH: ")
            }
        }
        
        if((emptyDictionary["DBM"]) != nil) {
            passDict.updateValue(emptyDictionary["DBM"]!, forKey: "SOCIAL SECURITY NUMBER: ")
            if(keyArr .contains("SOCIAL SECURITY NUMBER: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBM"]!)
                keyArr.add("SOCIAL SECURITY NUMBER: ")
            }
        }
        
        if((emptyDictionary["DBN"]) != nil) {
            passDict.updateValue(emptyDictionary["DBN"]!, forKey: "FULL NAME: ")
            if(keyArr .contains("FULL NAME: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBN"]!)
                keyArr.add("FULL NAME: ")
            }
        }
        
        if((emptyDictionary["DBO"]) != nil) {
            passDict.updateValue(emptyDictionary["DBO"]!, forKey: "LAST NAME: ")
            if(keyArr .contains("LAST NAME: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBO"]!)
                keyArr.add("LAST NAME: ")
            }
        }
        
        if((emptyDictionary["DBP"]) != nil) {
            passDict.updateValue(emptyDictionary["DBP"]!, forKey: "FIRST NAME: ")
            if(keyArr .contains("FIRST NAME: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBP"]!)
                keyArr.add("FIRST NAME: ")
            }
        }
        
        if((emptyDictionary["DBQ"]) != nil) {
            passDict.updateValue(emptyDictionary["DBQ"]!, forKey: "MIDDLE NAME: ")
            if(keyArr .contains("MIDDLE NAME: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBQ"]!)
                keyArr.add("MIDDLE NAME: ")
            }
            
        }
        
        if((emptyDictionary["DBR"]) != nil) {
            passDict.updateValue(emptyDictionary["DBR"]!, forKey: "SUFFIX: ")
            if(keyArr .contains("SUFFIX: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBR"]!)
                keyArr.add("SUFFIX: ")
            }
            
        }
        
        if((emptyDictionary["DBS"]) != nil) {
            passDict.updateValue(emptyDictionary["DBS"]!, forKey: "PREFIX: ")
            if(keyArr .contains("PREFIX: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DBS"]!)
                keyArr.add("PREFIX: ")
            }
            
        }
        
        if((emptyDictionary["DCA"]) != nil) {
            passDict.updateValue(emptyDictionary["DCA"]!, forKey: "VIRGINIA SPECIFIC CLASS: ")
            if(keyArr .contains("VIRGINIA SPECIFIC CLASS: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCA"]!)
                keyArr.add("VIRGINIA SPECIFIC CLASS: ")
            }
        }
        
        if((emptyDictionary["DCB"]) != nil) {
            passDict.updateValue(emptyDictionary["DCB"]!, forKey: "VIRGINIA SPECIFIC RESTRICTIONS: ")
            if(keyArr .contains("VIRGINIA SPECIFIC RESTRICTIONS: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCB"]!)
                keyArr.add("VIRGINIA SPECIFIC RESTRICTIONS: ")
            }
        }
        
        if((emptyDictionary["DCD"]) != nil) {
            passDict.updateValue(emptyDictionary["DCD"]!, forKey: "VIRGINIA SPECIFIC ENDORSEMENTS: ")
            if(keyArr .contains("VIRGINIA SPECIFIC ENDORSEMENTS: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCD"]!)
                keyArr.add("VIRGINIA SPECIFIC ENDORSEMENTS: ")
            }
        }
        
        if((emptyDictionary["DCE"]) != nil) {
            passDict.updateValue(emptyDictionary["DCE"]!, forKey: "PHYSICAL DESCRIPTION WEIGHT RANGE: ")
            if(keyArr .contains("PHYSICAL DESCRIPTION WEIGHT RANGE: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCE"]!)
                keyArr.add("PHYSICAL DESCRIPTION WEIGHT RANGE: ")
            }
        }
        
        if((emptyDictionary["DCF"]) != nil) {
            passDict.updateValue(emptyDictionary["DCF"]!, forKey: "DOCUMENT DISCRIMINATOR: ")
            if(keyArr .contains("DOCUMENT DISCRIMINATOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCF"]!)
                keyArr.add("DOCUMENT DISCRIMINATOR: ")
            }
            
            
        }
        
        if((emptyDictionary["DCG"]) != nil) {
            passDict.updateValue(emptyDictionary["DCG"]!, forKey: "COUNTRY TERRITORY OF ISSUANCE: ")
            if(keyArr .contains("COUNTRY TERRITORY OF ISSUANCE: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCG"]!)
                keyArr.add("COUNTRY TERRITORY OF ISSUANCE: ")
            }
        }
        
        if((emptyDictionary["DCH"]) != nil) {
            passDict.updateValue(emptyDictionary["DCH"]!, forKey: "FEDERAL COMMERCIAL VEHICLE CODES: ")
            if(keyArr .contains("FEDERAL COMMERCIAL VEHICLE CODES: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCH"]!)
                keyArr.add("FEDERAL COMMERCIAL VEHICLE CODES: ")
            }
        }
        
        if((emptyDictionary["DCI"]) != nil) {
            passDict.updateValue(emptyDictionary["DCI"]!, forKey: "PLACE OF BIRTH: ")
            if(keyArr .contains("PLACE OF BIRTH: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCI"]!)
                keyArr.add("PLACE OF BIRTH: ")
            }
        }
        
        if((emptyDictionary["DCJ"]) != nil) {
            passDict.updateValue(emptyDictionary["DCJ"]!, forKey: "AUDIT INFORMATION: ")
            if(keyArr .contains("AUDIT INFORMATION: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCJ"]!)
                keyArr.add("AUDIT INFORMATION: ")
            }
        }
        
        if((emptyDictionary["DCK"]) != nil) {
            passDict.updateValue(emptyDictionary["DCK"]!, forKey: "INVENTORY CONTROL NUMBER: ")
            if(keyArr .contains("INVENTORY CONTROL NUMBER: ")) {
            }
            else {
                valueArr.add(emptyDictionary["DCK"]!)
                keyArr.add("INVENTORY CONTROL NUMBER: ")
            }
            
            
        }
        
        if((emptyDictionary["DCL"]) != nil) {
            passDict.updateValue(emptyDictionary["DCL"]!, forKey: "RACE ETHNICITY: ")
            if(keyArr .contains("RACE ETHNICITY: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCL"]!)
                keyArr.add("RACE ETHNICITY: ")
            }
            
            
        }
        
        if((emptyDictionary["DCM"]) != nil) {
            passDict.updateValue(emptyDictionary["DCM"]!, forKey: "STANDARD VEHICLE CLASSIFICATION: ")
            if(keyArr .contains("STANDARD VEHICLE CLASSIFICATION: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCM"]!)
                keyArr.add("STANDARD VEHICLE CLASSIFICATION: ")
            }
            
            
        }
        
        if((emptyDictionary["DCN"]) != nil) {
            passDict.updateValue(emptyDictionary["DCN"]!, forKey: "STANDARD ENDORSEMENT CODE: ")
            if(keyArr .contains("STANDARD ENDORSEMENT CODE: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCN"]!)
                keyArr.add("STANDARD ENDORSEMENT CODE: ")
            }
        }
        
        if((emptyDictionary["DCO"]) != nil) {
            passDict.updateValue(emptyDictionary["DCO"]!, forKey: "STANDARD RESTRICTION CODE: ")
            if(keyArr .contains("STANDARD RESTRICTION CODE: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCO"]!)
                keyArr.add("STANDARD RESTRICTION CODE: ")
            }
        }
        
        if((emptyDictionary["DCP"]) != nil) {
            passDict.updateValue(emptyDictionary["DCP"]!, forKey: "JURISDICTION SPECIFIC VEHICLE CLASSIFICATION DESCRIPTION:  ")
            if(keyArr .contains("JURISDICTION SPECIFIC VEHICLE CLASSIFICATION DESCRIPTION: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCP"]!)
                keyArr.add("JURISDICTION SPECIFIC VEHICLE CLASSIFICATION DESCRIPTION: ")
            }
        }
        
        if((emptyDictionary["DCQ"]) != nil) {
            passDict.updateValue(emptyDictionary["DCQ"]!, forKey: "JURISDICTION-SPECIFIC: ")
            if(keyArr .contains("JURISDICTION-SPECIFIC: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCQ"]!)
                keyArr.add("JURISDICTION-SPECIFIC: ")
            }
        }
        
        if((emptyDictionary["DCR"]) != nil) {
            passDict.updateValue(emptyDictionary["DCR"]!, forKey: "JURISDICTION SPECIFIC RESTRICTION CODE DESCRIPTION: ")
            if(keyArr .contains("JURISDICTION SPECIFIC RESTRICTION CODE DESCRIPTION: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DCR"]!)
                keyArr.add("JURISDICTION SPECIFIC RESTRICTION CODE DESCRIPTION: ")
            }
        }
        
        if((emptyDictionary["DCS"]) != nil) {
            passDict.updateValue(emptyDictionary["DCS"]!, forKey: "FAMILY NAME:")
            if(keyArr .contains("FAMILY NAME:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCS"]!)
                keyArr.add("FAMILY NAME:")
            }
            
            
        }
        
        if((emptyDictionary["DCT"]) != nil) {
            passDict.updateValue(emptyDictionary["DCT"]!, forKey: "GIVEN NAME:")
            if(keyArr .contains("GIVEN NAME:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCT"]!)
                keyArr.add("GIVEN NAME:")
            }
            
            
        }
        
        if((emptyDictionary["DCU"]) != nil) {
            passDict.updateValue(emptyDictionary["DCU"]!, forKey: "SUFFIX:")
            if(keyArr .contains("SUFFIX:")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DCU"]!)
                keyArr.add("SUFFIX:")
            }
            
            
        }
        
        if((emptyDictionary["DDA"]) != nil) {
            passDict.updateValue(emptyDictionary["DDA"]!, forKey: "COMPLIANCE TYPE: ")
            if(keyArr .contains("COMPLIANCE TYPE: ")) {
            }
            else {
                
                
                
                valueArr.add(emptyDictionary["DDA"]!)
                keyArr.add("COMPLIANCE TYPE: ")
            }
        }
        
        if((emptyDictionary["DDB"]) != nil) {
            passDict.updateValue(emptyDictionary["DDB"]!, forKey: "CARD REVISION DATE: ")
            if(keyArr .contains("CARD REVISION DATE: ")) {
            }
            else {
                
                
                var  str = emptyDictionary["DDB"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                
                keyArr.add("CARD REVISION DATE: ")
            }
        }
        
        if((emptyDictionary["DDC"]) != nil) {
            passDict.updateValue(emptyDictionary["DDC"]!, forKey: "HAZMAT ENDORSEMENT EXPIRY DATE: ")
            if(keyArr .contains("HAZMAT ENDORSEMENT EXPIRY DATE: ")) {
            }
            else {
                
                var  str = emptyDictionary["DDC"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                
                keyArr.add("HAZMAT ENDORSEMENT EXPIRY DATE: ")
            }
        }
        
        if((emptyDictionary["DDD"]) != nil) {
            passDict.updateValue(emptyDictionary["DDD"]!, forKey: "LIMITED DURATION DOCUMENT INDICATOR: ")
            if(keyArr .contains("LIMITED DURATION DOCUMENT INDICATOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDD"]!)
                keyArr.add("LIMITED DURATION DOCUMENT INDICATOR: ")
            }
        }
        
        if((emptyDictionary["DDE"]) != nil) {
            passDict.updateValue(emptyDictionary["DDE"]!, forKey: "FAMILY NAMES TRUNCATION: ")
            if(keyArr .contains("FAMILY NAMES TRUNCATION: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDE"]!)
                keyArr.add("FAMILY NAMES TRUNCATION: ")
            }
        }
        
        if((emptyDictionary["DDF"]) != nil) {
            passDict.updateValue(emptyDictionary["DDF"]!, forKey: "FIRST NAMES TRUNCATION: ")
            if(keyArr .contains("FIRST NAMES TRUNCATION: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDF"]!)
                keyArr.add("FIRST NAMES TRUNCATION: ")
            }
        }
        
        if((emptyDictionary["DDG"]) != nil) {
            passDict.updateValue(emptyDictionary["DDG"]!, forKey: "MIDDLE NAMES TRUNCATION: ")
            if(keyArr .contains("MIDDLE NAMES TRUNCATION: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDG"]!)
                keyArr.add("MIDDLE NAMES TRUNCATION: ")
            }
        }
        
        if((emptyDictionary["DDH"]) != nil) {
            passDict.updateValue(emptyDictionary["DDH"]!, forKey: "UNDER 18 UNTIL: ")
            if(keyArr .contains("UNDER 18 UNTIL: ")) {
            }
            else {
                var  dstr = emptyDictionary["DDH"]
                let index = dstr?.index((dstr?.startIndex)!, offsetBy: 2, limitedBy: (dstr?.endIndex)!)
                
                dstr?.insert("/", at: index!)
                let index1 = dstr?.index((dstr?.startIndex)!, offsetBy: 5, limitedBy: (dstr?.endIndex)!)
                dstr?.insert("/", at: index1!)
                valueArr.add(dstr as Any)
                keyArr.add("UNDER 18 UNTIL:")
                
            }
        }
        
        if((emptyDictionary["DDI"]) != nil) {
            passDict.updateValue(emptyDictionary["DDI"]!, forKey: "UNDER 19 UNTIL: ")
            if(keyArr .contains("UNDER 19 UNTIL: ")) {
            }
            else {
                var  str = emptyDictionary["DDI"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                keyArr.add("UNDER 19 UNTIL:")
            }
        }
        
        if((emptyDictionary["DDJ"]) != nil) {
            passDict.updateValue(emptyDictionary["DDJ"]!, forKey: "UNDER 21 UNTIL: ")
            if(keyArr .contains("UNDER 21 UNTIL: ")) {
            }
            else {
                var  str = emptyDictionary["DDJ"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                keyArr.add("UNDER 21 UNTIL: ")
            }
        }
        
        if((emptyDictionary["DDK"]) != nil) {
            passDict.updateValue(emptyDictionary["DDK"]!, forKey: "ORGAN DONOR INDICATOR: ")
            if(keyArr .contains("ORGAN DONOR INDICATOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDK"]!)
                keyArr.add("ORGAN DONOR INDICATOR: ")
            }
        }
        
        if((emptyDictionary["DDL"]) != nil) {
            passDict.updateValue(emptyDictionary["DDL"]!, forKey: "VETERAN INDICATOR: ")
            if(keyArr .contains("VETERAN INDICATOR: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["DDL"]!)
                keyArr.add("VETERAN INDICATOR: ")
            }
            
            
        }
        
        if((emptyDictionary["PAA"]) != nil) {
            passDict.updateValue(emptyDictionary["PAA"]!, forKey: "PERMIT CLASSIFICATION CODE: ")
            if(keyArr .contains("PERMIT CLASSIFICATION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["PAA"]!)
                keyArr.add("PERMIT CLASSIFICATION CODE: ")
            }
            
            
        }
        
        if((emptyDictionary["PAB"]) != nil) {
            passDict.updateValue(emptyDictionary["PAB"]!, forKey: "PERMIT EXPIRATION DATE: ")
            if(keyArr .contains("PERMIT EXPIRATION DATE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["PAB"]!)
                keyArr.add("PERMIT EXPIRATION DATE: ")
            }
            
            
        }
        
        if((emptyDictionary["PAC"]) != nil) {
            passDict.updateValue(emptyDictionary["PAC"]!, forKey: "PERMIT IDENTIFIER: ")
            if(keyArr .contains("PERMIT IDENTIFIER: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["PAC"]!)
                keyArr.add("PERMIT IDENTIFIER: ")
            }
        }
        
        if((emptyDictionary["PAD"]) != nil) {
            passDict.updateValue(emptyDictionary["PAD"]!, forKey: "PERMIT ISSUE DATE: ")
            if(keyArr .contains("PERMIT ISSUE DATE: ")) {
            }
            else {
                var  str = emptyDictionary["PAD"]
                let index = str?.index((str?.startIndex)!, offsetBy: 2, limitedBy: (str?.endIndex)!)
                
                str?.insert("/", at: index!)
                let index1 = str?.index((str?.startIndex)!, offsetBy: 5, limitedBy: (str?.endIndex)!)
                str?.insert("/", at: index1!)
                
                valueArr.add(str as Any)
                
                keyArr.add("PERMIT ISSUE DATE: ")
            }
        }
        
        if((emptyDictionary["PAE"]) != nil) {
            passDict.updateValue(emptyDictionary["PAE"]!, forKey: "PERMIT RESTRICTION CODE: ")
            if(keyArr .contains("PERMIT RESTRICTION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["PAE"]!)
                keyArr.add("PERMIT RESTRICTION CODE: ")
            }
            
            
        }
        
        if((emptyDictionary["PAF"]) != nil) {
            passDict.updateValue(emptyDictionary["PAF"]!, forKey: "PERMIT ENDORSEMENT CODE: ")
            if(keyArr .contains("PERMIT ENDORSEMENT CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["PAF"]!)
                keyArr.add("PERMIT ENDORSEMENT CODE: ")
            }
            
            
        }
        
        if((emptyDictionary["ZVA"]) != nil) {
            passDict.updateValue(emptyDictionary["ZVA"]!, forKey: "COURT RESTRICTION CODE: ")
            if(keyArr .contains("COURT RESTRICTION CODE: ")) {
            }
            else {
                
                valueArr.add(emptyDictionary["ZVA"]!)
                keyArr.add("COURT RESTRICTION CODE: ")
            }
        }
        
        if(emptyDictionary["DAC"] != nil || emptyDictionary["DAD"] != nil || emptyDictionary["DCS"] != nil || emptyDictionary["DAG"] != nil ||  emptyDictionary["DAI"] != nil || emptyDictionary["DAJ"] != nil || emptyDictionary["DAK"] != nil || emptyDictionary["DBA"] != nil) {
            return true
        }
        else {
            return false
        }
        
    }
    var ocrFrontModeResult:ResultModel?
    var ocrBackModeResult:ResultModel?
}

extension ViewController: VideoCameraWrapperDelegate {
    func reco_titleMessage(_ messageCode: Int32) {
        var msg: String = ""
        switch messageCode {
            case SCAN_TITLE_OCR_FRONT:
                msg = ScanConfigs.SCAN_TITLE_OCR_FRONT
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_FRONT") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_FRONT"] as! String
                    msg = "\(msg) \(docName)"
                }
//                if isNeedBackSideFirst() {
//                    msg = ScanConfigs.SCAN_TITLE_OCR_BACK
//                    if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
//                        msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_BACK"] as! String
//                    }
//                }
                msg = msg.replacingOccurrences(of: "%@", with: docName)
                break
            case SCAN_TITLE_OCR_BACK:
                msg = ScanConfigs.SCAN_TITLE_OCR_BACK
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_BACK"] as! String
                    msg = "\(msg) \(docName)"
                }
//                if isNeedBackSideFirst() {
//                    msg = ScanConfigs.SCAN_TITLE_OCR_FRONT
//                    if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_FRONT") != nil {
//                        msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_FRONT"] as! String
//                    }
//                }
                msg = msg.replacingOccurrences(of: "%@", with: docName)
                break
            case SCAN_TITLE_OCR:
                msg = ScanConfigs.SCAN_TITLE_OCR
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR"] as! String
                    msg = "\(msg) \(docName)"
                }
                msg = msg.replacingOccurrences(of: "%@", with: docName)
                break
                
            case SCAN_TITLE_MRZ_PDF417_FRONT:
                msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_FRONT
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_FRONT") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_MRZ_PDF417_FRONT"] as! String
                }
                break
                
            case SCAN_TITLE_MRZ_PDF417_BACK:
                msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_BACK
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_BACK") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_MRZ_PDF417_BACK"] as! String
                }
                break
                
//            case SCAN_TITLE_MRZ_PDF417_BACK:
//                msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_FRONT
//                if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_FRONT") != nil {
//                    msg = ScanConfigs.accuraConfigs["SCAN_TITLE_MRZ_PDF417_FRONT"] as! String
//                }
//                if isNeedBackSideFirst() {
//                    msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_BACK
//                    if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_BACK") != nil {
//                        msg = ScanConfigs.accuraConfigs["SCAN_TITLE_MRZ_PDF417_BACK"] as! String
//                    }
//                }
//                break
            case SCAN_TITLE_DLPLATE:
                msg = ScanConfigs.SCAN_TITLE_DLPLATE
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_DLPLATE") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_DLPLATE"] as! String
                }
                break
            case SCAN_TITLE_BARCODE:
                msg = ScanConfigs.SCAN_TITLE_BARCODE
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_BARCODE") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_BARCODE"] as! String
                }
                break
            case SCAN_TITLE_BANKCARD:
                msg = ScanConfigs.SCAN_TITLE_BANKCARD
                if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_BANKCARD") != nil {
                    msg = ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_BANKCARD"] as! String
                }
                break
            default:
                break
        }
        _lblTitle.text = msg
    }

//     func reco_titleMessage(_ messageCode: Int32) {
//         var msg: String = ""
//         switch messageCode {
//             case SCAN_TITLE_OCR_FRONT:
//                 msg = ScanConfigs.SCAN_TITLE_OCR_FRONT
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_FRONT") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_FRONT"] as! String
//                 }
// //                if isNeedBackSideFirst() {
// //                    msg = ScanConfigs.SCAN_TITLE_OCR_BACK
// //                    if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
// //                        msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_BACK"] as! String
// //                    }
// //                }
//                 msg = msg.replacingOccurrences(of: "%@", with: docName)
//                 break
//             case SCAN_TITLE_OCR_BACK:
//                 msg = ScanConfigs.SCAN_TITLE_OCR_BACK
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_BACK"] as! String
//                 }
// //                if isNeedBackSideFirst() {
// //                    msg = ScanConfigs.SCAN_TITLE_OCR_FRONT
// //                    if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR_FRONT") != nil {
// //                        msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR_FRONT"] as! String
// //                    }
// //                }
//                 msg = msg.replacingOccurrences(of: "%@", with: docName)
//                 break
//             case  SCAN_TITLE_OCR:
//                 msg = ScanConfigs.SCAN_TITLE_OCR
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_OCR") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_OCR"] as! String
//                 }
//                 msg = msg.replacingOccurrences(of: "%@", with: docName)
//                 break
//             case SCAN_TITLE_MRZ_PDF417_FRONT:
//                 msg = "Scan Front Side of Document"
//                 break
//             case SCAN_TITLE_MRZ_PDF417_BACK:
//                 msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_FRONT
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_FRONT") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_MRZ_PDF417_FRONT"] as! String
//                 }
//                 if isNeedBackSideFirst() {
//                     msg = ScanConfigs.SCAN_TITLE_MRZ_PDF417_BACK
//                     if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_MRZ_PDF417_BACK") != nil {
//                         msg = ScanConfigs.accuraConfigs["SCAN_TITLE_MRZ_PDF417_BACK"] as! String
//                     }
//                 }
//                 break
//             case SCAN_TITLE_DLPLATE:
//                 msg = ScanConfigs.SCAN_TITLE_DLPLATE
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_DLPLATE") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_DLPLATE"] as! String
//                 }
//                 break
//             case SCAN_TITLE_BARCODE:
//                 msg = ScanConfigs.SCAN_TITLE_BARCODE
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_BARCODE") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_BARCODE"] as! String
//                 }
//                 break
//             case SCAN_TITLE_BANKCARD:
//                 msg = ScanConfigs.SCAN_TITLE_BANKCARD
//                 if ScanConfigs.accuraConfigs.index(forKey: "SCAN_TITLE_BANKCARD") != nil {
//                     msg = ScanConfigs.accuraConfigs["SCAN_TITLE_BANKCARD"] as! String
//                 }
//                 break
//             default:
//                 break
//         }
//         _lblTitle.text = msg
//     }
    
    func onUpdateLayout(_ frameSize: CGSize, _ borderRatio: Float) {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        if(isCheckScanOCR) {
            if(cardType != 2 && cardType != 3) {
                let orientastion = UIApplication.shared.statusBarOrientation
                if(orientastion ==  UIInterfaceOrientation.portrait) {
                    width = frameSize.width
                    height  = frameSize.height
                    viewNavigationBar.backgroundColor = UIColor(red: 231.0 / 255.0, green: 52.0 / 255.0, blue: 74.0 / 255.0, alpha: 1.0)
                } else {
                    
                    self.viewNavigationBar.backgroundColor = .clear
                    height = (((UIScreen.main.bounds.size.height - 100) * 5) / 5.6)
                    width = (height / CGFloat(borderRatio))
                    print("boreder ratio :- ", borderRatio)
                }
                print("layer", width)
                DispatchQueue.main.async {
                    self._constant_width.constant = width
                    
                    self._constant_height.constant = height
                }
                
            }
            
        } else if(isCheckCardMRZ) {
            
            let orientastion = UIApplication.shared.statusBarOrientation
           if(orientastion ==  UIInterfaceOrientation.portrait) {
               width = UIScreen.main.bounds.size.width * 0.95
               
               height  = (UIScreen.main.bounds.size.height - (self.bottomPadding + self.topPadding + self.statusBarRect.height)) * 0.35
           } else {
               height = UIScreen.main.bounds.size.height * 0.62
               width = UIScreen.main.bounds.size.width * 0.51
           }
            print("layer", width)
            DispatchQueue.main.async {
                self._constant_width.constant = width
                self._constant_height.constant = height
            }
        }
        
        
    }
    
    func dlPlateNumber(_ plateNumber: String!, andImageNumberPlate imageNumberPlate: UIImage!) {
        shareScanningListing["plate_number"] = plateNumber
        var results:[String: Any] = [:]
        var frontData:[String: Any] = [:]
        var backData:[String: Any] = [:]
        
        if let frontUri = KycPl.getImageUri(img: imageNumberPlate, name: nil) {
            results["front_img"] = frontUri
        }
        frontData["PlateNumber"] = plateNumber
        results["front_data"] = frontData
        results["back_data"] = backData
        results["type"] = "DL_PLATE"
        
        callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        closeMe()
    }
    func getMRZKeyValue() -> [String: String] {
        var mrzData:[String: String] = [:]
        if let line =  shareScanningListing["lines"] as? String {
            mrzData["MRZ"] = line

        }
        if let givenname =  shareScanningListing["givenname"] as? String {
            mrzData["First Name"] = givenname
        } else if let givenname =  shareScanningListing["givenNames"] as? String {
            mrzData["First Name"] = givenname
        }
        
        if let surname =  shareScanningListing["surname"] as? String {
            mrzData["Last Name"] = surname
            
        } else if let surname =  shareScanningListing["surName"] as? String {
            mrzData["Last Name"] = surname
            
        }
        
        if let docnumber =  shareScanningListing["docnumber"] as? String {
            mrzData["Document No."] = docnumber

        } else if let docnumber =  shareScanningListing["docNumber"] as? String {
            mrzData["Document No."] = docnumber

        }
        
        if let docchecksum =  shareScanningListing["docchecksum"] as? String {
            mrzData["Document check No."] = docchecksum
        } else if let docchecksum =  shareScanningListing["docCheckSum"] as? String {
            mrzData["Document check No."] = docchecksum
        }
        
        if let correctdocchecksum =  shareScanningListing["correctdocchecksum"] as? String {
            mrzData["Correct Document check No."] = correctdocchecksum

        } else if let correctdocchecksum =  shareScanningListing["correctPassportChecksum"] as? String {
            mrzData["Correct Document check No."] = correctdocchecksum

        }
        if let contri =  shareScanningListing["country"] as? String {
            mrzData["Country"] = contri

        }
        if let nationality =  shareScanningListing["nationality"] as? String {
            mrzData["Nationality"] = nationality

        }
        if let birth =  shareScanningListing["birth"] as? String {
            mrzData["Date of Birth"] = birth

        }
        if let birthchecksum =  shareScanningListing["birthchecksum"] as? String {
            mrzData["Birth Check No."] = birthchecksum

        } else if let birthchecksum =  shareScanningListing["birthCheckSum"] as? String {
            mrzData["Birth Check No."] = birthchecksum

        }
        if let correctbirthchecksum =  shareScanningListing["correctbirthchecksum"] as? String {
            mrzData["Correct Birth Check No."] = correctbirthchecksum

        } else if let correctbirthchecksum =  shareScanningListing["correctBirthChecksum"] as? String {
            mrzData["Correct Birth Check No."] = correctbirthchecksum

        }
        if let expirationdate =  shareScanningListing["expirationdate"] as? String {
            mrzData["Date of Expiry"] = expirationdate

        } else if let expirationdate =  shareScanningListing["expirationDate"] as? String {
            mrzData["Date of Expiry"] = expirationdate

        }
        if let expirationchecksum =  shareScanningListing["expirationchecksum"] as? String {
            mrzData["Expiration Check No."] = expirationchecksum

        } else if let expirationchecksum =  shareScanningListing["expirationChecksum"] as? String {
            mrzData["Expiration Check No."] = expirationchecksum

        }
        if let correctexpirationchecksum =  shareScanningListing["correctexpirationchecksum"] as? String {
            mrzData["Correct Expiration Check No."] = correctexpirationchecksum

        } else if let correctexpirationchecksum =  shareScanningListing["correctExpirationChecksum"] as? String {
            mrzData["Correct Expiration Check No."] = correctexpirationchecksum

        }
        if let issuedate =  shareScanningListing["issuedate"] as? String {
            mrzData["Date Of Issue"] = issuedate

        } else if let issuedate =  shareScanningListing["issueDate"] as? String {
            mrzData["Date Of Issue"] = issuedate

        }
        if let departmentnumber =  shareScanningListing["departmentnumber"] as? String {
            mrzData["Department No."] = departmentnumber

        }else if let departmentnumber =  shareScanningListing["departmentNumber"] as? String {
            mrzData["Department No."] = departmentnumber

        }
        if let otherid =  shareScanningListing["otherid"] as? String {
            mrzData["Other ID"] = otherid

        } else if let otherid =  shareScanningListing["otherId"] as? String {
            mrzData["Other ID"] = otherid

        }
        
        if let otheridchecksum =  shareScanningListing["otheridchecksum"] as? String {
            mrzData["Other ID Check"] = otheridchecksum

        } else if let otheridchecksum =  shareScanningListing["otherIdChecksum"] as? String {
            mrzData["Other ID Check"] = otheridchecksum

        }
        if let secondrowchecksum =  shareScanningListing["secondrowchecksum"] as? String {
            mrzData["Second Row Check No."] = secondrowchecksum

        } else if let secondrowchecksum =  shareScanningListing["secondRowChecksum"] as? String {
            mrzData["Second Row Check No."] = secondrowchecksum

        }
        if let correctsecondrowchecksum =  shareScanningListing["correctsecondrowchecksum"] as? String {
            mrzData["Correct Second Row Check No."] = correctsecondrowchecksum

        } else if let correctsecondrowchecksum =  shareScanningListing["correctSecondRowChecksum"] as? String {
            mrzData["Correct Second Row Check No."] = correctsecondrowchecksum

        }
        mrzData["sex"] = ""
        if let sx = shareScanningListing["sex"] as? String {
            if sx == "F" {
                mrzData["sex"] = "Female"
            } else if sx == "M" {
                mrzData["sex"] = "Male"
            }
        }
    
        return mrzData
    }
    func resultData(_ resultmodel: ResultModel!) {
        if isbothSideAvailable {
            if isNeedBackSideFirst() {
                accuraCameraWrapper?.cardSide(.FRONT_CARD_SCAN)
                if(resultmodel.arrayocrFrontSideDataKey.count == 0) {
                    flipAnimation()
//                    playSound()
                    return
                }
            } else {
                accuraCameraWrapper?.cardSide(.BACK_CARD_SCAN)
                if(resultmodel.arrayocrBackSideDataKey.count == 0) {
                    flipAnimation()
//                    playSound()
                    return
                }
            }
            
        }
        if isNeedBackSideFirst() {
//            if ocrBackModeResult == nil {
//                ocrBackModeResult = resultmodel
//                flipAnimation()
//                startOCRCamera()
//                accuraCameraWrapper?.cardSide(.FRONT_CARD_SCAN)
//                accuraCameraWrapper?.startCamera()
//                return
//            }
//            resultmodel.ocrFaceBackData = ocrBackModeResult!.ocrFaceBackData
//            resultmodel.backSideImage = ocrBackModeResult!.backSideImage
//            resultmodel.arrayocrBackSideDataKey = ocrBackModeResult!.arrayocrBackSideDataKey
//            resultmodel.arrayocrBackSideDataValue = ocrBackModeResult!.arrayocrBackSideDataValue
            
        }
        playSound()
        var results:[String: Any] = [:]
        var frontData:[String: Any] = [:]
        var backData:[String: Any] = [:]
        var mrzData:[String: Any] = [:]
        if let faceUri = KycPl.getImageUri(img: resultmodel.faceImage, name: nil) {
            results["face"] = faceUri
        }
        if let frontUri = KycPl.getImageUri(img: resultmodel.frontSideImage, name: nil) {
            results["front_img"] = frontUri
        }
        if let backUri = KycPl.getImageUri(img: resultmodel.backSideImage, name: nil) {
            results["back_img"] = backUri
        }
        self.dictFaceDataFront = resultmodel.ocrFaceFrontData
        for data in dictFaceDataFront {
            if let k = data.key as? String {
                if k == "Signature" {
                    if let base64img = data.value as? String {
                        let dataDecoded : Data = Data(base64Encoded: base64img, options: .ignoreUnknownCharacters)!
                        let decodedimage:UIImage = UIImage(data: dataDecoded)!
                        if let sigUri = KycPl.getImageUri(img: decodedimage, name: nil) {
                            frontData["signature"] = sigUri
                        }
                    }
                } else {
                    frontData[k] = data.value as? String ?? data.value as? Int ?? ""
                }
            }
            
        }
        
        self.dictFaceDataBack = resultmodel.ocrFaceBackData
        for data in dictFaceDataBack {
            if let k = data.key as? String {
                if k == "Signature" {
                    if let base64img = data.value as? String {
                        let dataDecoded : Data = Data(base64Encoded: base64img, options: .ignoreUnknownCharacters)!
                        let decodedimage:UIImage = UIImage(data: dataDecoded)!
                        if let sigUri = KycPl.getImageUri(img: decodedimage, name: nil) {
                            backData["signature"] = sigUri
                        }
                    }
                } else {
                    backData[k] = data.value as? String ?? data.value as? Int ?? ""
                }
            }
            
        }
        
        self.dictSecuretyData = resultmodel.ocrSecurityData
        for data in dictSecuretyData {
            frontData[data.key as! String] = data.value as? String ?? data.value as? Int ?? ""
        }

        self.arrFrontResultKey = resultmodel.arrayocrFrontSideDataKey as! [String]
        self.arrFrontResultValue = resultmodel.arrayocrFrontSideDataValue as! [String]
        for i in arrFrontResultKey.indices {
            if arrFrontResultKey[i] != "MRZ" {
                frontData[arrFrontResultKey[i]] = arrFrontResultValue[i]
            } else {
                self.shareScanningListing = resultmodel.shareScanningMRZListing
                mrzData = self.getMRZKeyValue()
                mrzData["Other Id2"] = shareScanningListing["personalNumber2"]
                mrzData["Document Type"] = "Card"
            }
        }
        
        self.arrBackResultKey = resultmodel.arrayocrBackSideDataKey as! [String]
        self.arrBackResultValue = resultmodel.arrayocrBackSideDataValue as! [String]
        for i in arrBackResultKey.indices {
            if arrBackResultKey[i] != "MRZ" {
                backData[arrBackResultKey[i]] = arrBackResultValue[i]
            } else {
                self.shareScanningListing = resultmodel.shareScanningMRZListing
                mrzData = self.getMRZKeyValue()
                mrzData["Other Id2"] = shareScanningListing["personalNumber2"]
                mrzData["Document Type"] = "Card"
            }
        }
        
        results["front_data"] = frontData
        results["back_data"] = backData
        results["mrz_data"] = mrzData
        results["type"] = "OCR"
        
        callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        closeMe()
    }
    
    func screenSound() {
        playSound()
        if !self.isflipanimation!{
            self.isflipanimation = true
            self.flipAnimation()
        }
        
    }
    
    func isBothSideAvailable(_ isBothAvailable: Bool) {
        isbothSideAvailable = isBothAvailable
        if !isBothAvailable && isNeedBackSideFirst(){
            
            callBack!(["Back Side not available" as Any, NSNull()])
            closeMe()
        }
    }
    
    func playSound() {
        if let audioUrl = gl.audio {
            let player = AVPlayer(url: audioUrl)
            player.isMuted = false
            player.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                player.pause()
            })
        } else {
            AudioServicesPlaySystemSound(1315)
        }
    }
    
    func recognizeSucceedBarcode(_ message: String!, back BackSideImage: UIImage!, frontImage FrontImage: UIImage!, face FaceImage: UIImage!) {
        var results:[String: Any] = [:]
        var frontData:[String: Any] = [:]
        var backData:[String: Any] = [:]
        if(!isBarcodeEnabled) {
            //display result of barcode
            if isNeedBackSideFirst() {
                if (FrontImage == nil) {
                   self.accuraCameraWrapper?.cardSide(.FRONT_CARD_SCAN)
                   self.flipAnimation()
                   return
               } else if(BackSideImage == nil) {
                     self.accuraCameraWrapper?.cardSide(.BACK_CARD_SCAN)
                    // self._lblTitle.text = ScanConfigs.SCAN_TITLE_OCR_BACK.replacingOccurrences(of: "%@", with: "Card")
                    // if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
                    //     self._lblTitle.text = (ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_BACK"] as! String).replacingOccurrences(of: "%@", with: "Card")
                    // }
                     self.flipAnimation()
                   return
               }else {
                   //Display Result
               }
            } else {
                if(BackSideImage == nil) {
                     self.accuraCameraWrapper?.cardSide(.BACK_CARD_SCAN)
                    // self._lblTitle.text = ScanConfigs.SCAN_TITLE_OCR_BACK.replacingOccurrences(of: "%@", with: "Card")
                    // if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
                    //     self._lblTitle.text = (ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_BACK"] as! String).replacingOccurrences(of: "%@", with: "Card")
                    // }
                     self.flipAnimation()
                   return
               } else if (FrontImage == nil) {
                   self.accuraCameraWrapper?.cardSide(.FRONT_CARD_SCAN)
                   self.flipAnimation()
                   return
               }else {
                   //Display Result
               }
            }

            
       }
            let isPDF = self.decodework(type: message)
            self.accuraCameraWrapper?.stopCamera()
            playSound()
            if cardType == 1 {
                if FaceImage != nil{
                    if let frontUri = KycPl.getImageUri(img: FaceImage!, name: nil) {
                        results["face"] = frontUri
                    }
                }
                if FrontImage != nil{
                    if let frontUri = KycPl.getImageUri(img: FrontImage!, name: nil) {
                        results["front_img"] = frontUri
                    }
                }
                if BackSideImage != nil{
                    if let frontUri = KycPl.getImageUri(img: BackSideImage!, name: nil) {
                        results["back_img"] = frontUri
                    }
                }
            } else {
                if let frontUri = KycPl.getImageUri(img: FrontImage!, name: nil) {
                    results["front_img"] = frontUri
                }
            }
            
            if(isPDF)
            {
                if cardType != 1 {
                    gl.type = "BARCODEPDF417"
                }
                let kArr = keyArr as! [String]
                let valArr = valueArr as! [String]
                for i in kArr.indices {
                    frontData[kArr[i]] = valArr[i]
                }
                frontData["PDF417"] = message
            }
            else{
                gl.type = "BARCODE"
                frontData["barcode"] = message
            }
        
        results["front_data"] = frontData
        results["back_data"] = backData
        results["type"] = gl.type
        
        callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        closeMe()
    }
    
    
    func processedImage(_ image: UIImage!) {
        //        _imageView.image = image
    }
    
    func recognizeFailed(_ message: String!) {
        
        callBack!([message as Any, NSNull()])
        closeMe()
    }
    
    func isNeedBackSideFirst() -> Bool {
        var result = false
        if ScanConfigs.accuraConfigs.index(forKey: "rg_setBackSide") != nil {
            if let isBackSideFirst = ScanConfigs.accuraConfigs["rg_setBackSide"] as? Bool {
                result = isBackSideFirst
            }
        }
        return result
    }

    func recognizeSucceed(_ scanedInfo: NSMutableDictionary!, recType: RecType, bRecDone: Bool, bFaceReplace: Bool, bMrzFirst: Bool, photoImage: UIImage, docFrontImage: UIImage!, docbackImage: UIImage!) {
        
        if(bMrzFirst)
        
        {
            self.imageRotation(rotation: "BackImg")
            self.accuraCameraWrapper?.stopCamera()
            self._imageView.image = nil
            
            playSound()
            
            self.shareScanningListing.addEntries(from: scanedInfo as! [AnyHashable : Any])
            sendRecognizResults(face: photoImage, front: docFrontImage, back: docbackImage)
        }
        else{
            countface += 1
            if !isBackSide!{
                if(countface > 2)
                {
                    countface = 0
                    self.docfrontImage = self._imageView.image
                    self.imageRotation(rotation: "FrontImage")
                    isBackSide = true
                    
                    // self._lblTitle.text = ScanConfigs.SCAN_TITLE_OCR_BACK.replacingOccurrences(of: "%@", with: "Card")
                    // if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
                    //     self._lblTitle.text = (ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_BACK"] as! String).replacingOccurrences(of: "%@", with: "Card")
                    // }
                    self.flipAnimation()
                    return
                }
            }
            else{
                // self._lblTitle.text = ScanConfigs.SCAN_TITLE_OCR_BACK.replacingOccurrences(of: "%@", with: "Card")
                // if ScanConfigs.accuraMessagesConfigs.index(forKey: "SCAN_TITLE_OCR_BACK") != nil {
                //     self._lblTitle.text = (ScanConfigs.accuraMessagesConfigs["SCAN_TITLE_OCR_BACK"] as! String).replacingOccurrences(of: "%@", with: "Card")
                // }
                return
            }
        }
    }
    
    func sendRecognizResults(face: UIImage?, front: UIImage?, back: UIImage?) {
        var results:[String: Any] = [:]
        var frontData:[String: Any] = [:]
        var backData:[String: Any] = [:]
        
        for (key, value) in shareScanningListing {
            let k = key as! String
            if let val = value as? String {
                
                print("key:- \(key) ==> value:- \(val)")
                if k == "lines" {
                    frontData["mrz"] = val.components(separatedBy: .whitespacesAndNewlines).joined()
                } else if k == "birth" || k == "expirationDate" || k == "issuedate" {
                    
                    var strDate = val
                    strDate = strDate.replacingOccurrences(of: "<", with: "")
                    if (strDate.count == 6) {
                        strDate = "\(strDate[4])\(strDate[5])-\(strDate[2])\(strDate[3])-\(strDate[0])\(strDate[1])"
                    }
                    frontData[k] = strDate
                } else if k == "BirthChecksum" {
                    frontData["birthChecksum"] = val
                } else if k == "sex" {
                    frontData["sex"] = val == "M" ? "Male" : "Female"
                } else {
                    frontData[k] = val
                }

            }
        }
        // frontData = self.getMRZKeyValue()
        // frontData["Other Id2"] = shareScanningListing["personalNumber2"]
        // frontData["Document Type"] = ""
        // if MRZDocType == 1 {
        //     frontData["Document Type"] = "Passport"
        // } else if (MRZDocType == 2) {
        //     frontData["Document Type"] = "Card"
        // } else if (MRZDocType == 2) {
        //     frontData["Document Type"] = "Visa"
        // }

        if let recogFrontImg = face{
            if let frontUri = KycPl.getImageUri(img: recogFrontImg, name: nil) {
                results["face"] = frontUri
            }
        }
        
        if let recogFrontImg = front{
            if let frontUri = KycPl.getImageUri(img: recogFrontImg, name: nil) {
                results["front_img"] = frontUri
            }
        }
        if let recogBackImg = back{
            if let frontUri = KycPl.getImageUri(img: recogBackImg, name: nil) {
                results["back_img"] = frontUri
            }
        }
        results["front_data"] = frontData
        results["back_data"] = backData
        results["type"] = "MRZ"
        
        callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        closeMe()
    }
    
    func recognizSuccessBankCard(_ cardDetail: NSMutableDictionary!, andBankCardImage bankCardImage: UIImage!) {
        var results:[String: Any] = [:]
        var frontData:[String: Any] = [:]
        let backData:[String: Any] = [:]
        if let frontUri = KycPl.getImageUri(img: bankCardImage, name: nil) {
            results["front_img"] = frontUri
        }
        for data in cardDetail {
            frontData[data.key as! String] = data.value as? String ?? data.value as? Int ?? ""
        }
        results["front_data"] = frontData
        results["back_data"] = backData
        results["type"] = "BANKCARD"
        
        callBack!([NSNull(), KycPl.convertJSONString(results: results)])
        closeMe()
    }
    
    func matchedItem(_ image: UIImage!, isCardSide1 cs: Bool, isBack b: Bool, isFront f: Bool, imagePhoto imgp: UIImage!, imageResult: UIImage!) {
        if f == true{
            imgViewCardFront = imageResult
        }else{
            imgViewCard = imageResult
        }
        isCardSide = cs
        isBack = b
        isFront = f
    }
    
    
    func imageRotation(rotation: String) {
        var strRotation = ""
        if UIDevice.current.orientation == .landscapeRight {
            strRotation = "Right"
        } else if UIDevice.current.orientation == .landscapeLeft {
            strRotation = "Left"
        }
        if rotation == "FrontImg" {
            frontImageRotation = strRotation
        } else if rotation == "BackImg" {
            backImageRotation = strRotation
        } else {
            frontImageRotation = strRotation
        }
    }
    func reco_msg(_ message: String!) {
        var msg = String()
        if(message == ACCURA_ERROR_CODE_MOTION) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_MOTION
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_MOTION") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_MOTION"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_PROCESSING) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_PROCESSING
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_PROCESSING") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_PROCESSING"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_BLUR_DOCUMENT) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_BLUR_DOCUMENT
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_BLUR_DOCUMENT") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_BLUR_DOCUMENT"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_FACE_BLUR) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_FACE_BLUR
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_FACE_BLUR") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_FACE_BLUR"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_GLARE_DOCUMENT) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_GLARE_DOCUMENT
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_GLARE_DOCUMENT") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_GLARE_DOCUMENT"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_HOLOGRAM) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_HOLOGRAM
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_HOLOGRAM") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_HOLOGRAM"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_DARK_DOCUMENT) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_DARK_DOCUMENT
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_DARK_DOCUMENT") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_DARK_DOCUMENT"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_FACE) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_FACE
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_FACE") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_FACE"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_MRZ) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_MRZ
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_MRZ") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_MRZ"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_PASSPORT_MRZ) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_PASSPORT_MRZ
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_PASSPORT_MRZ") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_PASSPORT_MRZ"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_ID_MRZ) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_ID_MRZ
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_ID_MRZ") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_ID_MRZ"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_VISA_MRZ) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_VISA_MRZ
            if (ScanConfigs.accuraMessagesConfigs.index(forKey: "ACCURA_ERROR_CODE_VISA_MRZ") != nil) {
                msg = ScanConfigs.accuraMessagesConfigs["ACCURA_ERROR_CODE_VISA_MRZ"] as! String
            }
        } else if(message == ACCURA_ERROR_CODE_WRONG_SIDE) {
            msg = AccuraErrorType.ACCURA_ERROR_CODE_WRONG_SIDE
            if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_WRONG_SIDE") != nil) {
                msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_WRONG_SIDE"] as! String
            }
        } else {
            msg = message
        }
        lblOCRMsg.text = msg
    }
    
    // func reco_msg(_ message: String!) {
    //     var msg = String()
    //     if(message == ACCURA_ERROR_CODE_MOTION) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_MOTION
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_MOTION") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_MOTION"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_PROCESSING) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_PROCESSING
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_PROCESSING") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_PROCESSING"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_BLUR_DOCUMENT) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_BLUR_DOCUMENT
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_BLUR_DOCUMENT") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_BLUR_DOCUMENT"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_FACE_BLUR) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_FACE_BLUR
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_FACE_BLUR") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_FACE_BLUR"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_GLARE_DOCUMENT) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_GLARE_DOCUMENT
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_GLARE_DOCUMENT") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_GLARE_DOCUMENT"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_HOLOGRAM) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_HOLOGRAM
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_HOLOGRAM") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_HOLOGRAM"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_DARK_DOCUMENT) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_DARK_DOCUMENT
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_DARK_DOCUMENT") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_DARK_DOCUMENT"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_FACE) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_FACE
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_FACE") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_FACE"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_MRZ) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_MRZ
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_MRZ") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_MRZ"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_PASSPORT_MRZ) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_PASSPORT_MRZ
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_PASSPORT_MRZ") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_PASSPORT_MRZ"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_ID_MRZ) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_ID_MRZ
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_ID_MRZ") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_ID_MRZ"] as! String
    //         }
    //     } else if(message == ACCURA_ERROR_CODE_VISA_MRZ) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_VISA_MRZ
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_VISA_MRZ") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_VISA_MRZ"] as! String
    //         }
    //     }else if(message == ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE"] as! String
    //         }
    //     }else if(message == ACCURA_ERROR_CODE_WRONG_SIDE) {
    //         msg = AccuraErrorType.ACCURA_ERROR_CODE_WRONG_SIDE
    //         if (ScanConfigs.accuraConfigs.index(forKey: "ACCURA_ERROR_CODE_WRONG_SIDE") != nil) {
    //             msg = ScanConfigs.accuraConfigs["ACCURA_ERROR_CODE_WRONG_SIDE"] as! String
    //         }
    //     }else {
    //         msg = message
    //     }
    //     lblOCRMsg.text = msg
    // }
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
