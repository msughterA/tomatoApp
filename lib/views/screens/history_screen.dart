import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:aiapp/services/database.dart';
import 'package:aiapp/views/screens/prediction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool hasData = false;
  List<Map<String, dynamic>> data = [];
  @override
  void initState() {
    // TODO: implement initState
    // load the data from the database
    getdata().then((value) {
      print('PREDICTIONS LIST QUERIED FROM THE DATABASE');
    });
  }

  Future getdata() async {
    var d = await databaseHelper.instance.queryAllPredictions();
    setState(() {
      data = d;
    });
  }

  castDouble(double number) {
    double figure = number * 100;
    return figure.round();
  }

  List<String> _options = ['delete'];
  String _selectedOption = '';
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('History'),
        centerTitle: false,
        backgroundColor: Colors.green,
      ),
      body: Sizer(builder: ((context, orientation, deviceType) {
        return Container(
          height: 100.h,
          width: 100.w,
          child: data == null
              ? const Text('No data stored')
              : data.isEmpty
                  ? const Center(child: Text('No data stored'))
                  : ListView.builder(
                      itemCount: data.length,
                      itemBuilder: ((context, index) {
                        var imageJson = json.decode(data[index]['image']);
                        List<int> imageList = List.from(imageJson['image']);
                        Uint8List imagebytes = Uint8List.fromList(imageList);
                        //print('THIS IS THE IMAGE BYTES $imagebytes');
                        return ListTile(
                          leading: const Icon(Icons.file_present_outlined),
                          title: Text('${data[index]['disease']}'),
                          subtitle: Text('${data[index]['date']}'),
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: ((context) {
                              return PredictionScreen(
                                  prediction: data[index]['disease'],
                                  treatmentOne: data[index]['treatmentOne'],
                                  treatmentTwo: data[index]['treatmentTwo'],
                                  treatmentThree: data[index]['treatmentThree'],
                                  confidence: data[index]['confidence'],
                                  image: imagebytes,
                                  isStored: true);
                            })));
                          },
                          trailing: DropdownButtonHideUnderline(
                              child: DropdownButton(
                            items: _options.map((e) {
                              return DropdownMenuItem(
                                child: new Text(e),
                                value: e,
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedOption = value ?? '';
                                if (_selectedOption == 'delete') {
                                  //widget.engine.Delete('playlists/${snapshot.data[index]['playlist']}');
                                  var predictionId = data[index]['id'];
                                  databaseHelper.instance
                                      .deletePrediction(predictionId);
                                }
                              });
                              await getdata();
                            },
                            icon: Icon(Icons.more_vert),
                            isDense: false,
                          )),
                          //style: ListTileStyle(),
                        );
                      })),
        );
      })),
    ));
  }
}
