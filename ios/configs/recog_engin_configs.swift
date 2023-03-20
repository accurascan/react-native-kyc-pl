struct EnginConfigs {
    static var rg_setBlurPercentage: Int32 = 62

    /* // 0 for clean face and 100 for Blurry face */
    static var rg_setFaceBlurPercentage: Int32 = 70

    /* // Set min percentage for glare */
    static var rg_setGlarePercentage_0: Int32 = 6

    /* // Set max percentage for glare */
    static var rg_setGlarePercentage_1: Int32 = 98

    /* Set Photo Copy to allow photocopy document or not */
    static var rg_isCheckPhotoCopy = false

    /* Set Hologram detection to verify the hologram on the face
    // true to check hologram on face */
    static var rg_SetHologramDetection = true

    /* Set light tolerance to detect light on document
    // 0 for full dark document and 100 for full bright document */
    static var rg_setLowLightTolerance: Int32 = 39

    /* Set motion threshold to detect motion on camera document
    // 1 - allows 1% motion on document and
    // 100 - it can not detect motion and allow document to scan. */
    static var rg_setMotionThreshold: Int32 = 18

    /* // Set min frame for qatar ID card for Most validated data. minFrame supports only odd numbers like 3,5... */
    static var rg_setMinFrameForValidate: Int32 = 3

    /* // To set front or back camera. allows 0,1 */
    static var rg_setCameraFacing: Int32 = 0

    /* false to disable default sound and default it is true */
    static var rg_setEnableMediaPlayer = true
    
    static var with_face = false
    
    static var app_oriantation = "portrait"
    
    static var face_uri = "portrait"
}

