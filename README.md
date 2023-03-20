# react-native-kyc-pl

This package is for digital user verification system powered by Accura Scan. 

**Installation using NPM**
```sh
npm install --save react-native-kyc-pl
```
**Installation using Yarn**
```sh
yarn add react-native-kyc-pl
```
**Installation using Yarn from Git**
```sh
yarn add https://github.com/accurascan/react-native-kyc-pl
```

## Setup Android
### Add this permissions into Android AndroidManifest.xml file.
```sh
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

### Add it in your root build.gradle at the end of repositories.
```sh
buildscript {
    repositories {
        ...
        jcenter()
    }
}

allprojects {
    repositories {
        ...
        jcenter()
        maven {
            url 'https://jitpack.io'
            credentials { username 'jp_ssguccab6c5ge2l4jitaj92ek2' }
        }
    }
}
```

### Set Accura SDK as a dependency to our app/build.gradle file.
```sh
android {

    defaultConfig {
        ...
        ndk {
            // Specify CPU architecture.
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    packagingOptions {
        pickFirst 'lib/arm64-v8a/libcrypto.so'
        pickFirst 'lib/arm64-v8a/libssl.so'

        pickFirst 'lib/armeabi-v7a/libcrypto.so'
        pickFirst 'lib/armeabi-v7a/libssl.so'

        pickFirst 'lib/x86/libcrypto.so'
        pickFirst 'lib/x86/libssl.so'

        pickFirst 'lib/x86_64/libcrypto.so'
        pickFirst 'lib/x86_64/libssl.so'

        pickFirst '**/libjsc.so'
        pickFirst '**/libc++_shared.so'

        pickFirst 'lib/x86/libc++_shared.so'
        pickFirst 'lib/x86_64/libc++_shared.so'
        pickFirst 'lib/armeabi-v7a/libc++_shared.so'
        pickFirst 'lib/arm64-v8a/libc++_shared.so'

        pickFirst 'lib/x86/libopencv_java4.so'
        pickFirst 'lib/armeabi-v7a/libopencv_java4.so'
        pickFirst 'lib/arm64-v8a/libopencv_java4.so'
        pickFirst 'lib/x86_64/libopencv_java4.so'
        pickFirst 'lib/armeabi-v7a/libopencv_java4.so'

        pickFirst 'lib/armeabi-v7a/libaccurasdk.so'
        pickFirst 'lib/arm64-v8a/libaccurasdk.so'
        pickFirst 'lib/armeabi-v7a/libaccuraface.so'
        pickFirst 'lib/arm64-v8a/libaccuraface.so'
        pickFirst 'lib/armeabi-v7a/libaccuraliveness.so'
        pickFirst 'lib/arm64-v8a/libaccuraliveness.so'
    }
}
```

## Setup iOS
### Please make sure to install git-lfs into your Mac.
**Open your mac terminal and fire following command**

```sh
brew install git-lfs

or

port install git-lfs
```
### Add this permissions into iOS Info.plist file.
```sh
<key>NSCameraUsageDescription</key>
<string>App usage camera for scan documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App usage photos for get document picture.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>App usage photos for save document picture.</string>
```

## Setup Accura license into your projects
**Accura has two license require for use full functionality of this library. Generate your own Accura license from [here](https://accurascan.com/developer/dashboard)**
1. ### key.license 
    - This license is compulsory for this library to work. it will get all setup of accura SDK.
2. ### accuraface.license
    - This license is use for get face match percentages between two face pictures.

***Note:-*** You have to create license of your own bundle id for iOS and app id for Android. You can not use any other app license. If you use other app license then it will return error.

**1. Setup license into Android**
- Go to android -> app -> src -> main and create folder named 'assets' if not exist and put all three licenses into that folder.

**2. Setup license into iOS**
- Open iOS project into Xcode and drag & drop all three license into project root directory. Do not forgot to check "copy if needed" & "project name".

## Usage

Import react native library into file.
```js
import KycPl from "react-native-kyc-pl";
```
### ➜ Get license configuration from SDK. It returns all active functionalities of your license.
```js
KycPl.getMetaData((error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("Response:- ", success)
        //Here you will get json string from SDK with all available functions activated on your license.
    }
})
```
- Error: String<Any Error Message>
- Success: JSON String Response = {
 	- countries: Array[<CountryModels<CardItems>>],
    - barcodes: Array[<BarcodeItems>],
    - isValid: boolean,
    - isOCREnable: boolean,
    - isBarcode: boolean,
    - isBankCard: boolean,
    - isMRZ: boolean,
    - sdk_version: String

    }

### ➜ Method for setup custom setup & messages to Accura SDK.
```js
let config = { 
    ACCURA_ERROR_CODE_MOTION: 'Keep Document Steady',
    ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME: 'Keep document in frame',
    ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME:  'Bring card near to frame',
    ACCURA_ERROR_CODE_PROCESSING:  'Processing…',
    ACCURA_ERROR_CODE_BLUR_DOCUMENT:  'Blur detect in document',
    ACCURA_ERROR_CODE_FACE_BLUR:  'Blur detected over face',
    ACCURA_ERROR_CODE_GLARE_DOCUMENT:  'Glare detect in document',
    ACCURA_ERROR_CODE_HOLOGRAM:  'Hologram Detected', 
    ACCURA_ERROR_CODE_DARK_DOCUMENT:  'Low lighting detected',
    ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT:  'Can not accept Photo Copy Document',
    ACCURA_ERROR_CODE_FACE:  'Face not detected',
    ACCURA_ERROR_CODE_MRZ:  'MRZ not detected',
    ACCURA_ERROR_CODE_PASSPORT_MRZ:  'Passport MRZ not detected',
    ACCURA_ERROR_CODE_ID_MRZ:  'ID card MRZ not detected',
    ACCURA_ERROR_CODE_VISA_MRZ:  'Visa MRZ not detected',
    ACCURA_ERROR_CODE_WRONG_SIDE:  'Scanning wrong side of document',
    ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE:  'Document is upside down. Place it properly',
    IS_SHOW_LOGO: true,
    SCAN_TITLE_OCR_FRONT:  'Scan Front Side of OCR Document',
    SCAN_TITLE_OCR_BACK:  'Scan Back Side of OCR Document',
    SCAN_TITLE_OCR:  'Scan',
    SCAN_TITLE_BANKCARD:  'Scan Bank Card',
    SCAN_TITLE_BARCODE:  'Scan Barcode',
    SCAN_TITLE_MRZ_PDF417_FRONT:  'Scan Front Side of Document',
    SCAN_TITLE_MRZ_PDF417_BACK:  'Now Scan Back Side of Document',
    SCAN_TITLE_DLPLATE:  'Scan Number Plate'
}
KycPl.setupAccuraConfig( config, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("Response:- ", success)
    }
})
```
- config: JSON Object 
    - ACCURA_ERROR_CODE_MOTION: String
    - ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME: String
    - ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME: String
    - ACCURA_ERROR_CODE_PROCESSING: String
    - ACCURA_ERROR_CODE_BLUR_DOCUMENT: String
    - ACCURA_ERROR_CODE_FACE_BLUR: String
    - ACCURA_ERROR_CODE_GLARE_DOCUMENT: String
    - ACCURA_ERROR_CODE_HOLOGRAM: String
    - ACCURA_ERROR_CODE_DARK_DOCUMENT: String
    - ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT: String
    - ACCURA_ERROR_CODE_FACE: String
    - ACCURA_ERROR_CODE_MRZ: String
    - ACCURA_ERROR_CODE_PASSPORT_MRZ: String
    - ACCURA_ERROR_CODE_ID_MRZ: String
    - ACCURA_ERROR_CODE_VISA_MRZ: String
    - ACCURA_ERROR_CODE_WRONG_SIDE: String
    - ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE: String
    - IS_SHOW_LOGO: Boolean
    - SCAN_TITLE_OCR_FRONT: String
    - SCAN_TITLE_OCR_BACK: String
    - SCAN_TITLE_OCR: String
    - SCAN_TITLE_BANKCARD: String
    - SCAN_TITLE_BARCODE: String
    - SCAN_TITLE_MRZ_PDF417_FRONT: String
    - SCAN_TITLE_MRZ_PDF417_BACK: String
    - SCAN_TITLE_DLPLATE: String

- Success: JSON Response {
    String
    }
- Error: String<Any Error Message>

### ➜ Method for scan MRZ documents.
```js
let passArgs = [{ enableLogs: false }, MRZType, CountryList, AppOrientation]
KycPl.startMRZ(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("Response:- ", success)
    }
})
```
- MRZType: String 
    - value: other_mrz or passport_mrz or id_mrz or visa_mrz
- CountryList: String 
    - value: all or IND,USA
- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {

 	- front_data: JSONObjects?,
    - back_data: JSONObjects?,
    - type: Recognition Type,
    - face: URI?
    - front_img: URI?
    - back_img: URI?
    }
- Error: String<Any Error Message>

### ➜ Method for scan OCR documents.
```js
let passArgs = [{ enableLogs: false }, CountryId, CardId, CardName, CardType, AppOrientation]
KycPl.startOcrWithCard(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("JSON:- ", success)
    }
});
```
- CountryId: integer
    - value: Id of selected country.
- CardId: integer
    - value: Id of selected card.
- CardName: String
    - value: Name of selected card.
- CardType: integer
    - value: Type of selected card.
- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {

    }
- Error: String<Any Error Message>

### ➜ Method for scan barcode.
```js
let passArgs = [{ enableLogs: false }, BarcodeType, AppOrientation]
KycPl.startBarcode(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("JSON:- ", success)
    }
});
```
- BarcodeType: String 
    - value: Type of barcode documents.
- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {

    }
- Error: String<Any Error Message>

### ➜ Method for scan bankcard.
```js
let passArgs = [{ enableLogs: false }, AppOrientation]
KycPl.startBankCard(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("JSON:- ", success)
    }
});
```
- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {

    }
- Error: String<Any Error Message>

### ➜ Method for get face match percentages between two face.
```js
var accuraConfs = { enableLogs: false, with_face: true, face_uri: 'uri of face'};
var config = {
    feedbackTextSize: 18,
    feedBackframeMessage: 'Frame Your Face',
    feedBackAwayMessage: 'Move Phone Away',
    feedBackOpenEyesMessage: 'Keep Your Eyes Open',
    feedBackCloserMessage: 'Move Phone Closer',
    feedBackCenterMessage: 'Move Phone Center',
    feedBackMultipleFaceMessage: 'Multiple Face Detected',
    feedBackHeadStraightMessage: 'Keep Your Head Straight',
    feedBackBlurFaceMessage: 'Blur Detected Over Face',
    feedBackGlareFaceMessage: 'Glare Detected',
    setBlurPercentage: 80,
    setGlarePercentage_0: -1,
    setGlarePercentage_1: -1,
};
let passArgs = [accuraConfs, config, AppOrientation]
KycPl.startFaceMatch(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("JSON:- ", success)
    }
});
```
- accuraConfs: JSON Object
    - enableLogs: Boolean
    - with_face: Boolean
    - face_uri: URI
- config: JSON Object
    - feedbackTextSize: integer
    - feedBackframeMessage: String
    - feedBackAwayMessage: String
    - feedBackOpenEyesMessage: String
    - feedBackCloserMessage: String
    - feedBackCenterMessage: String
    - feedBackMultipleFaceMessage: String
    - feedBackHeadStraightMessage: String
    - feedBackBlurFaceMessage: String
    - feedBackGlareFaceMessage: String
    - setBlurPercentage: integer
    - setGlarePercentage_0: integer
    - setGlarePercentage_1: integer
- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {
    - with_face: Boolean
 	- status: Boolean
    - detect: URI?
    - score: Float

    }
- Error: String<Any Error Message>

### ➜ Method for liveness check.
```js
var accuraConfs = { enableLogs: false, with_face: true, face_uri: 'uri of face' };
var config = {
    feedbackTextSize: 18,
    feedBackframeMessage: 'Frame Your Face',
    feedBackAwayMessage: 'Move Phone Away',
    feedBackOpenEyesMessage: 'Keep Your Eyes Open',
    feedBackCloserMessage: 'Move Phone Closer',
    feedBackCenterMessage: 'Move Phone Center',
    feedBackMultipleFaceMessage: 'Multiple Face Detected',
    feedBackHeadStraightMessage: 'Keep Your Head Straight',
    feedBackBlurFaceMessage: 'Blur Detected Over Face',
    feedBackGlareFaceMessage: 'Glare Detected',
    setBlurPercentage: 80,
    setGlarePercentage_0: -1,
    setGlarePercentage_1: -1,
    isSaveImage: true,
    liveness_url: 'your liveness url',
    contentType: 'form_data',
    feedBackLowLightMessage: 'Low light detected',
    feedbackLowLightTolerence: 39,
    feedBackStartMessage: 'Put your face inside the oval',
    feedBackLookLeftMessage: 'Look over your left shoulder',
    feedBackLookRightMessage: 'Look over your right shoulder',
    feedBackOralInfoMessage: 'Say each digits out loud',
    enableOralVerification: false,
    codeTextColor: 'white'
};
let passArgs = [accuraConfs, config, AppOrientation]
KycPl.startLiveness(passArgs, (error, success) => {
    if (error != null) {
        //if SDK returns error in this method.
    } else {
        console.log("JSON:- ", success)
    }
});
```
- accuraConfs: JSON Object
    - enableLogs: Boolean
    - with_face: Boolean
    - face_uri: 'uri of face'
- config: JSON Object
    - feedbackTextSize: integer
    - feedBackframeMessage: String
    - feedBackAwayMessage: String
    - feedBackOpenEyesMessage: String
    - feedBackCloserMessage: String
    - feedBackCenterMessage: String
    - feedBackMultipleFaceMessage: String
    - feedBackHeadStraightMessage: String
    - feedBackBlurFaceMessage: String
    - feedBackGlareFaceMessage: String
    - setBlurPercentage: integer
    - setGlarePercentage_0: integer
    - setGlarePercentage_1: integer
    - isSaveImage: Boolean
    - liveness_url: URL **(Require)**
    - contentType: String
    - feedBackLowLightMessage: String
    - feedbackLowLightTolerence: integer,
    - feedBackStartMessage: String
    - feedBackLookLeftMessage: String
    - feedBackLookRightMessage: String
    - feedBackOralInfoMessage: String
    - enableOralVerification: Boolean,
    - codeTextColor: String

- Oriantation: String (Optional) (Default portrait)
    - value: portrait or landscape
- Success: JSON Response {
    - with_face: Boolean,
 	- status: Boolean,
    - detect: URI?,
    - image_uri: URI?,
    - video_uri: URI?,
    - fm_score: Float? (when with_face = true),
    - score: Float,

    }
- Error: String<Any Error Message>


## SDK Configurations
### AccuraConfigrations:  JSON Object

|Option|Type|Default|Description|
| :- | :- | :- | :- |
|enableLogs|boolean|false|<p>if true logs will be enabled for the app.</p><p><br>make sure to disable logs in release mode</p>|
|with_face|boolean|false|need when using liveness or face match after ocr|
|face_uri|URI Sting|undefined|Required when with_face = true|
|face_base64|Image base64 Sting|undefined|Required when with_face = true. You have to pass "face_uri" or "face_base64"|
|face1|boolean|false|need when using facematch with “with_face = false”<br><br>For Face1 set it to TRUE|
|face2|boolean|false|<p>need when using facematch with “with_face = false”</p><p>For Face2 set it to TRUE</p>|
|rg_setBlurPercentage|integer|62|0 for clean document and 100 for Blurry document|
|rg_setFaceBlurPercentage|integer|70|0 for clean face and 100 for Blurry face|
|rg_setGlarePercentage_0|integer|6|Set min percentage for glare|
|rg_setGlarePercentage_1|integer|98|Set max percentage for glare|
|rg_isCheckPhotoCopy|boolean|false|Set Photo Copy to allow photocopy document or not|
|rg_SetHologramDetection|boolean|true|<p>Set Hologram detection to verify the hologram on the face</p><p></p><p>true to check hologram on face</p><p></p><p></p>|
|rg_setLowLightTolerance|integer|39|Set light tolerance to detect light on document|
|rg_setMotionThreshold|integer|18|<p>Set motion threshold to detect motion on camera document</p><p></p><p>1 - allows 1% motion on document and</p><p></p><p>100 - it can not detect motion and allow documents to scan.</p><p></p><p></p>|
|rg_setMinFrameForValidate|integer|3|<p>Set min frame for qatar ID card for Most validated data. minFrame supports only odd numbers like 3,5...</p><p></p><p></p>|
|rg_setCameraFacing|integer|0|To set the front or back camera. allows 0,1|
|rg_setBackSide|boolean|false|set true to use backside|
|rg_setEnableMediaPlayer|boolean|true|false to disable default sound and default it is true|
|rg_customMediaURL|string|null|if given a valid URL it will download the file and use it as an alert sound.|
|SCAN_TITLE_OCR_FRONT|string|Scan Front Side of %s||
|SCAN_TITLE_OCR_BACK|string|Scan Back Side of %s||
|SCAN_TITLE_OCR|string|Scan %s||
|SCAN_TITLE_BANKCARD|string|Scan Bank Card||
|SCAN_TITLE_BARCODE|string|Scan Barcode||
|SCAN_TITLE_MRZ_PDF417_FRONT|string|Scan Front Side of Document||
|SCAN_TITLE_MRZ_PDF417_BACK|string|Now Scan Back Side of Document||
|SCAN_TITLE_DLPLATE|string|Scan Number Plate||
|ACCURA_ERROR_CODE_MOTION|string|Keep Document Steady||
|ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME|string|Keep document in frame||
|ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME|string|Bring card near to frame.||
|ACCURA_ERROR_CODE_PROCESSING|string|Processing…||
|ACCURA_ERROR_CODE_BLUR_DOCUMENT|string|Blur detect in document||
|ACCURA_ERROR_CODE_FACE_BLUR|string|Blur detected over face||
|ACCURA_ERROR_CODE_GLARE_DOCUMENT|string|Glare detect in document||
|ACCURA_ERROR_CODE_HOLOGRAM|string|Hologram Detected||
|ACCURA_ERROR_CODE_DARK_DOCUMENT|string|Low lighting detected||
|ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT|string|Can not accept Photo Copy Document||
|ACCURA_ERROR_CODE_FACE|string|Face not detected||
|ACCURA_ERROR_CODE_MRZ|string|MRZ not detected||
|ACCURA_ERROR_CODE_PASSPORT_MRZ|string|Passport MRZ not detected||
|ACCURA_ERROR_CODE_ID_MRZ|string|ID card MRZ not detected||
|ACCURA_ERROR_CODE_VISA_MRZ|string|Visa MRZ not detected||
|ACCURA_ERROR_CODE_WRONG_SIDE|string|Scanning wrong side of document||
|ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE|string|Document is upside down. Place it properly||
###
### Liveness Configurations:  JSON Object

Contact AccuraScan at contact@accurascan.com for Liveness SDK or API

|Option|Type|Default|Description|
| :- | :- | :- | :- |
|feedbackTextSize|integer|18||
|feedBackframeMessage|string|Frame Your Face||
|feedBackAwayMessage|string|Move Phone Away||
|feedBackOpenEyesMessage|string|Keep Your Eyes Open||
|feedBackCloserMessage|string|Move Phone Closer||
|feedBackCenterMessage|string|Move Phone Center||
|feedBackMultipleFaceMessage|string|Multiple Face Detected||
|feedBackHeadStraightMessage|string|Keep Your Head Straight||
|feedBackBlurFaceMessage|string|Blur Detected Over Face||
|feedBackGlareFaceMessage|string|Glare Detected||
|setBlurPercentage|integer|80|0 for clean face and 100 for Blurry face or set it -1 to remove blur filter|
|setGlarePercentage_0|integer|-1|Set min percentage for glare or set it -1 to remove glare filter|
|setGlarePercentage_1|integer|-1|Set max percentage for glare or set it -1 to remove glare filter|
|isSaveImage|boolean|true||
|liveness_url|URL string|Your liveness url|Required|
|contentType|string|form_data|param type of your liveness API|
|livenessBackground|color string|#FFC4C4C5||
|livenessCloseIcon|color string|#FF000000||
|livenessfeedbackBg|color string|#00000000||
|livenessfeedbackText|color string|#FF000000||
|feedBackLowLightMessage|string|Low light detected||
|feedbackLowLightTolerence|integer|39||
|feedBackStartMessage|string|Put your face inside the oval||
|feedBackLookLeftMessage|string|Look over your left shoulder||
|feedBackLookRightMessage|string|Look over your right shoulder||
|feedBackOralInfoMessage|string|Say each digits out loud||
|feedBackProcessingMessage|string|"Processing..."||
|isShowLogo|boolean|true|For display watermark logo images|
|enableOralVerification|boolean|true||
|codeTextColor|color string|#FF000000||

###
### Face Match Configurations:  JSON Object

|Option|Type|Default|Description|
| :- | :- | :- | :- |
|feedbackTextSize|integer|18||
|feedBackframeMessage|string|Frame Your Face||
|feedBackAwayMessage|string|Move Phone Away||
|feedBackOpenEyesMessage|string|Keep Your Eyes Open||
|feedBackCloserMessage|string|Move Phone Closer||
|feedBackCenterMessage|string|Move Phone Center||
|feedBackMultipleFaceMessage|string|Multiple Face Detected||
|feedBackHeadStraightMessage|string|Keep Your Head Straight||
|feedBackBlurFaceMessage|string|Blur Detected Over Face||
|feedBackGlareFaceMessage|string|Glare Detected||
|feedBackProcessingMessage|string|"Processing..."||
|isShowLogo|boolean|true|For display watermark logo images|
|setBlurPercentage|integer|80|0 for clean face and 100 for Blurry face or set it -1 to remove blur filter|
|setGlarePercentage_0|integer|-1|Set min percentage for glare or set it -1 to remove glare filter|
|setGlarePercentage_1|integer|-1|Set max percentage for glare or set it -1 to remove glare filter|
|backGroundColor|color string|#FFC4C4C5||
|closeIconColor|color string|#FF000000||
|feedbackBackGroundColor|color string|#00000000||
|feedbackTextColor|color string|#FF000000||

### CountryModels: 
- type: JSON Array
- contents: CardItems
- properties: 
  - id: integer
  - name: string
  - Cards: JSON Array<Card Items>
###  	 CardItems:
- type: JSON Array
- contents: JSON Objects
- properties: 
  - id: integer
  - name: string
  - type: integer
###  	 BarcodeItems:
- type: JSON Array
- contents: JSON Objects
- properties: 
  - name: string
  - type: integer
###  		 Recognition Types: 
- MRZ
- OCR
- PDF417
- BARCODE
- DL_PLATE


###  	 Mrz Types:
- passport_mrz
- id_mrz
- visa_mrz
- other_mrz

###  	 Mrz Country List:
- all
- IND,USA etc...

## License

MIT
