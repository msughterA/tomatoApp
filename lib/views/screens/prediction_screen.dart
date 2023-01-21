import 'package:aiapp/services/database.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

class PredictionScreen extends StatefulWidget {
  final String prediction;
  final String treatmentOne;
  final String treatmentTwo;
  final String treatmentThree;
  final int confidence;
  final bool isStored;
  final Uint8List image;
  const PredictionScreen(
      {super.key,
      required this.prediction,
      required this.confidence,
      required this.treatmentOne,
      required this.treatmentTwo,
      required this.image,
      required this.isStored,
      required this.treatmentThree});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  calculatePercentagePadding(double percent) {
    double padding = (percent / 100) * 40.h;
    padding = 40.h - padding;
    return padding;
  }

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
          onPressed: (() {
            // Go back to the previous page
            Navigator.pop(context);
          }),
        ),
        title: const Text(
          'Prediction',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save_outlined),
        onPressed: () {
          if (widget.isStored) {
            showInSnackBar('Prediction Already Saved');
          } else {
            // d
            DateTime today = DateTime.now();
            String dateSlug = "${today.day}/${today.month}/${today.year}";
            var encodedImage = json.encode({'image': widget.image});
            var predictionTabledata = PredictionTabledata(
                image: encodedImage,
                date: dateSlug,
                disease: widget.prediction,
                confidence: widget.confidence,
                treatmentOne: widget.treatmentOne,
                treatmentTwo: widget.treatmentTwo,
                treatmentThree: widget.treatmentThree);
            databaseHelper.instance
                .insertPrediction(predictionTabledata.toMap());
            showInSnackBar('Prediction Saved');
          }
        },
      ),
      body: Sizer(
        builder: (context, orientation, deviceType) {
          return Container(
            height: 100.h,
            width: 100.w,
            color: Colors.black,
            child: Stack(children: [
              Container(
                height: 100.h,
                width: 100.w,
                child: Column(children: [
                  Container(
                    height: 48.h,
                    width: 100.w,
                    padding: const EdgeInsets.all(32.0),
                    child: Image.memory(widget.image),
                  )
                ]),
              ),
              Positioned(
                bottom: 2.h,
                left: 2.h,
                right: 2.h,
                child: Container(
                  height: 50.h,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15)),
                  child: SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.treatmentOne == 'UNKNOWN'
                            ? 'UNKNOWN'
                            : widget.prediction,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40.h,
                            height: 2.h,
                            padding: EdgeInsets.only(
                                right: calculatePercentagePadding(
                                    widget.confidence.toDouble())),
                            decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10)),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                          Text(widget.treatmentOne == 'UNKNOWN'
                              ? '0%'
                              : '${widget.confidence}%')
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Recommendations',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Prevention 1',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text('${widget.treatmentOne}'),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Prevention 2',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text('${widget.treatmentTwo}'),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Prevention 3',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text('${widget.treatmentThree}')
                    ],
                  )),
                ),
              )
            ]),
          );
        },
      ),
    ));
  }

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    //_scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
