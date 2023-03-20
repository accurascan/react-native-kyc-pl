package com.reactnativekycpl;

import android.util.Log;
import android.net.Uri;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.os.Bundle;

import com.accurascan.facedetection.LivenessCustomization;
import com.accurascan.facedetection.SelfieCameraActivity;
import com.accurascan.facedetection.model.AccuraVerificationResult;
import com.accurascan.facematch.util.BitmapHelper;
import com.facedetection.FMCameraScreenCustomization;
import com.facedetection.SelfieFMCameraActivity;
import com.facedetection.model.AccuraFMCameraModel;
import com.inet.facelock.callback.FaceCallback;
import com.inet.facelock.callback.FaceDetectionResult;
import com.inet.facelock.callback.FaceHelper;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import android.widget.Toast;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;

//Activity for check face match & liveness.
public class FaceMatchActivity extends AppCompatActivity implements FaceHelper.FaceMatchCallBack, FaceCallback {
    FaceHelper faceHelper;
    Bitmap face1, detectFace1, detectFace2, face2;
    Bundle bundle;
    boolean witFace = false;
    JSONObject livenessResult;
    Boolean isLiveness = false;
    private static final String TAG = OcrActivity.class.getSimpleName();

    public int R(String name, String type) {
        return getResources().getIdentifier(name, type, getPackageName());
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        bundle = getIntent().getExtras();
        if (bundle.getString("app_orientation", "portrait").contains("portrait")) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        }
        super.onCreate(savedInstanceState);
        setContentView(R("activity_face_match", "layout"));
        faceHelper = new FaceHelper(this);
        isLiveness = !bundle.getString("type").equalsIgnoreCase("fm");
        if (bundle.containsKey("with_face")) {
            witFace = bundle.getBoolean("with_face", false);
            if (witFace) {
                String uri = bundle.getString("face_uri", "");
                if (uri.length() > 0) {
                    Bitmap face = BitmapFactory.decodeFile(uri.replace("file://", ""));
                    face1 = face;
                    faceHelper.setInputImage(face);
                }

                String base64Data = bundle.getString("face_base64", "");
                if (base64Data.length() > 0) {
                    Bitmap face = KycPlModule.getBase64ToBitmap(base64Data);
                    face1 = face;
                    faceHelper.setInputImage(face);
                }

            } else if (isLiveness) {
                //Change it with v2.3.1
                //Default liveness has face match success.
                witFace = true;
                String uri = bundle.getString("face_uri", "");
                if (uri.length() > 0) {
                    Bitmap face = BitmapFactory.decodeFile(uri.replace("file://", ""));
                    face1 = face;
                    faceHelper.setInputImage(face);
                }

                String base64Data = bundle.getString("face_base64", "");
                if (base64Data.length() > 0) {
                    Bitmap face = KycPlModule.getBase64ToBitmap(base64Data);
                    face1 = face;
                    faceHelper.setInputImage(face);
                }
            } else {
                if (!isLiveness) {
                    if (!bundle.containsKey("face1")) {
                        KycPlModule.faceCL.invoke("Missing face1 configuration", null);
                        this.finish();
                        return;
                    }
                    if (bundle.containsKey("face2")) {
                        boolean isFace2 = bundle.getBoolean("face2", false);
                        if (isFace2) {
                            if (KycPlModule.face1 == null) {
                              KycPlModule.faceCL.invoke("Please first take Face1 photo", null);
                                this.finish();
                                return;
                            } else {
                                face1 = KycPlModule.face1;
                                faceHelper.setInputImage(face1);
                            }
                        }
                    } else {
                      KycPlModule.faceCL.invoke("Missing face2 configuration", null);
                        this.finish();
                        return;
                    }
                }
            }
        } else {
          KycPlModule.faceCL.invoke("Missing with_face configuration", null);
            this.finish();
            return;
        }
        try {
            if (!isLiveness) {
                openFaceMatch();
            } else if (bundle.getString("type").equalsIgnoreCase("lv")) {
                openLiveness();
            } else {
                this.finish();
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void openLiveness() throws JSONException {
        Resources res = getResources();

        LivenessCustomization livenessCustomization = new LivenessCustomization();
        livenessCustomization.backGroundColor = res.getColor(R("livenessBackground", "color"));
        if (bundle.containsKey("livenessBackground")) {
        livenessCustomization.backGroundColor = Color.parseColor(bundle.getString("livenessBackground"));
        }
        livenessCustomization.closeIconColor = res.getColor(R("livenessCloseIcon", "color"));
        if (bundle.containsKey("livenessCloseIcon")) {
        livenessCustomization.closeIconColor = Color.parseColor(bundle.getString("livenessCloseIcon"));
        }
        livenessCustomization.feedbackBackGroundColor = res.getColor(R("livenessfeedbackBg", "color"));
        if (bundle.containsKey("livenessfeedbackBg")) {
        livenessCustomization.feedbackBackGroundColor = Color.parseColor(bundle.getString("livenessfeedbackBg"));
        }
        livenessCustomization.feedbackTextColor = res.getColor(R("livenessfeedbackText", "color"));
        if (bundle.containsKey("livenessfeedbackText")) {
        livenessCustomization.feedbackTextColor = Color.parseColor(bundle.getString("livenessfeedbackText"));
        }
        livenessCustomization.feedbackTextSize = res.getInteger(R("feedbackTextSize", "integer"));
        if (bundle.containsKey("livenessfeedbackText")) {
        livenessCustomization.feedbackTextSize = bundle.getInt("feedbackTextSize");
        }
        livenessCustomization.feedBackframeMessage = res.getString(R("feedBackframeMessage", "string"));
        if (bundle.containsKey("feedBackframeMessage")) {
        livenessCustomization.feedBackframeMessage = bundle.getString("feedBackframeMessage");
        }
        livenessCustomization.feedBackAwayMessage = res.getString(R("feedBackAwayMessage", "string"));
        if (bundle.containsKey("feedBackAwayMessage")) {
        livenessCustomization.feedBackAwayMessage = bundle.getString("feedBackAwayMessage");
        }
        livenessCustomization.feedBackOpenEyesMessage = res.getString(R("feedBackOpenEyesMessage", "string"));
        if (bundle.containsKey("feedBackOpenEyesMessage")) {
        livenessCustomization.feedBackOpenEyesMessage = bundle.getString("feedBackOpenEyesMessage");
        }
        livenessCustomization.feedBackCloserMessage = res.getString(R("feedBackCloserMessage", "string"));
        if (bundle.containsKey("feedBackCloserMessage")) {
        livenessCustomization.feedBackCloserMessage = bundle.getString("feedBackCloserMessage");
        }
        livenessCustomization.feedBackCenterMessage = res.getString(R("feedBackCenterMessage", "string"));
        if (bundle.containsKey("feedBackCenterMessage")) {
        livenessCustomization.feedBackCenterMessage = bundle.getString("feedBackCenterMessage");
        }
        livenessCustomization.feedBackMultipleFaceMessage = res.getString(R("feedBackMultipleFaceMessage", "string"));
        if (bundle.containsKey("feedBackMultipleFaceMessage")) {
        livenessCustomization.feedBackMultipleFaceMessage = bundle.getString("feedBackMultipleFaceMessage");
        }
        livenessCustomization.feedBackHeadStraightMessage = res.getString(R("feedBackHeadStraightMessage", "string"));
        if (bundle.containsKey("feedBackHeadStraightMessage")) {
        livenessCustomization.feedBackHeadStraightMessage = bundle.getString("feedBackHeadStraightMessage");
        }
        livenessCustomization.feedBackBlurFaceMessage = res.getString(R("feedBackBlurFaceMessage", "string"));
        if (bundle.containsKey("feedBackBlurFaceMessage")) {
        livenessCustomization.feedBackBlurFaceMessage = bundle.getString("feedBackBlurFaceMessage");
        }
        livenessCustomization.feedBackGlareFaceMessage = res.getString(R("feedBackGlareFaceMessage", "string"));
        if (bundle.containsKey("feedBackGlareFaceMessage")) {
        livenessCustomization.feedBackGlareFaceMessage = bundle.getString("feedBackGlareFaceMessage");
        }

        livenessCustomization.setBlurPercentage(res.getInteger(R("setBlurPercentage", "integer")));
        if (bundle.containsKey("setBlurPercentage")) {
        livenessCustomization.setBlurPercentage(bundle.getInt("setBlurPercentage"));
        }
        int minGlare = res.getInteger(R("setGlarePercentage_0", "integer"));
        int maxGlare = res.getInteger(R("setGlarePercentage_1", "integer"));
        if (bundle.containsKey("setGlarePercentage_0")) {
        minGlare = bundle.getInt("setGlarePercentage_0");
        }
        if (bundle.containsKey("setGlarePercentage_1")) {
        minGlare = bundle.getInt("setGlarePercentage_1");
        }
        livenessCustomization.setGlarePercentage(minGlare, maxGlare);

        //End New SDK changes By ANIL
        String liveUrl = res.getString(R("liveness_url", "string"));
        if (bundle.containsKey("liveness_url")) {
        liveUrl = bundle.getString("liveness_url");
        }
        Intent intent = SelfieCameraActivity.getCustomIntent(this, livenessCustomization, liveUrl);
        startActivityForResult(intent, 201);
    }


    public void openFaceMatch() throws JSONException {

        Resources res = getResources();
        FMCameraScreenCustomization cameraScreenCustomization = new FMCameraScreenCustomization();
        cameraScreenCustomization.backGroundColor = getResources().getColor(R("faceMatchBackground", "color"));
        if (bundle.containsKey("backGroundColor")) {
        cameraScreenCustomization.backGroundColor = Color.parseColor(bundle.getString("backGroundColor"));
        }
        cameraScreenCustomization.closeIconColor = getResources().getColor(R("faceMatchCloseIcon", "color"));
        if (bundle.containsKey("closeIconColor")) {
        cameraScreenCustomization.closeIconColor = Color.parseColor(bundle.getString("closeIconColor"));
        }
        cameraScreenCustomization.feedbackBackGroundColor = getResources().getColor(R("faceMatchfeedbackBg", "color"));
        if (bundle.containsKey("feedbackBackGroundColor")) {
        cameraScreenCustomization.feedbackBackGroundColor = Color.parseColor(bundle.getString("feedbackBackGroundColor"));
        }
        cameraScreenCustomization.feedbackTextColor = getResources().getColor(R("faceMatchfeedbackText", "color"));
        if (bundle.containsKey("feedbackTextColor")) {
        cameraScreenCustomization.feedbackTextColor = Color.parseColor(bundle.getString("feedbackTextColor"));
        }

        cameraScreenCustomization.feedbackTextSize = res.getInteger(R("feedbackTextSize", "integer"));
        if (bundle.containsKey("feedbackTextSize")) {
        cameraScreenCustomization.feedbackTextSize = bundle.getInt("feedbackTextSize");
        }

        cameraScreenCustomization.feedBackframeMessage = res.getString(R("feedBackframeMessage", "string"));
        if (bundle.containsKey("feedBackframeMessage")) {
        cameraScreenCustomization.feedBackframeMessage = bundle.getString("feedBackframeMessage");
        }

        cameraScreenCustomization.feedBackAwayMessage = res.getString(R("feedBackAwayMessage", "string"));
        if (bundle.containsKey("feedBackAwayMessage")) {
        cameraScreenCustomization.feedBackAwayMessage = bundle.getString("feedBackAwayMessage");
        }

        cameraScreenCustomization.feedBackOpenEyesMessage = res.getString(R("feedBackOpenEyesMessage", "string"));
        if (bundle.containsKey("feedBackOpenEyesMessage")) {
        cameraScreenCustomization.feedBackOpenEyesMessage = bundle.getString("feedBackOpenEyesMessage");
        }

        cameraScreenCustomization.feedBackCloserMessage = res.getString(R("feedBackCloserMessage", "string"));
        if (bundle.containsKey("feedBackCloserMessage")) {
        cameraScreenCustomization.feedBackCloserMessage = bundle.getString("feedBackCloserMessage");
        }

        cameraScreenCustomization.feedBackCenterMessage = res.getString(R("feedBackCenterMessage", "string"));
        if (bundle.containsKey("feedBackCenterMessage")) {
        cameraScreenCustomization.feedBackCenterMessage = bundle.getString("feedBackCenterMessage");
        }

        cameraScreenCustomization.feedBackMultipleFaceMessage = res.getString(R("feedBackMultipleFaceMessage", "string"));
        if (bundle.containsKey("feedBackMultipleFaceMessage")) {
        cameraScreenCustomization.feedBackMultipleFaceMessage = bundle.getString("feedBackMultipleFaceMessage");
        }

        cameraScreenCustomization.feedBackHeadStraightMessage = res.getString(R("feedBackHeadStraightMessage", "string"));
        if (bundle.containsKey("feedBackHeadStraightMessage")) {
        cameraScreenCustomization.feedBackHeadStraightMessage = bundle.getString("feedBackHeadStraightMessage");
        }

        cameraScreenCustomization.feedBackBlurFaceMessage = res.getString(R("feedBackBlurFaceMessage", "string"));
        if (bundle.containsKey("feedBackBlurFaceMessage")) {
        cameraScreenCustomization.feedBackBlurFaceMessage = bundle.getString("feedBackBlurFaceMessage");
        }

        cameraScreenCustomization.feedBackGlareFaceMessage = res.getString(R("feedBackGlareFaceMessage", "string"));
        if (bundle.containsKey("feedBackGlareFaceMessage")) {
        cameraScreenCustomization.feedBackGlareFaceMessage = bundle.getString("feedBackGlareFaceMessage");
        }

        cameraScreenCustomization.setBlurPercentage(res.getInteger(R("setBlurPercentage", "integer")));
        if (bundle.containsKey("setBlurPercentage")) {
        cameraScreenCustomization.setBlurPercentage(bundle.getInt("setBlurPercentage"));
        }

        int minGlare = res.getInteger(R("setGlarePercentage_0", "integer"));
        int maxGlare = res.getInteger(R("setGlarePercentage_1", "integer"));
        if (bundle.containsKey("setGlarePercentage_0")) {
        minGlare = bundle.getInt("setGlarePercentage_0");
        }
        if (bundle.containsKey("setGlarePercentage_1")) {
        minGlare = bundle.getInt("setGlarePercentage_1");
        }
        cameraScreenCustomization.setGlarePercentage(minGlare, maxGlare);
        Intent intent = SelfieFMCameraActivity.getCustomIntent(this, cameraScreenCustomization);
        startActivityForResult(intent, 202);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 202) {
            if (data == null) {
              KycPlModule.faceCL.invoke("No data", null);
                this.finish();
                return;
            }
            AccuraVerificationResult result = data.getParcelableExtra("Accura.fm");
            if (result == null) {
                return;
            }
            if (result.getStatus().equals("1")) {
                handleVerificationSuccessResultFM(result);
            } else {
                Toast.makeText(getApplicationContext(), "Retry...", Toast.LENGTH_SHORT).show();
            }
        } else if (requestCode == 201) {
            if (data == null) {
              KycPlModule.faceCL.invoke("No Data", null);
                this.finish();
                return;
            }
            JSONObject results = new JSONObject();
            try {
                results.put("status", false);
                results.put("type", "liveness");
            } catch (JSONException e) {
                e.printStackTrace();
            }
            AccuraVerificationResult result = data.getParcelableExtra("Accura.liveness");
            if (result != null) {
                if (result.getStatus().equals("1")) {
                    livenessResult = handleVerificationSuccessResult(result, results);
                     if (witFace) {
                        if (result.getFaceBiometrics() != null) {
                            Bitmap nBmp = result.getFaceBiometrics();
                            face2 = nBmp;
                            faceHelper.setMatchImage(nBmp);
                        }
                     } else {
                         Log.i(TAG, "handleVerificationSuccessResult :- " + livenessResult);
                       KycPlModule.faceCL.invoke(null, livenessResult.toString());
                         this.finish();
                     }

                } else {
                  KycPlModule.faceCL.invoke(result.getErrorMessage(), null);
//                    if (result.getVideoPath() != null) {
//                      KycPlModule.isLivenessGetVideo = true;
//                      KycPlModule.livenessVideo = result.getVideoPath().getPath();
//                        Toast.makeText(getApplicationContext(), "Video Path : " + result.getVideoPath() + "\n" + result.getErrorMessage(), Toast.LENGTH_LONG).show();
//                    } else {
//                        Toast.makeText(getApplicationContext(), result.getErrorMessage(), Toast.LENGTH_SHORT).show();
//                    }
                    this.finish();
                }
            }
        }
    }

    public JSONObject handleVerificationSuccessResult(final AccuraVerificationResult result, JSONObject caResults) {
        if (result != null) {
            if (result.getLivenessResult() != null) {
                if (result.getLivenessResult().getLivenessStatus()) {
                    try {
                        caResults.put("status", true);
                        caResults.put("with_face", witFace);
                        caResults.put("score", result.getLivenessResult().getLivenessScore() * 100);
                        if (result.getFaceBiometrics() != null) {
                            caResults.put("detect", KycPlModule.getImageUri(result.getFaceBiometrics(), "live_detect", getFilesDir().getAbsolutePath()));
                        }
//                        if (result.getImagePath() != null) {
//                            caResults.put("image_uri", result.getImagePath());
//                        }
//                        if (result.getVideoPath() != null) {
//                            caResults.put("video_uri", result.getVideoPath());
//                        }
                    } catch (JSONException ignored) {
                    }
                }
            }
        }

        return caResults;

    }

    public void handleVerificationSuccessResultFM(final AccuraVerificationResult result) {
        if (result != null) {
            if (face1 == null) {
                if (result.getFaceBiometrics() != null) {
                    KycPlModule.face1 = face1 = result.getFaceBiometrics();
                    JSONObject results = new JSONObject();
                    try {
                        results.put("status", false);
                        results.put("with_face", witFace);
                        String fileDir = getFilesDir().getAbsolutePath();
                        if (detectFace1 == null) {
                            results.put("img_1", KycPlModule.getImageUri(KycPlModule.face1, "img_1", fileDir));
                        } else {
                            results.put("img_1", KycPlModule.getImageUri(detectFace1, "img_1", fileDir));
                        }

                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                    Log.i(TAG, "handleVerificationSuccessResultFM :- " + results);
                  KycPlModule.faceCL.invoke(null, results.toString());
                    this.finish();
                    return;
                }
                return;
            }
            if (result.getFaceBiometrics() != null) {
                Bitmap nBmp = result.getFaceBiometrics();
                face2 = nBmp;
                faceHelper.setMatchImage(nBmp);
            }
        }
    }

    @Override
    public void onInitEngine(int i) {
    }

    @Override
    public void onLeftDetect(FaceDetectionResult faceDetectionResult) {
        Bitmap det = BitmapHelper.createFromARGB(faceDetectionResult.getNewImg(), faceDetectionResult.getNewWidth(), faceDetectionResult.getNewHeight());
        detectFace1 = faceDetectionResult.getFaceImage(det);
    }

    @Override
    public void onRightDetect(FaceDetectionResult faceDetectionResult) {
        Bitmap det = BitmapHelper.createFromARGB(faceDetectionResult.getNewImg(), faceDetectionResult.getNewWidth(), faceDetectionResult.getNewHeight());
        detectFace2 = faceDetectionResult.getFaceImage(det);
    }

    @Override
    public void onExtractInit(int i) {

    }

    @Override
    public void onFaceMatch(float v) {

        if (face2 != null) {
            JSONObject results = new JSONObject();
            String fileDir = getFilesDir().getAbsolutePath();
            try {
                if (!isLiveness) {

                    results.put("status", true);
                    results.put("score", v);
                    results.put("with_face", witFace);
                    if (!witFace) {
                        results.put("img_1", KycPlModule.getImageUri(detectFace1, "img_1", fileDir));
                        results.put("img_2", KycPlModule.getImageUri(detectFace2, "img_2", fileDir));
                    } else {
                        results.put("detect", KycPlModule.getImageUri(detectFace2, "img_1", fileDir));
                    }
                    Log.i(TAG, "onFaceMatch !isLiveness :- " + results);
                  KycPlModule.faceCL.invoke(null ,results.toString());
                } else {
                    livenessResult.put("fm_score", v);
                    Log.i(TAG, "onFaceMatch isLiveness :- " + livenessResult);
                  KycPlModule.faceCL.invoke(null ,livenessResult.toString());
                }
              KycPlModule.face1 = null;
              KycPlModule.face2 = null;
            } catch (JSONException e) {
              KycPlModule.faceCL.invoke("Error found in data. Please try again", null);
                e.printStackTrace();
                this.finish();
            }
            this.finish();
        }
    }

    @Override
    public void onSetInputImage(Bitmap bitmap) {

    }

    @Override
    public void onSetMatchImage(Bitmap bitmap) {

    }
}
