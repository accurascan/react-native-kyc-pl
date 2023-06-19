import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  Image,
  Dimensions,
  Platform,
  ScrollView,
  ImageBackground,
  TouchableOpacity,
  Modal,
  LogBox,
  Alert,
  ActivityIndicator,
  SafeAreaView,
  PermissionsAndroid,
} from 'react-native';
import KycPl from 'react-native-kyc-pl';
import { Dropdown } from 'react-native-material-dropdown-no-proptypes';
import Toast from 'react-native-simple-toast';

const getOrientation = () => {
  if (Dimensions.get('window').width < Dimensions.get('window').height) {
    return 'portrait';
  } else {
    return 'landscape';
  }
};
const windowHeight = Dimensions.get('window').height;
const windowWidth = Dimensions.get('window').width;

export default class App extends React.Component {
  mrzSelected = '';
  mrzCountryList = 'all';
  countrySelected = null;
  cardSelected = null;
  barcodeSelected = '';
  facematchURI = '';
  newIndex = 0;
  language = 'en';

  constructor(props) {
    super(props);
    this.state = {
      isValid: false,
      isGetToken: false,
      objSDKRes: [],
      ocrContries: [],
      ocrCards: [],
      mrzDocuments: [
        { label: 'Passport', value: 'passport_mrz' },
        { label: 'Mrz ID', value: 'id_mrz' },
        { label: 'Visa Card', value: 'visa_mrz' },
        { label: 'Other', value: 'other_mrz' },
      ],
      barcodeTypes: [],
      objScanRes: [],
      modalVisible: false,
      ocrCardName: '',

      secondImageURI: '',
      fm_score: 0.0,
      lv_score: 0.0,

      isValidCountry: true,
      isValidCard: true,
      isValidType: true,
      isValidBarcodeType: true,
      isLoading: true,
    };
  }

  //Code for get permissions of access into Android devices.
  requestPermissions = async () => {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.CAMERA,
        PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
      ]);
      console.log('granted:- ', granted);
      if (
        granted['android.permission.CAMERA'] === 'granted' &&
        granted['android.permission.WRITE_EXTERNAL_STORAGE'] === 'granted' &&
        granted['android.permission.RECORD_AUDIO'] === 'granted'
      ) {
        console.log('You can use the camera');
        return true;
      } else {
        console.log('Camera permission denied');
        return false;
      }
    } catch (err) {
      console.warn(err);
    }
  };

  //Code for check camrera permissions of access into Android devices.
  checkRequestCameraPermission = async () => {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.CAMERA
    );
    if (granted === PermissionsAndroid.RESULTS.GRANTED) {
      console.log('checkRequestCameraPermission TRUE');
      return true;
    } else {
      console.log('checkRequestCameraPermission FALSE');
      return false;
    }
  };

  //Code for check exter storage permissions of access into Android devices.
  checkRequestWritePermission = async () => {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
    );
    if (granted === PermissionsAndroid.RESULTS.GRANTED) {
      console.log('checkRequestWritePermission TRUE');
      return true;
    } else {
      console.log('checkRequestWritePermission FALSE');
      return false;
    }
  };

  componentDidMount = () => {
    LogBox.ignoreAllLogs();
    console.log('IS_ACTIVE_ACCURA_KYC:- ', KycPl.getConstants());
    this.setUpCustomMessages();
    if (Platform.OS == 'ios') {
      this.getAccuraSetup();
    } else {
      if (this.requestPermissions()) {
        this.getAccuraSetup();
      } else {
        this.setState({ isLoading: false });
      }
    }
  };

  //Code for setup message & config into document scanning window.
  setUpCustomMessages = () => {
    var config = {
      ACCURA_ERROR_CODE_MOTION:
        this.language == 'en'
          ? 'Keep Document Steady'
          : 'حافظ على ثبات المستند',
      ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME:
        this.language == 'en'
          ? 'Keep document in frame'
          : 'احتفظ بالمستند في الإطار',
      ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME:
        this.language == 'en'
          ? 'Bring card near to frame'
          : 'إحضار البطاقة بالقرب من الإطار',
      ACCURA_ERROR_CODE_PROCESSING:
        this.language == 'en' ? 'Processing…' : 'يعالج…',
      ACCURA_ERROR_CODE_BLUR_DOCUMENT:
        this.language == 'en'
          ? 'Blur detect in document'
          : 'كشف التمويه في المستند',
      ACCURA_ERROR_CODE_FACE_BLUR:
        this.language == 'en'
          ? 'Blur detected over face'
          : 'تم الكشف عن ضبابية على الوجه',
      ACCURA_ERROR_CODE_GLARE_DOCUMENT:
        this.language == 'en'
          ? 'Glare detect in document'
          : 'كشف الوهج في المستند',
      ACCURA_ERROR_CODE_HOLOGRAM:
        this.language == 'en'
          ? 'Hologram Detected'
          : 'تم الكشف عن صورة ثلاثية الأبعاد',
      ACCURA_ERROR_CODE_DARK_DOCUMENT:
        this.language == 'en'
          ? 'Low lighting detected'
          : 'تم الكشف عن إضاءة منخفضة',
      ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT:
        this.language == 'en'
          ? 'Can not accept Photo Copy Document'
          : 'لا يمكن قبول مستند نسخ الصور',
      ACCURA_ERROR_CODE_FACE:
        this.language == 'en' ? 'Face not detected' : 'لم يتم الكشف عن الوجه',
      ACCURA_ERROR_CODE_MRZ:
        this.language == 'en' ? 'MRZ not detected' : 'لم يتم الكشف عن MRZ',
      ACCURA_ERROR_CODE_PASSPORT_MRZ:
        this.language == 'en'
          ? 'Passport MRZ not detected'
          : 'لم يتم الكشف عن MRZ جواز سفر',
      ACCURA_ERROR_CODE_ID_MRZ:
        this.language == 'en'
          ? 'ID card MRZ not detected'
          : 'لم يتم الكشف عن بطاقة الهوية MRZ',
      ACCURA_ERROR_CODE_VISA_MRZ:
        this.language == 'en'
          ? 'Visa MRZ not detected'
          : 'لم يتم الكشف عن Visa MRZ',
      ACCURA_ERROR_CODE_WRONG_SIDE:
        this.language == 'en'
          ? 'Scanning wrong side of document'
          : 'مسح الجانب الخطأ من المستند',
      ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE:
        this.language == 'en'
          ? 'Document is upside down. Place it properly'
          : 'المستند مقلوب. ضعه بشكل صحيح',

      IS_SHOW_LOGO: false,
      SCAN_TITLE_OCR_FRONT:
        this.language == 'en' ? 'Scan Front Side of' : 'مسح الجانب الأمامي من',
      SCAN_TITLE_OCR_BACK:
        this.language == 'en' ? 'Scan Back Side of' : 'مسح الجانب الخلفي من',
      SCAN_TITLE_OCR: this.language == 'en' ? 'Scan' : 'مسح',
      SCAN_TITLE_BANKCARD:
        this.language == 'en' ? 'Scan Bank Card' : 'مسح البطاقة المصرفية',
      SCAN_TITLE_BARCODE:
        this.language == 'en' ? 'Scan Barcode' : 'مسح الرمز الشريطى',
      SCAN_TITLE_MRZ_PDF417_FRONT:
        this.language == 'en'
          ? 'Scan Front Side of Document'
          : 'مسح الوجه الأمامي للمستند',
      SCAN_TITLE_MRZ_PDF417_BACK:
        this.language == 'en'
          ? 'Now Scan Back Side of Document'
          : 'الآن مسح الجانب الخلفي من المستند',
      SCAN_TITLE_DLPLATE:
        this.language == 'en' ? 'Scan Number Plate' : 'مسح رقم اللوحة',
    };
    //Method for setup config into native OS.
    KycPl.setupAccuraConfig([config], (error, response) => {
      if (error != null) {
        console.log('Failur!', error);
      } else {
        console.log('Message:- ', response);
      }
    });
  };

  //Code for get license info.
  getAccuraSetup = () => {
    //Method for get license info from native OS.
    KycPl.getMetaData((error, response) => {
      if (error != null) {
        console.log('Failur!', error);
        this.setState({ isLoading: false });
      } else {
        const res = this.getResultJSON(response);
        var newContries = [];
        res?.countries?.map(
          (item) =>
            (newContries = [
              ...newContries,
              { label: item.name, value: item.id },
            ])
        );

        var newBarcodeTypes = [];
        res?.barcodes?.map(
          (item) =>
            (newBarcodeTypes = [
              ...newBarcodeTypes,
              { label: item.name, value: item.type },
            ])
        );
        this.setState({
          objSDKRes: res,
          ocrContries: newContries,
          isValid: res.isValid,
          barcodeTypes: newBarcodeTypes,
          isLoading: false,
        });
      }
    });
  };

  showAlert = (title, message) => {
    if (Platform.OS === 'ios') {
      Alert.alert(title, message, [
        {
          text: 'OK',
          onPress: () => console.log('Cancel Pressed'),
          style: 'cancel',
        },
      ]);
    } else {
      Toast.show(message, Toast.LONG);
    }
  };

  getResultJSON = (jsonString) => {
    var json;
    try {
      // eslint-disable-next-line no-eval
      json = eval(jsonString);
    } catch (exception) {
      try {
        json = JSON.parse(jsonString);
      } catch (exception) {
        json = null;
        console.log('NOT VAID JSON');
      }
    }

    if (json) {
      console.log('VAID JSON');
      return json;
    }
    return null;
  };

  //Code for scan OCR documents with country & card info.
  onPressOCR = () => {
    var isValid = true;
    if (this.countrySelected == null || this.countrySelected == '') {
      this.setState({ isValidCountry: false });
      isValid = false;
    }

    if (this.cardSelected == null || this.cardSelected == '') {
      this.setState({ isValidCard: false });
      isValid = false;
    }

    if (isValid) {
      let passArgs = [
        { enableLogs: false },
        this.countrySelected.id,
        this.cardSelected.id,
        this.cardSelected.name,
        this.cardSelected.type,
        getOrientation(),
      ]; //[{"enableLogs":false},1,41,"Emirates National ID",0,"portrait-primary"]
      //Method for start OCR scaning from native OS.
      KycPl.startOcrWithCard(passArgs, (error, response) => {
        if (error != null) {
          console.log('Failur!', error);
          this.showAlert('Failur!', error);
        } else {
          const res = this.getResultJSON(response);
          this.setState({ modalVisible: true, objScanRes: res });
        }
      });
    }
  };

  //Code for scan MRZ documents with document type.
  onPressMRZ = () => {
    var isValid = true;
    if (this.mrzSelected == '' || this.mrzSelected == null) {
      this.setState({ isValidType: false });
      isValid = false;
    }

    if (isValid) {
      let passArgs = [
        { enableLogs: false },
        this.mrzSelected,
        this.mrzCountryList,
        getOrientation(),
      ];
      //Method for start MRZ scaning from native OS.
      KycPl.startMRZ(passArgs, (error, response) => {
        if (error != null) {
          console.log('Failur!', error);
          this.showAlert('Failur!', error);
        } else {
          const res = this.getResultJSON(response);
          this.setState({ modalVisible: true, objScanRes: res });
        }
      });
    }
  };

  //Code for scan Barcode with barcode type.
  onPressBarcode = () => {
    var isValid = true;
    if (this.barcodeSelected?.toString() == '') {
      this.setState({ isValidBarcodeType: false });
      isValid = false;
    }

    if (isValid) {
      let passArgs = [
        { enableLogs: false },
        this.barcodeSelected,
        getOrientation(),
      ];
      //Method for start MRZ scaning from native OS.
      KycPl.startBarcode(passArgs, (error, response) => {
        if (error != null) {
          console.log('Failur!', error);
          this.showAlert('Failur!', error);
        } else {
          const res = this.getResultJSON(response);
          this.setState({ modalVisible: true, objScanRes: res });
        }
      });
    }
  };

  //Code for scan bank card.
  onPressBankcard = () => {
    let passArgs = [{ enableLogs: false }, getOrientation()];
    //Method for start bank card scaning from native OS.
    KycPl.startBankCard(passArgs, (error, response) => {
      if (error != null) {
        console.log('Failur!', error);
        this.showAlert('Failur!', error);
      } else {
        const res = this.getResultJSON(response);
        this.setState({ modalVisible: true, objScanRes: res });
      }
    });
  };

  //Code for check liveness.
  onPressStartLiveness = () => {
    var accuraConfs = {
      enableLogs: false,
      with_face: true,
      face_uri: this.facematchURI,
    };
    var config = {
      feedbackTextSize: 18,
      feedBackframeMessage:
        this.language == 'en' ? 'Frame Your Face' : 'ضع إطارًا لوجهك',
      feedBackAwayMessage:
        this.language == 'en' ? 'Move Phone Away' : 'انقل الهاتف بعيدًا',
      feedBackOpenEyesMessage:
        this.language == 'en' ? 'Keep Your Eyes Open' : 'أبق أعينك مفتوحة',
      feedBackCloserMessage:
        this.language == 'en' ? 'Move Phone Closer' : 'نقل الهاتف أقرب',
      feedBackCenterMessage:
        this.language == 'en' ? 'Move Phone Center' : 'نقل مركز الهاتف',
      feedBackMultipleFaceMessage:
        this.language == 'en'
          ? 'Multiple Face Detected'
          : 'تم اكتشاف وجوه متعددة',
      feedBackHeadStraightMessage:
        this.language == 'en'
          ? 'Keep Your Head Straight'
          : 'حافظ على استقامة رأسك',
      feedBackBlurFaceMessage:
        this.language == 'en'
          ? 'Blur Detected Over Face'
          : 'تم اكتشاف ضبابية على الوجه',
      feedBackGlareFaceMessage:
        this.language == 'en' ? 'Glare Detected' : 'تم الكشف عن الوهج',
      // <!--// 0 for clean face and 100 for Blurry face or set it -1 to remove blur filter-->
      setBlurPercentage: -1,
      // <!--// Set min percentage for glare or set it -1 to remove glare filter-->
      setGlarePercentage_0: -1,
      // <!--// Set max percentage for glare or set it -1 to remove glare filter-->
      setGlarePercentage_1: -1,
      isSaveImage: true,
      liveness_url: 'your liveness url',
    };

    let passArgs = [accuraConfs, config, getOrientation()];
    //Method for start liveness checking from native OS.
    KycPl.startLiveness(passArgs, (error, response) => {
      if (error != null) {
        console.log('Failur!', error);
        this.showAlert('Failur!', error);
        this.setState({ modalVisible: true });
      } else {
        const res = this.getResultJSON(response);
        this.setState({
          fm_score: res.fm_score,
          lv_score: res.score,
          secondImageURI: res.detect,
          modalVisible: true,
        });
      }
    });
  };

  //Code for check face match.
  onPressFaceMatch = (withFace = false, face1 = false, face2 = false) => {
    var accuraConfs = {
      with_face: withFace,
      face_uri: this.facematchURI,
      enableLogs: false,
    };
    if (!withFace) {
      delete accuraConfs.face_uri;
    }
    if (face1) {
      face2 = false;
    }
    if (face2) {
      face1 = false;
    }
    accuraConfs.face1 = face1;
    accuraConfs.face2 = face2;
    var config = {
      feedbackTextSize: 18,
      feedBackLowLightMessage:
        this.language == 'en'
          ? 'Low light detected'
          : 'تم الكشف عن إضاءة منخفضة',
      feedBackStartMessage:
        this.language == 'en'
          ? 'Put your face inside the oval'
          : 'ضع وجهك داخل الشكل البيضاوي',
      feedBackframeMessage:
        this.language == 'en' ? 'Frame Your Face' : 'ضع إطارًا لوجهك',
      feedBackAwayMessage:
        this.language == 'en' ? 'Move Phone Away' : 'انقل الهاتف بعيدًا',
      feedBackOpenEyesMessage:
        this.language == 'en' ? 'Keep Your Eyes Open' : 'أبق أعينك مفتوحة',
      feedBackCloserMessage:
        this.language == 'en' ? 'Move Phone Closer' : 'نقل الهاتف أقرب',
      feedBackCenterMessage:
        this.language == 'en' ? 'Move Phone Center' : 'نقل مركز الهاتف',
      feedBackMultipleFaceMessage:
        this.language == 'en'
          ? 'Multiple Face Detected'
          : 'تم اكتشاف وجوه متعددة',
      feedBackHeadStraightMessage:
        this.language == 'en'
          ? 'Keep Your Head Straight'
          : 'حافظ على استقامة رأسك',
      feedBackBlurFaceMessage:
        this.language == 'en'
          ? 'Blur Detected Over Face'
          : 'تم اكتشاف ضبابية على الوجه',
      feedBackGlareFaceMessage:
        this.language == 'en' ? 'Glare Detected' : 'تم الكشف عن الوهج',
      // <!--// 0 for clean face and 100 for Blurry face or set it -1 to remove blur filter-->
      setBlurPercentage: 80,
      // <!--// Set min percentage for glare or set it -1 to remove glare filter-->
      setGlarePercentage_0: -1,
      // <!--// Set max percentage for glare or set it -1 to remove glare filter-->
      setGlarePercentage_1: -1,
      isShowLogo: true,
      feedBackProcessingMessage:
        this.language == 'en' ? 'Processing...' : 'يعالج...',
    };
    let passArgs = [accuraConfs, config, getOrientation()];
    //Method for start face match checking from native OS.
    KycPl.startFaceMatch(passArgs, (error, response) => {
      if (error != null) {
        console.log('Failur!', error);
        this.showAlert('Failur!', error);
        this.setState({ modalVisible: true });
      } else {
        const res = this.getResultJSON(response);
        this.setState({
          fm_score: res.score,
          lv_score: 0.0,
          secondImageURI: res.detect,
          modalVisible: true,
        });
      }
    });
  };

  render() {
    return (
      <ImageBackground
        source={require('./assets/images/background.png')}
        style={styles.backgroundView}
      >
        {this.state.isLoading ? (
          <View
            style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}
          >
            <ActivityIndicator size="large" color="#d32d38" />
          </View>
        ) : (
          <>
            {
              //UI for scanning options
              <SafeAreaView>
                <ScrollView>
                  <View style={styles.container}>
                    <Image
                      source={require('./assets/images/logo.png')}
                      style={styles.logoView}
                    />
                    {this.state.isValid ? (
                      <>
                        {this.state.objSDKRes?.isOCR ? (
                          <View style={[styles.viewOption, { height: 270 }]}>
                            <Text style={styles.optionTitle}>
                              {'Scan OCR Documents'}
                            </Text>
                            <Dropdown
                              style={{
                                width: windowWidth * 0.75,
                                backgroundColor: 'none',
                                marginTop: -20,
                              }}
                              label="Select Country"
                              data={this.state.ocrContries}
                              onChangeText={(value, index) => {
                                console.log(
                                  'Inex:- ',
                                  index,
                                  'value:- ',
                                  value
                                );
                                this.countrySelected =
                                  this.state.objSDKRes?.countries[index];
                                console.log('Country:- ', this.countrySelected);
                                this.cardSelected = null;

                                var selectedCountry =
                                  this.state.objSDKRes?.countries[index];
                                var newCards = [];
                                selectedCountry?.cards?.map(
                                  (item) =>
                                    (newCards = [
                                      ...newCards,
                                      { label: item.name, value: item.id },
                                    ])
                                );
                                this.setState({
                                  ocrCards: newCards,
                                  isValidCountry: true,
                                  ocrCardName: '',
                                });
                              }}
                            />
                            {!this.state.isValidCountry ? (
                              <Text style={styles.lblError}>
                                {'Please select country first.'}
                              </Text>
                            ) : (
                              <View />
                            )}
                            <Dropdown
                              style={{
                                width: windowWidth * 0.75,
                                backgroundColor: 'none',
                                marginTop: -20,
                              }}
                              label="Select Card"
                              value={this.state.ocrCardName}
                              data={this.state.ocrCards}
                              onChangeText={(value, index) => {
                                console.log(
                                  'Inex:- ',
                                  index,
                                  'value:- ',
                                  value
                                );
                                this.cardSelected =
                                  this.countrySelected.cards[index];
                                console.log('Card:- ', this.cardSelected);
                                this.setState({
                                  isValidCard: true,
                                  ocrCardName:
                                    this.countrySelected.cards[index].name,
                                });
                              }}
                            />
                            {!this.state.isValidCard ? (
                              <Text style={styles.lblError}>
                                {'Please select card first.'}
                              </Text>
                            ) : (
                              <View />
                            )}
                            <TouchableOpacity
                              style={styles.optionButton}
                              onPress={this.onPressOCR}
                            >
                              <Text style={styles.optionButtonText}>
                                Start OCR
                              </Text>
                            </TouchableOpacity>
                          </View>
                        ) : (
                          <View />
                        )}

                        {this.state.objSDKRes?.isMRZ ? (
                          <View style={[styles.viewOption]}>
                            <Text style={styles.optionTitle}>
                              {'Scan MRZ Documents'}
                            </Text>
                            <Dropdown
                              style={{
                                width: windowWidth * 0.75,
                                backgroundColor: 'none',
                                marginTop: -20,
                              }}
                              label="Select Type"
                              data={this.state.mrzDocuments}
                              onChangeText={(value, index) => {
                                console.log(
                                  'Inex:- ',
                                  index,
                                  'value:- ',
                                  value
                                );
                                this.mrzSelected = value;
                                this.setState({ isValidType: true });
                              }}
                            />
                            {!this.state.isValidType ? (
                              <Text style={styles.lblError}>
                                {'Please select MRZ type first.'}
                              </Text>
                            ) : (
                              <View />
                            )}
                            <TouchableOpacity
                              style={styles.optionButton}
                              onPress={this.onPressMRZ}
                            >
                              <Text style={styles.optionButtonText}>
                                Start MRZ
                              </Text>
                            </TouchableOpacity>
                          </View>
                        ) : (
                          <View />
                        )}

                        {this.state.objSDKRes?.isBarcode ? (
                          <View style={[styles.viewOption]}>
                            <Text style={styles.optionTitle}>
                              {'Scan Barcode'}
                            </Text>
                            <Dropdown
                              style={{
                                width: windowWidth * 0.75,
                                backgroundColor: 'none',
                                marginTop: -20,
                              }}
                              label="Select Type"
                              data={this.state.barcodeTypes}
                              onChangeText={(value, index) => {
                                console.log(
                                  'Inex:- ',
                                  index,
                                  'value:- ',
                                  value
                                );
                                this.barcodeSelected = value;
                                this.setState({ isValidBarcodeType: true });
                              }}
                            />
                            {!this.state.isValidBarcodeType ? (
                              <Text style={styles.lblError}>
                                {'Please select barcode type first.'}
                              </Text>
                            ) : (
                              <View />
                            )}
                            <TouchableOpacity
                              style={styles.optionButton}
                              onPress={this.onPressBarcode}
                            >
                              <Text style={styles.optionButtonText}>
                                Start Barcode
                              </Text>
                            </TouchableOpacity>
                          </View>
                        ) : (
                          <View />
                        )}

                        {this.state.objSDKRes?.isBankCard ? (
                          <View style={[styles.viewOption, { height: 170 }]}>
                            <Text style={styles.optionTitle}>
                              {'Scan Bankcard'}
                            </Text>
                            <Text style={styles.optionDescription}>
                              {
                                'You can scan any bank card here by tap on "Start Bankcard" button.'
                              }
                            </Text>
                            <TouchableOpacity
                              style={styles.optionButton}
                              onPress={this.onPressBankcard}
                            >
                              <Text style={styles.optionButtonText}>
                                Start Bankcard
                              </Text>
                            </TouchableOpacity>
                          </View>
                        ) : (
                          <View />
                        )}
                      </>
                    ) : (
                      <View
                        style={{
                          height: windowHeight * 0.6,
                          width: '100%',
                          justifyContent: 'center',
                          alignItems: 'center',
                        }}
                      >
                        <Image
                          source={require('./assets/images/license.png')}
                          style={styles.licenseView}
                        />
                        <Text style={styles.optionDescription}>
                          {'License you provided for sacnning is invalid.'}
                        </Text>
                        <Text
                          style={{
                            textDecorationLine: 'underline',
                            fontSize: 16,
                            marginTop: 10,
                          }}
                        >
                          {'www.accurascan.com'}
                        </Text>
                      </View>
                    )}
                  </View>
                </ScrollView>
              </SafeAreaView>
            }
          </>
        )}
        {this.generateResult(this.state.objScanRes)}
      </ImageBackground>
    );
  }

  //Code for display result popup when complete scanning.
  generateResult = (result) => {
    if (result == undefined || result == null) {
      return;
    }

    if (result.hasOwnProperty('face')) {
      this.facematchURI = result?.face;
    }
    var sides = ['front_data', 'back_data'];

    return (
      <Modal
        animationType="fade"
        transparent={true}
        visible={this.state.modalVisible}
        onRequestClose={() => {
          this.setState({
            modalVisible: false,
            secondImageURI: '',
            lv_score: 0.0,
            fm_score: 0.0,
          });
        }}
      >
        <View style={{ flex: 1, padding: 20, backgroundColor: '#00000066' }}>
          <ScrollView showsVerticalScrollIndicator={false}>
            <View style={styles.modalView}>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  marginBottom: 30,
                }}
              >
                <Text
                  style={{ fontWeight: 'bold', fontSize: 23, color: '#d22c39' }}
                >
                  Accura Result
                </Text>
                <TouchableOpacity
                  style={{}}
                  onPress={() =>
                    this.setState({
                      modalVisible: false,
                      secondImageURI: '',
                      lv_score: 0.0,
                      fm_score: 0.0,
                    })
                  }
                >
                  <Text style={{ fontSize: 28, fontWeight: 'bold' }}>✖</Text>
                </TouchableOpacity>
              </View>
              {result.hasOwnProperty('face') ? (
                <View style={styles.modelFace}>
                  <View
                    style={{
                      width: '100%',
                      justifyContent: 'center',
                      alignItems: 'center',
                      flexDirection: 'row',
                    }}
                  >
                    <Image
                      style={styles.faceImageView}
                      source={{ uri: result?.face }}
                    />
                    {this.state.secondImageURI !== '' ? (
                      <Image
                        style={[styles.faceImageView, { marginLeft: 50 }]}
                        source={{ uri: this.state.secondImageURI }}
                      />
                    ) : (
                      <View />
                    )}
                  </View>
                  <View
                    style={{
                      width: '100%',
                      alignItems: 'center',
                      flexDirection: 'row',
                      marginVertical: 10,
                      justifyContent: 'space-around',
                    }}
                  >
                    <TouchableOpacity
                      style={{}}
                      onPress={() => {
                        this.setState({ modalVisible: false });
                        this.onPressStartLiveness();
                      }}
                    >
                      <View style={styles.btnView}>
                        <Image
                          style={{ aspectRatio: 1, width: 18 }}
                          source={require('./assets/images/ic_liveness.png')}
                        />
                        <Text
                          style={{
                            color: 'white',
                            fontSize: 15,
                            marginLeft: 5,
                          }}
                        >
                          LIVENESS
                        </Text>
                      </View>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={{}}
                      onPress={() => {
                        this.setState({ modalVisible: false });
                        this.onPressFaceMatch(true);
                      }}
                    >
                      <View style={styles.btnView}>
                        <Image
                          style={{ aspectRatio: 1, width: 18 }}
                          source={require('./assets/images/ic_biometric.png')}
                        />
                        <Text
                          style={{
                            color: 'white',
                            fontSize: 15,
                            marginLeft: 5,
                          }}
                        >
                          FACE MATCH
                        </Text>
                      </View>
                    </TouchableOpacity>
                  </View>
                  <View
                    style={{
                      width: '100%',
                      alignItems: 'center',
                      flexDirection: 'row',
                      marginBottom: 10,
                      justifyContent: 'space-around',
                    }}
                  >
                    <Text style={{ fontSize: 15, fontWeight: 'bold' }}>
                      {parseInt(this.state.lv_score).toFixed(2) + '%'}
                    </Text>
                    <Text style={{ fontSize: 15, fontWeight: 'bold' }}>
                      {parseInt(this.state.fm_score).toFixed(2) + '%'}
                    </Text>
                  </View>
                </View>
              ) : (
                <View />
              )}

              <View style={{ marginTop: -20 }}>
                {sides.map((side, index) => {
                  return (
                    <View key={index.toString()}>
                      {result.hasOwnProperty(side) ? (
                        Object.keys(result[side]).length > 0 ? (
                          <View>
                            {index === 0 ? (
                              <View style={styles.dataHeader}>
                                <Text
                                  style={{ fontSize: 18, fontWeight: 'bold' }}
                                >
                                  {this.getResultType(result?.type)}
                                </Text>
                              </View>
                            ) : (
                              <View style={styles.dataHeader}>
                                <Text
                                  style={{ fontSize: 18, fontWeight: 'bold' }}
                                >
                                  {'OCR Back'}
                                </Text>
                              </View>
                            )}
                            {Object.keys(result[side]).map((key, index) => {
                              return (
                                <View key={index.toString()}>
                                  {key !== 'PDF417' ? (
                                    ![
                                      'signature',
                                      'front_img',
                                      'back_img',
                                    ].includes(key) ? (
                                      result.type == 'MRZ' ? (
                                        <View style={styles.dataItem}>
                                          <Text style={styles.lblDataTitle}>
                                            {this.getMRZLable(key)}
                                          </Text>
                                          <Text style={styles.lblDataText}>
                                            {result[side][key].toString()}
                                          </Text>
                                        </View>
                                      ) : (
                                        <View style={styles.dataItem}>
                                          <Text style={styles.lblDataTitle}>
                                            {key}
                                          </Text>
                                          <Text style={styles.lblDataText}>
                                            {result[side][key].toString()}
                                          </Text>
                                        </View>
                                      )
                                    ) : key === 'signature' ? (
                                      <View style={styles.dataItem}>
                                        <Text style={styles.lblDataTitle}>
                                          {key}
                                        </Text>
                                        <Image
                                          style={styles.signatureImage}
                                          source={{ uri: result[side][key] }}
                                        />
                                      </View>
                                    ) : (
                                      <View />
                                    )
                                  ) : (
                                    <View />
                                  )}
                                </View>
                              );
                            })}
                          </View>
                        ) : (
                          <View />
                        )
                      ) : (
                        <View />
                      )}
                    </View>
                  );
                })}
                {result.hasOwnProperty('mrz_data') ? (
                  Object.keys(result.mrz_data).length > 0 ? (
                    <>
                      <View style={styles.dataHeader}>
                        <Text style={{ fontSize: 18, fontWeight: 'bold' }}>
                          {'MRZ'}
                        </Text>
                      </View>
                      {Object.keys(result.mrz_data).map((key, index) => {
                        return (
                          <View style={styles.dataItem} key={index.toString()}>
                            <Text style={styles.lblDataTitle}>
                              {this.getMRZLable(key)}
                            </Text>
                            <Text style={styles.lblDataText}>
                              {result.mrz_data[key].toString()}
                            </Text>
                          </View>
                        );
                      })}
                    </>
                  ) : (
                    <View />
                  )
                ) : (
                  <View />
                )}
              </View>
              {result.hasOwnProperty('front_img') ? (
                <View>
                  <View style={styles.dataHeader}>
                    <Text style={{ fontSize: 18, fontWeight: 'bold' }}>
                      {'FRONT SIDE'}
                    </Text>
                  </View>
                  <View style={{ marginVertical: 10, borderRadius: 10 }}>
                    <Image
                      style={styles.cardImage}
                      source={{ uri: result.front_img }}
                    />
                  </View>
                </View>
              ) : (
                <View />
              )}

              {result.hasOwnProperty('back_img') ? (
                <View>
                  <View style={styles.dataHeader}>
                    <Text style={{ fontSize: 18, fontWeight: 'bold' }}>
                      {'BACK SIDE'}
                    </Text>
                  </View>
                  <View style={{ marginVertical: 10, borderRadius: 10 }}>
                    <Image
                      style={styles.cardImage}
                      source={{ uri: result.back_img }}
                    />
                  </View>
                </View>
              ) : (
                <View />
              )}
            </View>
          </ScrollView>
        </View>
      </Modal>
    );
  };

  getResultType = (type) => {
    switch (type) {
      case 'BANKCARD':
        return 'Bank Card Data';
      case 'DL_PLATE':
        return 'Vehicle Plate';
      case 'BARCODE':
        return 'Barcode Data';
      case 'PDF417':
        return 'PDF417 Barcode';
      case 'OCR':
        return 'OCR Front';
      case 'MRZ':
        return 'MRZ';
      case 'BARCODEPDF417':
        return 'USA DL Result';
      default:
        return 'Front Side';
    }
  };

  getMRZLable = (key) => {
    var lableText = '';
    switch (key) {
      case 'mrz':
        lableText += 'MRZ';
        break;
      case 'placeOfBirth':
        lableText += 'Place Of Birth';
        break;
      case 'retval':
        lableText += 'Retval';
        break;
      case 'givenNames':
        lableText += 'First Name';
        break;
      case 'country':
        lableText += 'Country';
        break;
      case 'surName':
        lableText += 'Last Name';
        break;
      case 'expirationDate':
        lableText += 'Date of Expiry';
        break;
      case 'passportType':
        lableText += 'Document Type';
        break;
      case 'personalNumber':
        lableText += 'Other ID';
        break;
      case 'correctBirthChecksum':
        lableText += 'Correct Birth Check No.';
        break;
      case 'correctSecondrowChecksum':
        lableText += 'Correct Second Row Check No.';
        break;
      case 'personalNumberChecksum':
        lableText += 'Other Id Check No.';
        break;
      case 'secondRowChecksum':
        lableText += 'Second Row Check No.';
        break;
      case 'expirationDateChecksum':
        lableText += 'Expiration Check No.';
        break;
      case 'correctPersonalChecksum':
        lableText += 'Correct Document check No.';
        break;
      case 'passportNumber':
        lableText += 'Document No.';
        break;
      case 'correctExpirationChecksum':
        lableText += 'Correct Expiration Check No.';
        break;
      case 'sex':
        lableText += 'Sex';
        break;
      case 'birth':
        lableText += 'Date Of Birth';
        break;
      case 'birthChecksum':
        lableText += 'Birth Check No.';
        break;
      case 'personalNumber2':
        lableText += 'Other ID2';
        break;
      case 'correctPassportChecksum':
        lableText += 'Correct Document check No.';
        break;
      case 'placeOfIssue':
        lableText += 'Place Of Issue';
        break;
      case 'nationality':
        lableText += 'Nationality';
        break;
      case 'passportNumberChecksum':
        lableText += 'Document check No.';
        break;
      case 'issueDate':
        lableText += 'Date Of Issue';
        break;
      case 'departmentNumber':
        lableText += 'Department No.';
        break;
      default:
        lableText += key;
        break;
    }
    return lableText;
  };
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginHorizontal: 20,
    marginVertical: 10,
    alignItems: 'center',
  },
  backgroundView: {
    flex: 1,
  },
  logoView: {
    width: 180,
    height: 90,
    marginTop: 10,
    resizeMode: 'stretch',
  },
  viewOption: {
    width: '100%',
    marginVertical: 20,
    height: 210,
    borderRadius: 20,
    backgroundColor: 'white',
    paddingVertical: 20,
    paddingHorizontal: 20,
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.9,
    shadowRadius: 3,
    elevation: 3,
  },
  optionTitle: {
    color: '#d32d38',
    fontWeight: 'bold',
    fontSize: 20,
  },
  licenseView: {
    width: 180,
    height: 180,
    marginVertical: 10,
    resizeMode: 'stretch',
  },
  optionDescription: {
    color: '#d22c39',
    fontWeight: 'bold',
    fontSize: 17,
    textAlign: 'center',
  },
  optionButton: {
    backgroundColor: 'black',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.9,
    shadowRadius: 3,
    elevation: 3,
  },
  optionButtonText: {
    fontWeight: 'bold',
    color: 'white',
  },
  lblError: {
    textAlign: 'left',
    width: '100%',
    fontSize: 12,
    color: 'red',
    marginTop: -8,
    paddingHorizontal: 10,
  },
  modalView: {
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 20,
    flex: 1,
  },
  modelFace: {
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  faceImageView: {
    height: 140,
    width: 100,
    borderRadius: 10,
    backgroundColor: 'lightgrey',
  },
  btnView: {
    flexDirection: 'row',
    backgroundColor: '#d22c39',
    width: 130,
    paddingVertical: 10,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 5,
  },
  dataHeader: {
    width: '100%',
    backgroundColor: 'lightgrey',
    padding: 10,
  },
  dataItem: {
    width: '100%',
    borderBottomColor: 'lightgrey',
    borderBottomWidth: 1,
    paddingHorizontal: 5,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  lblDataTitle: {
    fontSize: 16,
    color: '#d22c39',
    flex: 2,
    paddingHorizontal: 5,
  },
  lblDataText: {
    fontSize: 16,
    flex: 3,
  },
  signatureImage: {
    aspectRatio: 3 / 2,
    width: '50%',
    borderRadius: 10,
    resizeMode: 'contain',
    alignSelf: 'flex-start',
  },
  cardImage: {
    aspectRatio: 3 / 2,
    width: '100%',
    borderRadius: 10,
    resizeMode: 'contain',
    backgroundColor: 'lightgrey',
  },
  offlineContainer: {
    height: Dimensions.get('window').height,
    backgroundColor: '#0e3360',
    alignItems: 'center',
    alignContent: 'center',
    justifyContent: 'center',
    flexGrow: 1,
  },
  offlineText: {
    color: 'white',
    fontSize: 25,
    fontWeight: 'bold',
  },
  offlineHint: {
    fontSize: 18,
    fontWeight: '300',
    color: 'gray',
  },
});
