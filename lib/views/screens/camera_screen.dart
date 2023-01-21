// ignore_for_file: sort_child_properties_last

import 'package:aiapp/views/screens/history_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/container.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:aiapp/views/screens/prediction_screen.dart';
import 'package:tflite/tflite.dart';
import 'package:sizer/sizer.dart';
import 'package:aiapp/constants/preventions.dart';

// late List<CameraDescription> cameras;

// void main(List<String> args) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MaterialApp(
//     home: CameraScreen(cameras: cameras),
//   ));
// }

// The model should be very sure before outputing a prediction
const double CONFIDENCE_THRESHOLD = 0.9000000000000000;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  late File _imageGallery;
  late File _imageCamera;
  bool _isCameraInitialized = false;
  int _selectedModeIndex = 0;
  late List _recognitions;

  // varialbles for focus
  bool showFocusCircle = false;
  double x = 0;
  double y = 0;
  final ImagePicker _picker = ImagePicker();
  late Future<void> _initializeController;
  //LightMode lightMode = LightMode.auto;
  late FlashMode currentFlashMode;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    //SystemChrome.setEnabledSystemUIOverlays([]);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CameraController(widget.cameras[0], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
    loadModel().then((value) {
      print('Model loaded');
    });
    //onNewCameraSelected(cameras[0]);
    currentFlashMode = FlashMode.off;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    controller?.dispose();
  }

  takePicture() async {
    //final CameraController cameraController = controller;
    if (controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      await controller!.initialize();
      await controller!.setFlashMode(currentFlashMode);
      //await Future.delayed(Duration(milliseconds: 500));
      //await controller.stopImageStream();
      //await Future.delayed(Duration(milliseconds: 200));
      XFile file = await controller!.takePicture();
      //setState(() {});
      //return file.readAsBytes();
      return file;
    } catch (e) {
      print('AN ERROR OCCURRED WHILE TAKING THE PICTURE: $e');
      //return null;
    }
  }

  pickFromPhotos() async {
    try {
      var img = await _picker.pickImage(source: ImageSource.gallery);
      return img;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String? res;
      res = await Tflite.loadModel(
        model: "assets/plant_diseas_model.tflite",
        labels: "assets/labels.txt",
        // useGpuDelegate: true,
      );

      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future recognizeImage(XFile image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 38,
      threshold: 0.03,
      imageMean: 0,
      imageStd: 255.0,
    );
    setState(() {
      _recognitions = recognitions!;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      key: _scaffoldKey,
      body: Sizer(
        builder: (context, orientation, deviceType) {
          return Container(
            height: double.maxFinite,
            width: double.maxFinite,
            child: GestureDetector(
              child: Stack(
                children: [
                  Container(
                    // height: double.maxFinite,
                    //width: double.maxFinite,
                    child: _isCameraInitialized
                        ? Transform.scale(
                            scale: 1.0,
                            child: AspectRatio(
                              aspectRatio:
                                  MediaQuery.of(context).size.aspectRatio,
                              child: OverflowBox(
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.fitHeight,
                                  child: Container(
                                    width: width,
                                    height:
                                        width * controller!.value.aspectRatio,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        CameraPreview(controller!),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 10.h,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.black, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter)),
                      child: const Center(
                          child: Text(
                        'Capture Tomato Leave',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(left: 6.h, right: 6.h),
                      height: 15.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Container(
                              height: 6.h,
                              width: 6.h,
                              child: const Icon(Icons.image_outlined),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                            ),
                            onTap: (() async {
                              // tap this button to pick image from gallery
                              XFile imgFile = await pickFromPhotos();
                              if (imgFile != null) {
                                // run prediction on image
                                // read file bytes
                                var imgFileBytes = await imgFile.readAsBytes();
                                //showLoaderDialog(context);
                                await recognizeImage(imgFile);
                                //Navigator.pop(context);
                                var preventions = getPrevention(
                                    _recognitions[0]['label'],
                                    _recognitions[0]['confidence']);
                                //print(_recognitions[0]['label']);
                                print(
                                    'THIS IS THE PREDICTION ${_recognitions[0]['label']}');
                                print(
                                    'THIS IS THE CONFIDENCE ${_recognitions[0]['confidence']}');
                                double confidence;
                                String prediction;
                                if (preventions[0] == 'UNKNOWN') {
                                  confidence = 0.0;
                                  prediction = 'unknown image';
                                } else {
                                  confidence = _recognitions[0]['confidence'];
                                  prediction = _recognitions[0]['label'];
                                }

                                // ignore: use_build_context_synchronously
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return PredictionScreen(
                                      prediction: prediction,
                                      treatmentOne: preventions[0],
                                      treatmentTwo: preventions[1],
                                      treatmentThree: preventions[2],
                                      image: imgFileBytes,
                                      confidence: castDouble(confidence),
                                      isStored: false);
                                }));
                              } else {
                                showInSnackBar('Picture access error');
                              }
                            }),
                          ),
                          GestureDetector(
                            child: Container(
                              height: 10.h,
                              width: 10.h,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                            ),
                            onTap: (() async {
                              // tap this button to snap picture
                              XFile imgFile = await takePicture();
                              if (imgFile != null) {
                                // run prediction on image
                                var imgFileBytes = await imgFile.readAsBytes();
                                //showLoaderDialog(context);
                                await recognizeImage(imgFile);
                                //Navigator.pop(context);
                                var preventions = getPrevention(
                                    _recognitions[0]['label'],
                                    _recognitions[0]['confidence']);
                                print(
                                    'THIS IS THE PREDICTION ${_recognitions[0]['label']}');
                                print(
                                    'THIS IS THE CONFIDENCE ${_recognitions[0]['confidence']}');
                                double confidence;
                                String prediction;
                                if (preventions[0] == 'UNKNOWN') {
                                  confidence = 0.0;
                                  prediction = 'unknown image';
                                } else {
                                  confidence = _recognitions[0]['confidence'];
                                  prediction = _recognitions[0]['label'];
                                }
                                // ignore: use_build_context_synchronously
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return PredictionScreen(
                                      prediction: prediction,
                                      image: imgFileBytes,
                                      treatmentOne: preventions[0],
                                      treatmentTwo: preventions[1],
                                      treatmentThree: preventions[2],
                                      confidence: castDouble(confidence),
                                      isStored: false);
                                }));
                                // go to the PredictionScreen
                              } else {
                                showInSnackBar('Camera error');
                              }
                            }),
                          ),
                          GestureDetector(
                            child: Container(
                              height: 6.h,
                              width: 6.h,
                              child: Icon(Icons.history_outlined),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                            ),
                            onTap: () async {
                              //tap this button to go to the history page to see saved predictions
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          const HistoryScreen())));
                            },
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    ));
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircularProgressIndicator(),
          Container(
              margin: EdgeInsets.only(left: 7), child: Text("Loading...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  castDouble(double number) {
    double figure = number * 100;
    return figure.round();
  }

  getPrevention(String disease, double confidence) {
    print('DOES IT CONTAIN THE KEY ${DISEASE_PREVENTION.containsKey(disease)}');

    if ((DISEASE_PREVENTION.containsKey(disease)) &&
        (confidence > CONFIDENCE_THRESHOLD)) {
      print('TEST PASSED');
      return DISEASE_PREVENTION[disease];
    } else {
      return ['UNKNOWN', 'UNKNOWN', 'UNKNOWN'];
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      //showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
      //currentFlashMode = cameraController.value.flashMode;
      cameraController.setFlashMode(currentFlashMode);
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    //_scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = controller!;

    // App state changed before we got the chance to initialize.

    if (cameraController == null ||
        cameraController.value.isInitialized != null) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (controller!.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * controller!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);
      print("point : $point");

      // Manually focus
      await controller?.setFocusPoint(point);

      // Manually set light exposure
      //controller.setExposurePoint(point);

      setState(() {
        Future.delayed(const Duration(seconds: 2)).whenComplete(() {
          setState(() {
            showFocusCircle = false;
          });
        });
      });
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      print(e);
      rethrow;
    }
  }
}
