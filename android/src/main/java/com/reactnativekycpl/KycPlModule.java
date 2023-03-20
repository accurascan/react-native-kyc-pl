package com.reactnativekycpl;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.accurascan.ocr.mrz.model.BarcodeFormat;
import com.accurascan.ocr.mrz.model.ContryModel;
import com.accurascan.ocr.mrz.util.AccuraLog;
import com.androidnetworking.AndroidNetworking;
import com.docrecog.scan.RecogEngine;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.bridge.Callback;

import android.Manifest;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Base64;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;

//Module file of all RN extern method that you can call from RN
@ReactModule(name = KycPlModule.NAME)
public class KycPlModule extends ReactContextBaseJavaModule {
  public static final String NAME = "KycPl";
  public static Bitmap face1 = null;
  public static Bitmap face2 = null;
  public static Callback faceCL = null;
  public static Callback ocrCL = null;
  public static boolean ocrCLProcess = false;
  public static boolean isLivenessGetVideo = false;
  public static String livenessVideo = "";
  public static final String CAMERA = Manifest.permission.CAMERA;
  public static final String WRITE = Manifest.permission.WRITE_EXTERNAL_STORAGE;
  public static final int SEARCH_REQ_CODE = 0;
  private static final String TAG = OcrActivity.class.getSimpleName();
  private final String defaultAppOrientation = "portrait";
  public static JSONObject messagesConf = null;

  public static Callback pCallbackContext = null;
  public static JSONArray pArgs = null;
  public static String pAction = null;
  public static final int MY_PERMISSIONS_REQUEST_CAMERA = 100;
  private static final int MY_PERMISSIONS_REQUEST_WRITE = 101;

  public KycPlModule(ReactApplicationContext reactContext) {
      super(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
      return NAME;
  }

  @Override
  public Map<String, Object> getConstants() {
    final Map<String, Object> constants = new HashMap<>();
    constants.put("is_active_accura_kyc_pl", true);
    return constants;
  }

  public static String getSaltString() {
      String SALTCHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
      StringBuilder salt = new StringBuilder();
      Random rnd = new Random();
      while (salt.length() < 18) { // length of the random string.
          int index = (int) (rnd.nextFloat() * SALTCHARS.length());
          salt.append(SALTCHARS.charAt(index));
      }
      return salt.toString();
  }

  public static Bitmap getBitmap(ContentResolver cr, Uri url)
          throws FileNotFoundException, IOException {
      InputStream input = cr.openInputStream(url);
      Bitmap bitmap = BitmapFactory.decodeStream(input);
      input.close();
      return bitmap;
  }

  public static Bitmap getBase64ToBitmap(String base64Image) {

      byte[] decodedString = Base64.decode(base64Image, Base64.DEFAULT);
      Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
      return decodedByte;
  }

  public static String getImageUri(Bitmap bitmap, String name, String path) {
      OutputStream fOut = null;
      File file = new File(path, getSaltString() + "_" + name + ".jpg");
      try {
          fOut = new FileOutputStream(file);
      } catch (FileNotFoundException e) {
          e.printStackTrace();
      }
      bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fOut);
      try {
          fOut.flush(); // Not really required
          fOut.close();
      } catch (IOException e) {
          e.printStackTrace();
      }
      return "file://"+file.getAbsolutePath();
  }

  //Code for get license info from SDK.
  @ReactMethod
  public boolean getMetaData( Callback callbackContext ) throws JSONException {

    ocrCL = callbackContext;
    RecogEngine recogEngine = new RecogEngine();
    AccuraLog.enableLogs(false);
    recogEngine.setDialog(false);
    JSONObject results = new JSONObject();
    RecogEngine.SDKModel sdkModel = recogEngine.initEngine(getReactApplicationContext());
    if (sdkModel.i >= 0) {
      AndroidNetworking.initialize(getReactApplicationContext(), UnsafeOkHttpClient.getUnsafeOkHttpClient());
//      results.put("sdk_version", recogEngine.getVersion());
      results.put("isValid", true);
      // if OCR enable then get card list
      if (sdkModel.isOCREnable) {
        results.put("isOCR", true);
        List<ContryModel> modelList = recogEngine.getCardList(getCurrentActivity());
        JSONArray countries = new JSONArray();
        for (int i = 0; i < modelList.size(); i++) {
          JSONObject country = new JSONObject();
          country.put("name", modelList.get(i).getCountry_name());
          country.put("id", modelList.get(i).getCountry_id());
          JSONArray cards = new JSONArray();
          List<ContryModel.CardModel> cardList = modelList.get(i).getCards();
          for (int j = 0; j < cardList.size(); j++) {
            JSONObject card = new JSONObject();
            card.put("name", cardList.get(j).getCard_name());
            card.put("id", cardList.get(j).getCard_id());
            card.put("type", cardList.get(j).getCard_type());
            cards.put(card);
          }
          country.put("cards", cards);
          countries.put(country);
        }
        results.put("countries", countries);
      }
      results.put("isOCREnable", sdkModel.isOCREnable);
      results.put("isBarcode", sdkModel.isAllBarcodeEnable);
      if (sdkModel.isAllBarcodeEnable) {
        List<BarcodeFormat> CODE_NAMES = BarcodeFormat.getList();
        JSONArray barcodes = new JSONArray();
        for (int i = 0; i < CODE_NAMES.size(); i++) {
          JSONObject barcode = new JSONObject();
          barcode.put("name", CODE_NAMES.get(i).barcodeTitle);
          barcode.put("type", CODE_NAMES.get(i).formatsType);
          barcodes.put(barcode);
        }
        results.put("barcodes", barcodes);
      }
      results.put("isBankCard", sdkModel.isBankCardEnable);
      results.put("isMRZ", sdkModel.isMRZEnable);

    } else {
      results.put("isValid", false);
    }
    callbackContext.invoke(null, results.toString());
    return true;
  }

  //Code for clear facematch data
  @ReactMethod
  public boolean cleanFaceMatch( Callback callbackContext ) throws JSONException {

    KycPlModule.face1 = null;
    KycPlModule.face2 = null;
    KycPlModule.isLivenessGetVideo = false;
    KycPlModule.livenessVideo = "";
    return true;
  }

  //Code for setup custom messages and config.
  @ReactMethod
  public boolean setupAccuraConfig( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject messagesConf = args.getJSONObject(0);

    KycPlModule.messagesConf = messagesConf;
    callbackContext.invoke(null, "Messages setup successfully");
    return true;
  }

  //Code for start OCR document scanning with country & card info.
  @ReactMethod
  public boolean startOcrWithCard( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    int country = args.getInt(1);
    int card = args.getInt(2);
    String cardName = args.getString(3);
    int cardType = args.getInt(4);
    String appOrientation = args.length() > 5 ? args.getString(5) : defaultAppOrientation;
    Intent myIntent = new Intent(getCurrentActivity(), OcrActivity.class);
    if (KycPlModule.messagesConf != null) {
      myIntent = addDefaultConfigs(myIntent, KycPlModule.messagesConf);
    }
    myIntent = addDefaultConfigs(myIntent, accuraConf);
    myIntent.putExtra("app_orientation", appOrientation);
    myIntent.putExtra("type", "ocr");
    myIntent.putExtra("country_id", country);
    myIntent.putExtra("card_id", card);
    myIntent.putExtra("card_name", cardName);
    myIntent.putExtra("card_type", cardType);
    ocrCL = callbackContext;
    getCurrentActivity().startActivity(myIntent);
    return true;
  }

  //Code for start MRZ document scanning with document type.
  @ReactMethod
  public boolean startMRZ( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    String type = args.getString(1);
    String countryList = args.getString(2);
      String appOrientation = args.length() > 3 ? args.getString(3) : defaultAppOrientation;
    Intent myIntent = new Intent(getCurrentActivity(), OcrActivity.class);
    if (KycPlModule.messagesConf != null) {
      myIntent = addDefaultConfigs(myIntent, KycPlModule.messagesConf);
    }
    myIntent = addDefaultConfigs(myIntent, accuraConf);
    myIntent.putExtra("type", "mrz");
    myIntent.putExtra("country-list", countryList);
    myIntent.putExtra("sub-type", type);
    myIntent.putExtra("app_orientation", appOrientation);
    ocrCL = callbackContext;
    getCurrentActivity().startActivity(myIntent);
    return true;
  }

  //Code for start bank card scanning.
  @ReactMethod
  public boolean startBankCard( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    Intent myIntent = new Intent(getCurrentActivity(), OcrActivity.class);
    String appOrientation = args.length() > 1 ? args.getString(1) : defaultAppOrientation;
    if (KycPlModule.messagesConf != null) {
      myIntent = addDefaultConfigs(myIntent, KycPlModule.messagesConf);
    }
    myIntent = addDefaultConfigs(myIntent, accuraConf);
    myIntent.putExtra("type", "bankcard");
    myIntent.putExtra("app_orientation", appOrientation);
    ocrCL = callbackContext;
    getCurrentActivity().startActivity(myIntent);
    return true;
  }

  //Code for start barcode scanning with type.
  @ReactMethod
  public boolean startBarcode( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    String type = args.getString(1);
    String appOrientation = args.length() > 2 ? args.getString(2) : defaultAppOrientation;
    Intent myIntent = new Intent(getCurrentActivity(), OcrActivity.class);
    if (KycPlModule.messagesConf != null) {
      myIntent = addDefaultConfigs(myIntent, KycPlModule.messagesConf);
    }
    myIntent = addDefaultConfigs(myIntent, accuraConf);
    myIntent.putExtra("type", "barcode");
    myIntent.putExtra("sub-type", type);
    myIntent.putExtra("app_orientation", appOrientation);
    ocrCL = callbackContext;
    getCurrentActivity().startActivity(myIntent);
    return true;
  }

  //Code for start face match check.
  @ReactMethod
  public boolean startFaceMatch( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    JSONObject config = args.getJSONObject(1);
    String appOrientation = args.length() > 2 ? args.getString(2) : defaultAppOrientation;
    faceCL = callbackContext;
    Intent intent = new Intent(getCurrentActivity(), FaceMatchActivity.class);
    intent = addDefaultConfigs(intent, accuraConf);
    intent = addDefaultConfigs(intent, config);
    intent.putExtra("app_orientation", appOrientation);
    intent.putExtra("type", "fm");
    getCurrentActivity().startActivity(intent);
    return true;
  }

  //Code for start liveness check.
  @ReactMethod
  public boolean startLiveness( ReadableArray argsNew, Callback callbackContext ) throws JSONException {

    JSONArray args = ReactNativeJSON.convertArrayToJson(argsNew);
    JSONObject accuraConf = args.getJSONObject(0);
    if (accuraConf.has("enableLogs")) {
      boolean isLogEnable = accuraConf.getBoolean("enableLogs");
    }
    faceCL = callbackContext;
    Intent intent = new Intent(getCurrentActivity(), FaceMatchActivity.class);
    JSONObject config = args.getJSONObject(1);
    String appOrientation = args.length() > 2 ? args.getString(2) : defaultAppOrientation;
    intent = addDefaultConfigs(intent, accuraConf);
    intent = addDefaultConfigs(intent, config);
    intent.putExtra("app_orientation", appOrientation);
    intent.putExtra("type", "lv");
    getCurrentActivity().startActivity(intent);
    return true;
  }

  public Intent addDefaultConfigs(Intent intent, JSONObject config) {
    Iterator<String> iter = config.keys();
    while (iter.hasNext()) {
      String key = iter.next();
      try {
        if (config.get(key) instanceof String) {
          intent.putExtra(key, config.getString(key));
        }
        if (config.get(key) instanceof Boolean) {
          intent.putExtra(key, config.getBoolean(key));
        }
        if (config.get(key) instanceof Integer) {
          intent.putExtra(key, config.getInt(key));
        }
        if (config.get(key) instanceof Double) {
          intent.putExtra(key, config.getDouble(key));
        }
      } catch (JSONException e) {
        e.printStackTrace();
      }

    }
    return intent;
  }

}
