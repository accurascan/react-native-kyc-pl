package com.reactnativekycpl;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.pm.ActivityInfo;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import com.accurascan.ocr.mrz.CameraView;
import com.accurascan.ocr.mrz.interfaces.OcrCallback;
import com.accurascan.ocr.mrz.model.CardDetails;
import com.accurascan.ocr.mrz.model.OcrData;
import com.accurascan.ocr.mrz.model.PDF417Data;
import com.accurascan.ocr.mrz.model.RecogResult;
import com.accurascan.ocr.mrz.motiondetection.SensorsActivity;
import com.accurascan.ocr.mrz.util.AccuraLog;
import com.docrecog.scan.MRZDocumentType;
import com.docrecog.scan.RecogEngine;
import com.docrecog.scan.RecogType;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.net.URL;
import java.net.URLConnection;
import java.util.Arrays;
import java.util.List;

import static com.reactnativekycpl.KycPlModule.getImageUri;
import static com.reactnativekycpl.KycPlModule.getSaltString;

//Activity for scanning document window.
public class OcrActivity extends SensorsActivity implements OcrCallback {

    private static final String TAG = OcrActivity.class.getSimpleName();
    private CameraView cameraView;
    private View viewLeft, viewRight, borderFrame;
    private TextView tvTitle, tvScanMessage;
    private ImageView imageFlip;
    private int cardId;
    private int countryId;
    private String mrzCountryList;
    RecogType recogType;
    private String cardName;
    private boolean isBack = false;
    private MRZDocumentType mrzType;
    Resources res;

    private static class MyHandler extends Handler {
        private final WeakReference<OcrActivity> mActivity;

        public MyHandler(OcrActivity activity) {
            mActivity = new WeakReference<>(activity);
        }

        @Override
        public void handleMessage(Message msg) {
            OcrActivity activity = mActivity.get();
            if (activity != null) {
                String s = "";
                if (msg.obj instanceof String) s = (String) msg.obj;
                switch (msg.what) {
                    case 0:
                        activity.tvTitle.setText(s);
                        break;
                    case 1:
                        activity.tvScanMessage.setText(s);
                        break;
                    case 2:
                        if (activity.cameraView != null)
                            activity.cameraView.flipImage(activity.imageFlip);
                        break;
                    default:
                        break;
                }
            }
            super.handleMessage(msg);
        }
    }

    private Handler handler = new MyHandler(this);
    String type = "";
    Boolean needCallback = true;
    Bundle bundle;

    public int R(String name, String type) {
        return getResources().getIdentifier(name, type, getPackageName());
    }

    boolean isSetBackSide = false;
    String isCustomMediaURL = null;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        bundle = getIntent().getExtras();
        if (bundle.getString("app_orientation", "portrait").contains("portrait")) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        }
        super.onCreate(savedInstanceState);
        res = getResources();
        if (bundle.containsKey("type")) {
            type = bundle.getString("type");
        }
        KycPlModule.ocrCLProcess = true;
        setTheme(R("AppThemeNoActionBar", "style"));
        requestWindowFeature(Window.FEATURE_NO_TITLE); // Hide the window title.
        setContentView(R("ocr_activity", "layout"));
        LinearLayout viewImageLayer= (LinearLayout) findViewById(R.id.viewImageLayer);// change id here
        if (bundle.containsKey("IS_SHOW_LOGO")) {
          Boolean isShow = bundle.getBoolean("IS_SHOW_LOGO");
          Log.i(TAG, "isSHow:- " + isShow);
          viewImageLayer.setVisibility( isShow ? View.VISIBLE : View.GONE);
        }
      AccuraLog.loge(TAG, "Start Camera Activity");
        init();
        try {
            RecogEngine recogEngine = new RecogEngine();
            boolean isLogEnable = bundle.getBoolean("enableLogs", false);
            AccuraLog.enableLogs(isLogEnable); // make sure to disable logs in release mode
            if (isLogEnable) {
                AccuraLog.refreshLogfile(getApplicationContext());
            }
            recogEngine.setDialog(false); // setDialog(false) To set your custom dialog for license validation
            RecogEngine.SDKModel sdkModel = recogEngine.initEngine(this);
            if (sdkModel.i >= 0) {
                // if OCR enable then get card list
                Resources res = getResources();
                recogEngine.setBlurPercentage(this, bundle.getInt("rg_setBlurPercentage", res.getInteger(R("rg_setBlurPercentage", "integer"))));
                recogEngine.setFaceBlurPercentage(this, bundle.getInt("rg_setFaceBlurPercentage", res.getInteger(R("rg_setFaceBlurPercentage", "integer"))));
                recogEngine.setGlarePercentage(this, bundle.getInt("rg_setGlarePercentage_0", res.getInteger(R("rg_setGlarePercentage_0", "integer"))), bundle.getInt("rg_setGlarePercentage_1", res.getInteger(R("rg_setGlarePercentage_1", "integer"))));
                recogEngine.isCheckPhotoCopy(this, bundle.getBoolean("rg_isCheckPhotoCopy", res.getBoolean(R("rg_isCheckPhotoCopy", "bool"))));
                recogEngine.SetHologramDetection(this, bundle.getBoolean("rg_SetHologramDetection", res.getBoolean(R("rg_SetHologramDetection", "bool"))));
                recogEngine.setLowLightTolerance(this, bundle.getInt("rg_setLowLightTolerance", res.getInteger(R("rg_setLowLightTolerance", "integer"))));
                recogEngine.setMotionThreshold(this, bundle.getInt("rg_setMotionThreshold", res.getInteger(R("rg_setMotionThreshold", "integer"))));
                if (bundle.getString("type").equalsIgnoreCase("ocr")) {
                    int cardType = bundle.getInt("card_type", 0);
                    if (cardType == 1) {
                        recogType = RecogType.PDF417;
                    } else if (cardType == 2) {
                        recogType = RecogType.DL_PLATE;
                    } else {
                        recogType = RecogType.OCR;
                    }
                } else if (bundle.getString("type").equalsIgnoreCase("mrz")) {
                    String mrz = bundle.getString("sub-type");
                    mrzCountryList = bundle.getString("country-list");
                    switch (mrz) {
                        case "passport_mrz":
                            recogType = RecogType.MRZ;
                            mrzType = MRZDocumentType.PASSPORT_MRZ;
                            cardName = getResources().getString(R("passport_mrz", "string"));
                            break;
                        case "id_mrz":
                            recogType = RecogType.MRZ;
                            mrzType = MRZDocumentType.ID_CARD_MRZ;
                            cardName = getResources().getString(R("id_mrz", "string"));
                            break;
                        case "visa_mrz":
                            recogType = RecogType.MRZ;
                            mrzType = MRZDocumentType.VISA_MRZ;
                            cardName = getResources().getString(R("visa_mrz", "string"));
                            break;
                        default:
                            recogType = RecogType.MRZ;
                            mrzType = MRZDocumentType.NONE;
                            cardName = getResources().getString(R("other_mrz", "string"));
                    }
                } else if (bundle.getString("type").equalsIgnoreCase("bankcard")) {
                    recogType = RecogType.BANKCARD;
                    cardName = getResources().getString(R("bank_card", "string"));
                } else if (bundle.getString("type").equalsIgnoreCase("barcode")) {
                    recogType = RecogType.BARCODE;
                    cardName = "Barcode";
                }
            } else {
                KycPlModule.ocrCL.invoke("No Licence Found", null);
                this.finish();
              KycPlModule.ocrCLProcess = false;
            }

        } catch (Exception e) {
          KycPlModule.ocrCL.invoke("No Action Found", null);
            this.finish();
          KycPlModule.ocrCLProcess = false;
        }
        if (mrzType == null) {
            mrzType = MRZDocumentType.NONE;
        }
        cardId = bundle.getInt("card_id", 0);
        countryId = bundle.getInt("country_id", 0);
        if (cardName == null) {
            cardName = bundle.getString("card_name", "");
        }

        AccuraLog.loge(TAG, "RecogType " + recogType);
        AccuraLog.loge(TAG, "Card Id " + cardId);
        AccuraLog.loge(TAG, "Country Id " + countryId);

      Log.i(TAG, "RecogType " + recogType);
      Log.i(TAG, "Card Id " + cardId);
      Log.i(TAG, "Country Id " + countryId);

        initCamera();
    }

//     private void initCamera() {
//         AccuraLog.loge(TAG, "Initialized camera");

//         RelativeLayout linearLayout = findViewById(R("ocr_root", "id")); // layout width and height is match_parent
//         cameraView = new CameraView(this);
//         if (recogType == RecogType.OCR || recogType == RecogType.DL_PLATE) {
//             // must have to set data for RecogType.OCR and RecogType.DL_PLATE
//             cameraView.setCountryId(12).setCardId(49)
//                     .setMinFrameForValidate(3); // to set min frame for qatar Id card
//         } else if (recogType == RecogType.PDF417) {
//             // must have to set data RecogType.PDF417
//             cameraView.setCountryId(countryId);
//         } else if (recogType == RecogType.MRZ) {
//             cameraView.setMRZDocumentType(mrzType);
//             cameraView.setMRZCountryCodeList(mrzCountryList);
//         }
//         cameraView.setRecogType(RecogType.OCR)
//                 .setView(linearLayout) // To add camera view
//                 .setCameraFacing(0) // To set front or back camera.
//                 .setOcrCallback(this)  // To get Update and Success Call back

// //                optional field
//                 .setEnableMediaPlayer(true);// false to disable default sound and default it is true

//         // initialized camera
//         isSetBackSide = bundle.getBoolean("rg_setBackSide", false);
//         isCustomMediaURL = bundle.getString("rg_customMediaURL", null);
//         if (isSetBackSide) {
// //            isBack = true;
//             cameraView.setBackSide();
//         } else {
// //            if (isSetBackSide) {
// //                Toast.makeText(getApplicationContext(), "")
// //            }
//             cameraView.setFrontSide();
//         }
//         recycleOldData();
//         if (recogType == RecogType.BARCODE) {
//             if (bundle.containsKey("sub-type")) {
//                 int barcodeType = bundle.getInt("sub-type");
//                 cameraView.setBarcodeFormat(barcodeType);
//             }
//         }
//         if (isCustomMediaURL != null) {
//           KycPlModule.ocrCLProcess = true;
//             mediaTask = new getMediaByURL().execute(isCustomMediaURL);
//         } else {
//             cameraView.init();
//         }
//     }

    private void initCamera() {
        AccuraLog.loge(TAG, "Initialized camera");

        RelativeLayout linearLayout = findViewById(R("ocr_root", "id")); // layout width and height is match_parent
        cameraView = new CameraView(this);
        if (recogType == RecogType.OCR || recogType == RecogType.DL_PLATE) {
            // must have to set data for RecogType.OCR and RecogType.DL_PLATE
            cameraView.setCountryId(countryId).setCardId(cardId)
                    .setMinFrameForValidate(bundle.getInt("rg_setMinFrameForValidate", res.getInteger(R("rg_setMinFrameForValidate", "integer")))); // to set min frame for qatar Id card
        } else if (recogType == RecogType.PDF417) {
            // must have to set data RecogType.PDF417
            cameraView.setCountryId(countryId);
        } else if (recogType == RecogType.MRZ) {
            cameraView.setMRZDocumentType(mrzType);
//            cameraView.setMRZCountryCodeList(mrzCountryList);
        }
        cameraView.setRecogType(recogType)
                .setView(linearLayout) // To add camera view
                .setCameraFacing(bundle.getInt("rg_setCameraFacing", res.getInteger(R("rg_setCameraFacing", "integer")))) // To set front or back camera.
                .setOcrCallback(this)  // To get Update and Success Call back

//                optional field
                .setEnableMediaPlayer(bundle.getBoolean("rg_setEnableMediaPlayer", res.getBoolean(R("rg_setEnableMediaPlayer", "bool"))));// false to disable default sound and default it is true

        // initialized camera
        isSetBackSide = bundle.getBoolean("rg_setBackSide", false);
        isCustomMediaURL = bundle.getString("rg_customMediaURL", null);
        if (isSetBackSide) {
//            isBack = true;
            cameraView.setBackSide();
        } else {
//            if (isSetBackSide) {
//                Toast.makeText(getApplicationContext(), "")
//            }
            cameraView.setFrontSide();
        }
        recycleOldData();
        if (recogType == RecogType.BARCODE) {
            if (bundle.containsKey("sub-type")) {
                int barcodeType = bundle.getInt("sub-type");
                cameraView.setBarcodeFormat(barcodeType);
            }
        }
        if (isCustomMediaURL != null) {
          KycPlModule.ocrCLProcess = true;
            mediaTask = new getMediaByURL().execute(isCustomMediaURL);
        } else {
            cameraView.init();
        }
    }

    public void recycleOldData() {
        if (OcrData.getOcrResult() != null) {
            try {
                OcrData.getOcrResult().getFrontimage().recycle();
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                OcrData.getOcrResult().getBackimage().recycle();
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                OcrData.getOcrResult().getFaceImage().recycle();
            } catch (Exception ignored) {
            }
        }


        try {
            if (RecogResult.getRecogResult() != null) {
                RecogResult.getRecogResult().docFrontBitmap.recycle();
                RecogResult.getRecogResult().faceBitmap.recycle();
                RecogResult.getRecogResult().docBackBitmap.recycle();
            }

        } catch (Exception ignored) {
        }
        try {
            if (PDF417Data.getPDF417Result() != null) {
                PDF417Data.getPDF417Result().docFrontBitmap.recycle();
                PDF417Data.getPDF417Result().faceBitmap.recycle();
                PDF417Data.getPDF417Result().docBackBitmap.recycle();
            }
        } catch (Exception ignored) {
        }
        OcrData.setOcrResult(null);
        RecogResult.setRecogResult(null);
        CardDetails.setCardDetails(null);
        PDF417Data.setPDF417Result(null);
    }

    AsyncTask<String, Integer, String> mediaTask = null;
    ProgressDialog progressDialog = null;

    public class getMediaByURL extends AsyncTask<String, Integer, String> {

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            progressDialog = new ProgressDialog(OcrActivity.this);
            progressDialog.setCancelable(false);
            progressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, "Cancel", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                    if (mediaTask != null) {
                        mediaTask.cancel(true);
                    }
                }
            });
            progressDialog.setTitle("Downloading Media File");
            progressDialog.show();
        }

        @Override
        protected void onCancelled() {
            super.onCancelled();
          KycPlModule.ocrCL.invoke("Media downloading cancelled", null);
            finish();
          KycPlModule.ocrCLProcess = false;
        }

        @Override
        protected String doInBackground(String... aurl) {
            int count;
            try {
                URL url = new URL(aurl[0]);
                URLConnection conexion = url.openConnection();
                conexion.connect();
                int lenghtOfFile = conexion.getContentLength();
                InputStream input = new BufferedInputStream(url.openStream());
                String path = getFilesDir().getAbsolutePath() + File.separator + "media_sound.mp3";
                File soundFile = new File(path);
                if (soundFile.exists()) {
                    if (!soundFile.delete()) {
                        return null;
                    }
                }
                OutputStream output = new FileOutputStream(soundFile.getAbsolutePath());
                byte data[] = new byte[1024];
                long total = 0;
                while ((count = input.read(data)) != -1) {
                    total += count;
                    publishProgress((int) ((total * 100) / lenghtOfFile));
                    output.write(data, 0, count);
                }

                output.flush();
                output.close();
                input.close();
                return soundFile.getAbsolutePath();
            } catch (Exception e) {
                return null;
            }
        }

        @Override
        protected void onPostExecute(String sound) {
            super.onPostExecute(sound);
            progressDialog.hide();
            if (sound != null) {
                File file = new File(sound);
                try {
                    cameraView.setCustomMediaPlayer(MediaPlayer.create(getApplicationContext(), Uri.fromFile(file)));
                    cameraView.init();
                } catch (Exception e) {
                  KycPlModule.ocrCL.invoke("Failed to open custom media", null);
                    finish();
                  KycPlModule.ocrCLProcess = false;
                }
            } else {
              KycPlModule.ocrCL.invoke("Failed to fetch custom media", null);
                finish();
              KycPlModule.ocrCLProcess = false;
            }
        }
    }

    private void init() {
        viewLeft = findViewById(R("view_left_frame", "id"));
        viewRight = findViewById(R("view_right_frame", "id"));
        borderFrame = findViewById(R("border_frame", "id"));
        tvTitle = findViewById(R("tv_title", "id"));
        tvScanMessage = findViewById(R("tv_scan_msg", "id"));
        imageFlip = findViewById(R("im_flip_image", "id"));
        View btn_flip = findViewById(R("btn_flip", "id"));
        btn_flip.setOnClickListener(v -> {
            if (cameraView != null) {
                cameraView.flipCamera();
            }
        });
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        if (cameraView != null) cameraView.onWindowFocusUpdate(hasFocus);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (cameraView != null) cameraView.onResume();
    }

    @Override
    protected void onPause() {
        if (cameraView != null) cameraView.onPause();
        super.onPause();
    }

    @Override
    public void onDestroy() {
        AccuraLog.loge(TAG, "onDestroy");
        Log.e("onDestroy", "onDestroy");
        if (cameraView != null) cameraView.stopCamera();
        if (cameraView != null) cameraView.onDestroy();
        if (progressDialog != null) {
            progressDialog.dismiss();
        }
        super.onDestroy();
        Runtime.getRuntime().gc(); // to clear garbage
    }

    /**
     * Override method call after camera initialized successfully
     * <p>
     * And update your border frame according to width and height
     * it's different for different card
     * <p>
     * Call {@link CameraView#startOcrScan(boolean isReset)} To start Camera Preview
     *
     * @param width  border layout width
     * @param height border layout height
     */
    @Override
    public void onUpdateLayout(int width, int height) {
        AccuraLog.loge(TAG, "Frame Size (wxh) : " + width + "x" + height);
        if (cameraView != null) cameraView.startOcrScan(false);

        //<editor-fold desc="To set camera overlay Frame">
        ViewGroup.LayoutParams layoutParams = borderFrame.getLayoutParams();
        layoutParams.width = width;
        layoutParams.height = height;
        borderFrame.setLayoutParams(layoutParams);
        ViewGroup.LayoutParams lpRight = viewRight.getLayoutParams();
        lpRight.height = height;
        viewRight.setLayoutParams(lpRight);
        ViewGroup.LayoutParams lpLeft = viewLeft.getLayoutParams();
        lpLeft.height = height;
        viewLeft.setLayoutParams(lpLeft);

        findViewById(R("ocr_frame", "id")).setVisibility(View.VISIBLE);

    }

    /**
     * Override this method after scan complete to get data from document
     *
     * @param result is scanned card data
     *               result instance of {@link OcrData} if recog type is {@link com.docrecog.scan.RecogType#OCR}
     *               or {@link com.docrecog.scan.RecogType#DL_PLATE} or {@link com.docrecog.scan.RecogType#BARCODE}
     *               result instance of {@link RecogResult} if recog type is {@link com.docrecog.scan.RecogType#MRZ}
     *               result instance of {@link PDF417Data} if recog type is {@link com.docrecog.scan.RecogType#PDF417}
     */
    @Override
    public void onScannedComplete(Object result) {
        Runtime.getRuntime().gc(); // To clear garbage
        AccuraLog.loge(TAG, "onScannedComplete: ");
        if (result != null) {
            if (result instanceof OcrData) {
                if (recogType == RecogType.OCR) {
                    if (isSetBackSide) {
                        if (!isBack && !cameraView.isBackSideAvailable()) {
                            cameraView.setFrontSide();
                            cameraView.flipImage(imageFlip);
                            isBack = true;
                        } else {
                            if (isBack) {
                                OcrData.setOcrResult((OcrData) result);
                                /**@recogType is {@link RecogType#OCR}*/
                                sendDataToResultActivity(RecogType.OCR);
                            } else {
                                cameraView.setFrontSide();
                                cameraView.flipImage(imageFlip);
                                isBack = true;
                            }
                        }
                    } else {
                        if (isBack || !cameraView.isBackSideAvailable()) {
                            OcrData.setOcrResult((OcrData) result);
                            /**@recogType is {@link RecogType#OCR}*/
                            sendDataToResultActivity(RecogType.OCR);
                        } else {
                            cameraView.setBackSide();
                            cameraView.flipImage(imageFlip);
                            isBack = true;
                        }
                    }

                } else if (recogType == RecogType.DL_PLATE || recogType == RecogType.BARCODE) {
                    /**
                     * @recogType is {@link RecogType#DL_PLATE} or recogType == {@link RecogType#BARCODE}*/
                    OcrData.setOcrResult((OcrData) result);
                    sendDataToResultActivity(recogType);
                }
            } else if (result instanceof RecogResult) {
                /**
                 *  @recogType is {@link RecogType#MRZ}*/
                RecogResult.setRecogResult((RecogResult) result);
                sendDataToResultActivity(RecogType.MRZ);
            } else if (result instanceof CardDetails) {
                /**
                 *  @recogType is {@link RecogType#BANKCARD}*/
                CardDetails.setCardDetails((CardDetails) result);
                sendDataToResultActivity(RecogType.BANKCARD);
            } else if (result instanceof PDF417Data) {
                /**
                 *  @recogType is {@link RecogType#PDF417}*/
                if (isBack || !cameraView.isBackSideAvailable()) {
                    PDF417Data.setPDF417Result((PDF417Data) result);
                    sendDataToResultActivity(recogType);
                } else {
                    isBack = true;
                    if (isSetBackSide) {
                        cameraView.setFrontSide();
                    } else {
                        cameraView.setBackSide();
                    }
                    cameraView.flipImage(imageFlip);
                }
            }
        } else Toast.makeText(this, "Failed", Toast.LENGTH_SHORT).show();
    }

    private void sendDataToResultActivity(RecogType recogType) {
        if (cameraView != null) cameraView.release(true);
        if (needCallback) {
//            if (type.contains("ocr")) {
            RecogResult recogResult = null;
            CardDetails cardDetails = null;
            PDF417Data barcodeData = PDF417Data.getPDF417Result();
            Boolean isBarCodePdf417 = recogType == RecogType.BARCODE && barcodeData != null;
            RecogType ocrTypes[] = {RecogType.BARCODE, RecogType.DL_PLATE, RecogType.OCR};
            String frontUri = null, backUri = null, faceUri = null;
            JSONObject results = new JSONObject();
            JSONObject frontResult = new JSONObject();
            JSONObject mrzResult = new JSONObject();
            JSONObject backResult = new JSONObject();
            OcrData data = null;
            type = recogType.toString();
            String fileDir = getFilesDir().getAbsolutePath();
            if (Arrays.asList(ocrTypes).contains(recogType)) {
                data = OcrData.getOcrResult();
                if (data != null) {
                    if (data.getFaceImage() != null) {
                        faceUri = getImageUri(data.getFaceImage(), "face", fileDir);
                    }
                    if (data.getFrontimage() != null) {
                        frontUri = getImageUri(data.getFrontimage(), "front", fileDir);
                    }
                    if (data.getBackimage() != null) {
                        backUri = getImageUri(data.getBackimage(), "back", fileDir);
                    }
                }
            }
            if (recogType == RecogType.MRZ) {
                recogResult = RecogResult.getRecogResult();
                if (recogResult != null) {
                    frontResult = setMRZData(recogResult);
                    if (recogResult.faceBitmap != null) {
                        faceUri = getImageUri(recogResult.faceBitmap, "face", fileDir);
                    }
                    if (recogResult.docFrontBitmap != null) {
                        frontUri = getImageUri(recogResult.docFrontBitmap, "front", fileDir);
                    }
                    if (recogResult.docBackBitmap != null) {
                        backUri = getImageUri(recogResult.docBackBitmap, "back", fileDir);
                    }
                }

            } else if (recogType == RecogType.BANKCARD) {
                cardDetails = CardDetails.getCardDetails();
                if (cardDetails.bitmap != null) {
                    frontUri = getImageUri(cardDetails.bitmap, "front", fileDir);
                    try {
                        frontResult.put("front_img", frontUri);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
                try {
                    frontResult.put("Expiry Date", cardDetails.expirationDate);
                    frontResult.put("Expiry Month", cardDetails.expirationMonth);
                    frontResult.put("Expiry Year", cardDetails.expirationYear);
                    frontResult.put("Card Type", cardDetails.cardType);
                    frontResult.put("Card Number", cardDetails.number);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            } else if (recogType == RecogType.PDF417 || isBarCodePdf417) {
                type += "PDF417";
                if (barcodeData.faceBitmap != null) {
                    faceUri = getImageUri(barcodeData.faceBitmap, "face", fileDir);
                }
                if (barcodeData.docFrontBitmap != null) {
                    frontUri = getImageUri(barcodeData.docFrontBitmap, "front", fileDir);
                }
                if (barcodeData.docBackBitmap != null) {
                    backUri = getImageUri(barcodeData.docBackBitmap, "back", fileDir);
                }
                try {
                    frontResult.put(getString(R("firstName", "string")), barcodeData.fname);
                    frontResult.put(getString(R("firstName", "string")), barcodeData.firstName);
                    frontResult.put(getString(R("firstName", "string")), barcodeData.firstName1);
                    frontResult.put(getString(R("lastName", "string")), barcodeData.lname);
                    frontResult.put(getString(R("lastName", "string")), barcodeData.lastName);
                    frontResult.put(getString(R("lastName", "string")), barcodeData.lastName1);
                    frontResult.put(getString(R("middle_name", "string")), barcodeData.mname);
                    frontResult.put(getString(R("middle_name", "string")), barcodeData.middleName);
                    frontResult.put(getString(R("addressLine1", "string")), barcodeData.address1);
                    frontResult.put(getString(R("addressLine2", "string")), barcodeData.address2);
                    frontResult.put(getString(R("ResidenceStreetAddress1", "string")), barcodeData.ResidenceAddress1);
                    frontResult.put(getString(R("ResidenceStreetAddress2", "string")), barcodeData.ResidenceAddress2);
                    frontResult.put(getString(R("city", "string")), barcodeData.city);
                    frontResult.put(getString(R("zipcode", "string")), barcodeData.zipcode);
                    frontResult.put(getString(R("birth_date", "string")), barcodeData.birthday);
                    frontResult.put(getString(R("birth_date", "string")), barcodeData.birthday1);
                    frontResult.put(getString(R("license_number", "string")), barcodeData.licence_number);
                    frontResult.put(getString(R("license_expiry_date", "string")), barcodeData.licence_expire_date);
                    frontResult.put(getString(R("sex", "string")), barcodeData.sex);
                    frontResult.put(getString(R("jurisdiction_code", "string")), barcodeData.jurisdiction);
                    frontResult.put(getString(R("license_classification", "string")), barcodeData.licenseClassification);
                    frontResult.put(getString(R("license_restriction", "string")), barcodeData.licenseRestriction);
                    frontResult.put(getString(R("license_endorsement", "string")), barcodeData.licenseEndorsement);
                    frontResult.put(getString(R("issue_date", "string")), barcodeData.issueDate);
                    frontResult.put(getString(R("organ_donor", "string")), barcodeData.organDonor);
                    frontResult.put(getString(R("height_in_ft", "string")), barcodeData.heightinFT);
                    frontResult.put(getString(R("height_in_cm", "string")), barcodeData.heightCM);
                    frontResult.put(getString(R("full_name", "string")), barcodeData.fullName);
                    frontResult.put(getString(R("full_name", "string")), barcodeData.fullName1);
                    frontResult.put(getString(R("weight_in_lbs", "string")), barcodeData.weightLBS);
                    frontResult.put(getString(R("weight_in_kg", "string")), barcodeData.weightKG);
                    frontResult.put(getString(R("name_prefix", "string")), barcodeData.namePrefix);
                    frontResult.put(getString(R("name_suffix", "string")), barcodeData.nameSuffix);
                    frontResult.put(getString(R("prefix", "string")), barcodeData.Prefix);
                    frontResult.put(getString(R("suffix", "string")), barcodeData.Suffix);
                    frontResult.put(getString(R("suffix", "string")), barcodeData.Suffix1);
                    frontResult.put(getString(R("eye_color", "string")), barcodeData.eyeColor);
                    frontResult.put(getString(R("hair_color", "string")), barcodeData.hairColor);
                    frontResult.put(getString(R("issue_time", "string")), barcodeData.issueTime);
                    frontResult.put(getString(R("number_of_duplicate", "string")), barcodeData.numberDuplicate);
                    frontResult.put(getString(R("unique_customer_id", "string")), barcodeData.uniqueCustomerId);
                    frontResult.put(getString(R("social_security_number", "string")), barcodeData.socialSecurityNo);
                    frontResult.put(getString(R("social_security_number", "string")), barcodeData.socialSecurityNo1);
                    frontResult.put(getString(R("under_18", "string")), barcodeData.under18);
                    frontResult.put(getString(R("under_19", "string")), barcodeData.under19);
                    frontResult.put(getString(R("under_21", "string")), barcodeData.under21);
                    frontResult.put(getString(R("permit_classification_code", "string")), barcodeData.permitClassification);
                    frontResult.put(getString(R("veteran_indicator", "string")), barcodeData.veteranIndicator);
                    frontResult.put(getString(R("permit_issue", "string")), barcodeData.permitIssue);
                    frontResult.put(getString(R("permit_expire", "string")), barcodeData.permitExpire);
                    frontResult.put(getString(R("permit_restriction", "string")), barcodeData.permitRestriction);
                    frontResult.put(getString(R("permit_endorsement", "string")), barcodeData.permitEndorsement);
                    frontResult.put(getString(R("court_restriction", "string")), barcodeData.courtRestriction);
                    frontResult.put(getString(R("inventory_control_no", "string")), barcodeData.inventoryNo);
                    frontResult.put(getString(R("race_ethnicity", "string")), barcodeData.raceEthnicity);
                    frontResult.put(getString(R("standard_vehicle_class", "string")), barcodeData.standardVehicleClass);
                    frontResult.put(getString(R("document_discriminator", "string")), barcodeData.documentDiscriminator);
                    frontResult.put(getString(R("ResidenceCity", "string")), barcodeData.ResidenceCity);
                    frontResult.put(getString(R("ResidenceJurisdictionCode", "string")), barcodeData.ResidenceJurisdictionCode);
                    frontResult.put(getString(R("ResidencePostalCode", "string")), barcodeData.ResidencePostalCode);
                    frontResult.put(getString(R("MedicalIndicatorCodes", "string")), barcodeData.MedicalIndicatorCodes);
                    frontResult.put(getString(R("NonResidentIndicator", "string")), barcodeData.NonResidentIndicator);
                    frontResult.put(getString(R("VirginiaSpecificClass", "string")), barcodeData.VirginiaSpecificClass);
                    frontResult.put(getString(R("VirginiaSpecificRestrictions", "string")), barcodeData.VirginiaSpecificRestrictions);
                    frontResult.put(getString(R("VirginiaSpecificEndorsements", "string")), barcodeData.VirginiaSpecificEndorsements);
                    frontResult.put(getString(R("PhysicalDescriptionWeight", "string")), barcodeData.PhysicalDescriptionWeight);
                    frontResult.put(getString(R("CountryTerritoryOfIssuance", "string")), barcodeData.CountryTerritoryOfIssuance);
                    frontResult.put(getString(R("FederalCommercialVehicleCodes", "string")), barcodeData.FederalCommercialVehicleCodes);
                    frontResult.put(getString(R("PlaceOfBirth", "string")), barcodeData.PlaceOfBirth);
                    frontResult.put(getString(R("StandardEndorsementCode", "string")), barcodeData.StandardEndorsementCode);
                    frontResult.put(getString(R("StandardRestrictionCode", "string")), barcodeData.StandardRestrictionCode);
                    frontResult.put(getString(R("JuriSpeciVehiClassiDescri", "string")), barcodeData.JuriSpeciVehiClassiDescri);
                    frontResult.put(getString(R("JuriSpeciRestriCodeDescri", "string")), barcodeData.JuriSpeciRestriCodeDescri);
                    frontResult.put(getString(R("ComplianceType", "string")), barcodeData.ComplianceType);
                    frontResult.put(getString(R("CardRevisionDate", "string")), barcodeData.CardRevisionDate);
                    frontResult.put(getString(R("HazMatEndorsementExpiryDate", "string")), barcodeData.HazMatEndorsementExpiryDate);
                    frontResult.put(getString(R("LimitedDurationDocumentIndicator", "string")), barcodeData.LimitedDurationDocumentIndicator);
                    frontResult.put(getString(R("FamilyNameTruncation", "string")), barcodeData.FamilyNameTruncation);
                    frontResult.put(getString(R("FirstNamesTruncation", "string")), barcodeData.FirstNamesTruncation);
                    frontResult.put(getString(R("MiddleNamesTruncation", "string")), barcodeData.MiddleNamesTruncation);
                    frontResult.put(getString(R("organ_donor_indicator", "string")), barcodeData.OrganDonorIndicator);
                    frontResult.put(getString(R("PermitIdentifier", "string")), barcodeData.PermitIdentifier);
                    frontResult.put(getString(R("AuditInformation", "string")), barcodeData.AuditInformation);
                    frontResult.put(getString(R("JurisdictionSpecific", "string")), barcodeData.JurisdictionSpecific);
                    if (!TextUtils.isEmpty(barcodeData.wholeDataString)) {
                        frontResult.put("PDF417", barcodeData.wholeDataString);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            if (data != null) {
                OcrData.MapData frontData = data.getFrontData();
                OcrData.MapData backData = data.getBackData();
                if (frontData != null) {
                    List<OcrData.MapData.ScannedData> frontScanData = frontData.getOcr_data();
                    for (int i = 0; i < frontScanData.size(); i++) {
                        if (frontScanData.get(i).getKey() != null) {
                            try {
                                if (frontScanData.get(i).getKey().equalsIgnoreCase("signature")) {
                                    String base64Uri = getBase64Uri(frontScanData.get(i).getKey_data());
                                    if (base64Uri != null) {
                                        frontResult.put("signature", base64Uri);
                                    }
                                } else if (frontScanData.get(i).getKey().equalsIgnoreCase("mrz")) {
                                    RecogResult mrzData = data.getMrzData();
                                    if (mrzData != null) {
                                        mrzResult = setMRZData(mrzData);
                                    }
                                } else {
                                    frontResult.put(frontScanData.get(i).getKey(), frontScanData.get(i).getKey_data());
                                }
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }
                    }
                }
                if (backData != null) {
                    List<OcrData.MapData.ScannedData> backScanData = backData.getOcr_data();
                    for (int i = 0; i < backScanData.size(); i++) {
                        if (backScanData.get(i).getKey() != null) {
                            try {
                                if (backScanData.get(i).getKey().equalsIgnoreCase("signature")) {
                                    String base64Uri = getBase64Uri(backScanData.get(i).getKey_data());
                                    if (base64Uri != null) {
                                        backResult.put("signature", base64Uri);
                                    }
                                } else if (backScanData.get(i).getKey().equalsIgnoreCase("mrz")) {
                                    RecogResult mrzData = data.getMrzData();
                                    if (mrzData != null) {
                                        mrzResult = setMRZData(mrzData);
                                    }
                                }  else {
                                    backResult.put(backScanData.get(i).getKey(), backScanData.get(i).getKey_data());
                                }

                            } catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }

                    }
                }
            }
            try {
                if (faceUri != null) {
                    results.put("face", faceUri);
                }
                if (frontUri != null) {
                    results.put("front_img", frontUri);
                }
                if (backUri != null) {
                    results.put("back_img", backUri);
                }
                results.put("type", type);
                results.put("back_data", backResult);
                results.put("front_data", frontResult);
                results.put("mrz_data", mrzResult);
            } catch (JSONException e) {
                e.printStackTrace();
            }
          KycPlModule.ocrCL.invoke(null, results.toString());
//                cameraView.onDestroy();
            finish();
          KycPlModule.ocrCLProcess = false;
//            }
            return;
        }
    }

    public JSONObject setMRZData(RecogResult recogResult) {
        JSONObject frontResult = new JSONObject();
        try {
            String newMRZText = recogResult.lines.replace("\n", "").replace("\r", "");
            frontResult.put("mrz", recogResult.lines);
            frontResult.put("passportType", recogResult.docType);
            frontResult.put("givenNames", recogResult.givenname);
            frontResult.put("surName", recogResult.surname);
            frontResult.put("passportNumber", recogResult.docnumber);
            frontResult.put("passportNumberChecksum", recogResult.docchecksum);
            frontResult.put("correctPersonalChecksum", recogResult.correctdocchecksum);
            frontResult.put("country", recogResult.country);
            frontResult.put("nationality", recogResult.nationality);
            String s = (recogResult.sex.equals("M")) ? "Male" : ((recogResult.sex.equals("F")) ? "Female" : recogResult.sex);
            frontResult.put("sex", s);
            frontResult.put("birth", recogResult.birth);
            frontResult.put("birthChecksum", recogResult.birthchecksum);
            frontResult.put("correctBirthChecksum", recogResult.correctbirthchecksum);
            frontResult.put("expirationDate", recogResult.expirationdate);
            frontResult.put("expirationDateChecksum", recogResult.expirationchecksum);
            frontResult.put("correctExpirationChecksum", recogResult.correctexpirationchecksum);
            frontResult.put("issueDate", recogResult.issuedate);
            frontResult.put("departmentNumber", recogResult.departmentnumber);
            frontResult.put("personalNumber", recogResult.otherid);
            frontResult.put("personalNumber2", recogResult.otherid2);
            frontResult.put("personalNumberChecksum", recogResult.otheridchecksum);
            frontResult.put("secondRowChecksum", recogResult.secondrowchecksum);
            frontResult.put("correctSecondrowChecksum", recogResult.correctsecondrowchecksum);
            frontResult.put("retval", recogResult.ret);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return frontResult;
    }

    public String getBase64Uri(String base64Str) {
        byte[] decodedString = Base64.decode(base64Str, android.util.Base64.DEFAULT);
        String path = getFilesDir().getAbsolutePath();
        OutputStream fOut = null;
        File file = new File(path, getSaltString() + "_signature.jpg");
        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);

        try {
            fOut = new FileOutputStream(file);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        decodedByte.compress(Bitmap.CompressFormat.JPEG, 100, fOut);
        try {
            fOut.flush(); // Not really required
            fOut.close();
            return "file://" + file.getAbsolutePath();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * @param titleCode    to display scan card message on top of border Frame
     * @param errorMessage To display process message.
     *                     null if message is not available
     * @param isFlip       To set your customize animation after complete front scan
     */
    @Override
    public void onProcessUpdate(int titleCode, String errorMessage, boolean isFlip) {
        AccuraLog.loge(TAG, "onProcessUpdate :-> " + titleCode + "," + errorMessage + "," + isFlip);
        Message message;
        if (getTitleMessage(titleCode) != null) {
            /**
             *
             * 1. Scan Frontside of Card Name // for front side ocr
             * 2. Scan Backside of Card Name // for back side ocr
             * 3. Scan Card Name // only for single side ocr
             * 4. Scan Front Side of Document // for MRZ and PDF417
             * 5. Now Scan Back Side of Document // for MRZ and PDF417
             * 6. Scan Number Plate // for DL plate
             */

            message = new Message();
            message.what = 0;
            message.obj = getTitleMessage(titleCode);
            handler.sendMessage(message);
//            tvTitle.setText(title);
        }
        if (errorMessage != null) {
            message = new Message();
            message.what = 1;
            message.obj = getErrorMessage(errorMessage);
            handler.sendMessage(message);
//            tvScanMessage.setText(message);
        }
        if (isFlip) {
            message = new Message();
            message.what = 2;
            handler.sendMessage(message);//  to set default animation or remove this line to set your customize animation
        }

    }

//    private String getTitleMessage(int titleCode) {
//        Bundle bundle = getIntent().getExtras();
//        if (titleCode < 0) return null;
//        switch (titleCode) {
//            case RecogEngine.SCAN_TITLE_OCR_FRONT:// for front side ocr;
//                return String.format(bundle.getString("SCAN_TITLE_OCR_FRONT", res.getString(R("SCAN_TITLE_OCR_FRONT", "string"))), cardName);
//            case RecogEngine.SCAN_TITLE_OCR_BACK: // for back side ocr
//                return String.format(bundle.getString("SCAN_TITLE_OCR_BACK", res.getString(R("SCAN_TITLE_OCR_BACK", "string"))), cardName);
//            case RecogEngine.SCAN_TITLE_OCR: // only for single side ocr
//                return String.format(bundle.getString("SCAN_TITLE_OCR", res.getString(R("SCAN_TITLE_OCR", "string"))), cardName);
//            case RecogEngine.SCAN_TITLE_MRZ_PDF417_FRONT:// for front side MRZ and PDF417
//                if (recogType == RecogType.BANKCARD) {
//                    return bundle.getString("SCAN_TITLE_BANKCARD", res.getString(R("SCAN_TITLE_BANKCARD", "string")));
//                } else if (recogType == RecogType.BARCODE) {
//                    return bundle.getString("SCAN_TITLE_BARCODE", res.getString(R("SCAN_TITLE_BARCODE", "string")));
//                } else
//                    return bundle.getString("SCAN_TITLE_MRZ_PDF417_FRONT", res.getString(R("SCAN_TITLE_MRZ_PDF417_FRONT", "string")));
//            case RecogEngine.SCAN_TITLE_MRZ_PDF417_BACK: // for back side MRZ and PDF417
//                return bundle.getString("SCAN_TITLE_MRZ_PDF417_BACK", res.getString(R("SCAN_TITLE_MRZ_PDF417_BACK", "string")));
//            case RecogEngine.SCAN_TITLE_DLPLATE: // for DL plate
//                return bundle.getString("SCAN_TITLE_DLPLATE", res.getString(R("SCAN_TITLE_DLPLATE", "string")));
//            default:
//                return "";
//        }
//    }

    private String getTitleMessage(int titleCode) {
      Bundle bundle = getIntent().getExtras();
      String strMessage = "";
      if (titleCode < 0) return null;
      switch (titleCode) {
        case RecogEngine.SCAN_TITLE_OCR_FRONT:// for front side ocr;

          strMessage = String.format(bundle.getString("SCAN_TITLE_OCR_FRONT", res.getString(R("SCAN_TITLE_OCR_FRONT", "string"))), cardName);
          if (bundle.containsKey("SCAN_TITLE_OCR_FRONT")) {
            strMessage = String.format(bundle.getString("SCAN_TITLE_OCR_FRONT") + " ", cardName);
          }
          return strMessage;
        case RecogEngine.SCAN_TITLE_OCR_BACK: // for back side ocr

          strMessage = String.format(bundle.getString("SCAN_TITLE_OCR_BACK", res.getString(R("SCAN_TITLE_OCR_BACK", "string"))), cardName);
          if (bundle.containsKey("SCAN_TITLE_OCR_BACK")) {
            strMessage = String.format(bundle.getString("SCAN_TITLE_OCR_BACK") + " ", cardName);
          }
          return strMessage;
        case RecogEngine.SCAN_TITLE_OCR: // only for single side ocr

          strMessage = String.format(bundle.getString("SCAN_TITLE_OCR", res.getString(R("SCAN_TITLE_OCR", "string"))), cardName);
          if (bundle.containsKey("SCAN_TITLE_OCR")) {
            strMessage = String.format(bundle.getString("SCAN_TITLE_OCR") + " ", cardName);
          }
          return strMessage;
        case RecogEngine.SCAN_TITLE_MRZ_PDF417_FRONT:// for front side MRZ and PDF417

          if (recogType == RecogType.BANKCARD) {

            strMessage = bundle.getString("SCAN_TITLE_BANKCARD", res.getString(R("SCAN_TITLE_BANKCARD", "string")));
            if (bundle.containsKey("SCAN_TITLE_BANKCARD")) {
              strMessage = String.format(bundle.getString("SCAN_TITLE_BANKCARD"));
            }
          } else if (recogType == RecogType.BARCODE) {

            strMessage = bundle.getString("SCAN_TITLE_BARCODE", res.getString(R("SCAN_TITLE_BARCODE", "string")));
            if (bundle.containsKey("SCAN_TITLE_BARCODE")) {
              strMessage = String.format(bundle.getString("SCAN_TITLE_BARCODE"));
            }
          } else {

            strMessage = bundle.getString("SCAN_TITLE_MRZ_PDF417_FRONT", res.getString(R("SCAN_TITLE_MRZ_PDF417_FRONT", "string")));
            if (bundle.containsKey("SCAN_TITLE_MRZ_PDF417_FRONT")) {
              strMessage = String.format(bundle.getString("SCAN_TITLE_MRZ_PDF417_FRONT"));
            }
          }
          return strMessage;
        case RecogEngine.SCAN_TITLE_MRZ_PDF417_BACK: // for back side MRZ and PDF417

          strMessage = bundle.getString("SCAN_TITLE_MRZ_PDF417_BACK", res.getString(R("SCAN_TITLE_MRZ_PDF417_BACK", "string")));
          if (bundle.containsKey("SCAN_TITLE_MRZ_PDF417_BACK")) {
            strMessage = String.format(bundle.getString("SCAN_TITLE_MRZ_PDF417_BACK"));
          }
          return strMessage;
        case RecogEngine.SCAN_TITLE_DLPLATE: // for DL plate

          strMessage = bundle.getString("SCAN_TITLE_DLPLATE", res.getString(R("SCAN_TITLE_DLPLATE", "string")));
          if (bundle.containsKey("SCAN_TITLE_DLPLATE")) {
            strMessage = String.format(bundle.getString("SCAN_TITLE_DLPLATE"));
          }
          return strMessage;
        default:
          return "";
      }
    }


//    private String getErrorMessage(String s) {
//        Bundle bundle = getIntent().getExtras();
//        switch (s) {
//            case RecogEngine.ACCURA_ERROR_CODE_MOTION:
//                return bundle.getString("ACCURA_ERROR_CODE_MOTION", res.getString(R("ACCURA_ERROR_CODE_MOTION", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME:
//                return bundle.getString("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME", res.getString(R("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME:
//                return bundle.getString("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME", res.getString(R("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_PROCESSING:
//                return bundle.getString("ACCURA_ERROR_CODE_PROCESSING", res.getString(R("ACCURA_ERROR_CODE_PROCESSING", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_BLUR_DOCUMENT:
//                return bundle.getString("ACCURA_ERROR_CODE_BLUR_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_BLUR_DOCUMENT", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_FACE_BLUR:
//                return bundle.getString("ACCURA_ERROR_CODE_FACE_BLUR", res.getString(R("ACCURA_ERROR_CODE_FACE_BLUR", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_GLARE_DOCUMENT:
//                return bundle.getString("ACCURA_ERROR_CODE_GLARE_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_GLARE_DOCUMENT", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_HOLOGRAM:
//                return bundle.getString("ACCURA_ERROR_CODE_HOLOGRAM", res.getString(R("ACCURA_ERROR_CODE_HOLOGRAM", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_DARK_DOCUMENT:
//                return bundle.getString("ACCURA_ERROR_CODE_DARK_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_DARK_DOCUMENT", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT:
//                return bundle.getString("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_FACE:
//                return bundle.getString("ACCURA_ERROR_CODE_FACE", res.getString(R("ACCURA_ERROR_CODE_FACE", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_MRZ:
//                return bundle.getString("ACCURA_ERROR_CODE_MRZ", res.getString(R("ACCURA_ERROR_CODE_MRZ", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_PASSPORT_MRZ:
//                return bundle.getString("ACCURA_ERROR_CODE_PASSPORT_MRZ", res.getString(R("ACCURA_ERROR_CODE_PASSPORT_MRZ", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_ID_MRZ:
//                return bundle.getString("ACCURA_ERROR_CODE_ID_MRZ", res.getString(R("ACCURA_ERROR_CODE_ID_MRZ", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_VISA_MRZ:
//                return bundle.getString("ACCURA_ERROR_CODE_VISA_MRZ", res.getString(R("ACCURA_ERROR_CODE_VISA_MRZ", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_WRONG_SIDE:
//                return bundle.getString("ACCURA_ERROR_CODE_WRONG_SIDE", res.getString(R("ACCURA_ERROR_CODE_WRONG_SIDE", "string")));
//            case RecogEngine.ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE:
//                return bundle.getString("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE", res.getString(R("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE", "string")));
//            default:
//                return s;
//        }
//    }

    private String getErrorMessage(String s) {

      Bundle bundle = getIntent().getExtras();
      String strMessage = "";
      switch (s) {
        case RecogEngine.ACCURA_ERROR_CODE_MOTION:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_MOTION", res.getString(R("ACCURA_ERROR_CODE_MOTION", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_MOTION")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_MOTION");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME", res.getString(R("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME", res.getString(R("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_PROCESSING:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_PROCESSING", res.getString(R("ACCURA_ERROR_CODE_PROCESSING", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_PROCESSING")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_PROCESSING");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_BLUR_DOCUMENT:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_BLUR_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_BLUR_DOCUMENT", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_BLUR_DOCUMENT")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_BLUR_DOCUMENT");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_FACE_BLUR:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_FACE_BLUR", res.getString(R("ACCURA_ERROR_CODE_FACE_BLUR", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_FACE_BLUR")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_FACE_BLUR");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_GLARE_DOCUMENT:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_GLARE_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_GLARE_DOCUMENT", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_GLARE_DOCUMENT")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_GLARE_DOCUMENT");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_HOLOGRAM:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_HOLOGRAM", res.getString(R("ACCURA_ERROR_CODE_HOLOGRAM", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_HOLOGRAM")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_HOLOGRAM");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_DARK_DOCUMENT:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_DARK_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_DARK_DOCUMENT", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_DARK_DOCUMENT")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_DARK_DOCUMENT");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT", res.getString(R("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_PHOTO_COPY_DOCUMENT");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_FACE:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_FACE", res.getString(R("ACCURA_ERROR_CODE_FACE", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_FACE")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_FACE");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_MRZ:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_MRZ", res.getString(R("ACCURA_ERROR_CODE_MRZ", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_MRZ")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_MRZ");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_PASSPORT_MRZ:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_PASSPORT_MRZ", res.getString(R("ACCURA_ERROR_CODE_PASSPORT_MRZ", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_PASSPORT_MRZ")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_PASSPORT_MRZ");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_ID_MRZ:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_ID_MRZ", res.getString(R("ACCURA_ERROR_CODE_ID_MRZ", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_ID_MRZ")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_ID_MRZ");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_VISA_MRZ:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_VISA_MRZ", res.getString(R("ACCURA_ERROR_CODE_VISA_MRZ", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_VISA_MRZ")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_VISA_MRZ");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_WRONG_SIDE:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_WRONG_SIDE", res.getString(R("ACCURA_ERROR_CODE_WRONG_SIDE", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_WRONG_SIDE")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_WRONG_SIDE");
          }
          return strMessage;
        case RecogEngine.ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE:

          strMessage = bundle.getString("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE", res.getString(R("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE", "string")));
          if (bundle.containsKey("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE")) {
            strMessage = bundle.getString("ACCURA_ERROR_CODE_UPSIDE_DOWN_SIDE");
          }
          return strMessage;
        default:
          return s;
      }
    }

    @Override
    public void onError(final String errorMessage) {
        // stop ocr if failed
        if (errorMessage.equalsIgnoreCase("Back Side not available") && isSetBackSide) {
          KycPlModule.ocrCL.invoke(errorMessage, null);
            finish();
          KycPlModule.ocrCLProcess = false;
        }
        tvScanMessage.setText(errorMessage);
    }

}
