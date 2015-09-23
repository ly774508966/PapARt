import fr.inria.papart.depthcam.devices.*;

int frameWidth, frameHeight;
PMatrix3D kinectCameraExtrinsics;
// TODO: ?! pop-up a new window with Kinect AR view ?

ProjectiveDeviceP projectorDevice, kinectProjectiveP;

KinectDevice kinectDevice;
KinectProcessing kinectAnalysis;
PointCloudVisualization pcv;

boolean isKinectOneActivated = false;
PlaneAndProjectionCalibration planeProjCalib;
HomographyCalibration homographyCalibration;

void initKinectOne(){

    if(isKinectOneActivated)
        return;

    kinectDevice = new KinectOne(this, camera);
    kinectDevice.getCameraRGB().setThread();
    kinectDevice.getCameraDepth().setThread();

    kinectAnalysis = new KinectProcessing(this, kinectDevice);

    planeProjCalib =
        new PlaneAndProjectionCalibration();
    homographyCalibration = new HomographyCalibration();

    pcv = new PointCloudVisualization();
    // // TODO: variable precision.  ?



    // Kinect camera is the main tracking Camera
    kinectProjectiveP = camera.getProjectiveDevice();
    projectorDevice = projector.getProjectiveDeviceP();

    frameWidth = projectorDevice.getWidth();
    frameHeight = projectorDevice.getHeight();

    // identity - no external camera for ProCam calibration
    kinectCameraExtrinsics = new PMatrix3D();
    kinectCameraExtrinsics.reset();


    isKinectOneActivated = true;
}

void stopKinectOne(){

}

// To implement fully
void initKinect360(){

    // TODO: load the Kinect camera & stuff...
/*
    kinectProjectiveP = cameraKinectRGB.getProjectiveDevice();
    projectorDevice = projector.getProjectiveDeviceP();

    frameWidth = projectorDevice.getWidth();
    frameHeight = projectorDevice.getHeight();
*/

// TODO: find the  KinectPaperTransform (with the tracking).
    // compute Camera -> Kinect transformation
    // kinectCameraExtrinsics = cameraPaperTransform.get();
    // kinectCameraExtrinsics.invert();
    // kinectCameraExtrinsics.preApply(kinectPaperTransform);

}

boolean computeScreenPaperIntersection(){

    // generate coordinates...
    float step = 0.5f;
    int nbPoints = (int) ((1 + 1f / step) * (1 + 1f / step));
    HomographyCreator homographyCreator = new HomographyCreator(3, 2, nbPoints);

    // Creates 3D points on the corner of the screen
    int k = 0;
    for (float i = 0; i <= 1.0; i += step) {
        for (float j = 0; j <= 1.0; j += step, k++) {

            PVector screenPoint = new PVector(i, j);
            PVector kinectPoint = new PVector();

            // where the point is on the table.
            PVector inter = computeIntersection(i, j);
            if(inter == null)
                return false;

            kinectCameraExtrinsics.mult(inter, kinectPoint);
            homographyCreator.addPoint(kinectPoint, screenPoint);
        }
    }
    homographyCalibration = homographyCreator.getHomography();
    return true;
}



PVector computeIntersection(float px, float py){

    // Create ray from the projector (origin / viewed pixel)
    // Intersect this ray with the piece of paper.
    // Compute the Two points for the ray
    PVector originP = new PVector(0, 0, 0);
    PVector viewedPtP = projectorDevice.pixelToWorldNormP((int) (px * frameWidth), (int) (py * frameHeight));

    // Pass it to the camera point of view (origin)
    PMatrix3D extr = projector.getExtrinsicsInv();
    PVector originC = new PVector();
    PVector viewedPtC = new PVector();
    extr.mult(originP, originC);
    extr.mult(viewedPtP, viewedPtC);

    // Second argument is a direction
    viewedPtC.sub(originC);

    Ray3D ray
        = new Ray3D(new Vec3D(originC.x,
                              originC.y,
                              originC.z),
                    new Vec3D(viewedPtC.x,
                              viewedPtC.y,
                              viewedPtC.z));

    // Intersect ray with Plane
    ReadonlyVec3D inter = planeCalibCam.getPlane().getIntersectionWithRay(ray);

    if(inter == null){
        println("No intersection :( check stuff");
        return null;
    }

    return new PVector(inter.x(), inter.y(), inter.z());
}
