import 'dart:io';

import 'package:badhandatainput/model/donor_model.dart';
import 'package:badhandatainput/util/badhan_constants.dart';
import 'package:badhandatainput/util/const_ui.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../util/debug.dart';
import '../common/all_donors_widget.dart';

class ExcelWidget extends StatefulWidget {
  const ExcelWidget({
    Key? key,
  }) : super(key: key);
  @override
  _ExcelWidgetState createState() {
    //Log.d("ExcelWidget", "Creating new ExcelWidget");
    return _ExcelWidgetState();
  }
}

class _ExcelWidgetState extends State<ExcelWidget> {
  static String tag = "ExcelWidget";
  final String defaultMsg = "Import an excel file.";

  final List<NewDonor> newDonorList = [];
  final StringBuffer msg = StringBuffer(
      "Import an excel file."); // message displayed in the topbar. e.g."Import an excel file"
  // key: phone number, value: last donation date
  final Map<String, DateTime> lastDonationMap = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      //color: Colors.amber,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Container(
                  // top upload all bar
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          msg.toString(),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Tooltip(
                        message:
                            "Import a formatted excel. Follow instructions.",
                        child: TextButton.icon(
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text("Import Excel"),
                          onPressed: _uploadFile,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              AllDonorsWidget(
                  newDonorList: newDonorList, lastDonationMap: lastDonationMap),
            ],
          ),

          /// floating action button
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              overlayOpacity: 0,
              children: [
                SpeedDialChild(
                    onTap: _uploadFile,
                    //tooltip: 'Add Excel file',
                    label: "Import Excel",
                    child: const Icon(Icons.file_upload),
                    backgroundColor: Colors.amber,
                    labelBackgroundColor: Colors.amber),
                if (newDonorList.isNotEmpty)
                  SpeedDialChild(
                      onTap: _uploadAll,
                      label: "Upload all",
                      child: const Icon(Icons.file_upload_outlined),
                      backgroundColor: Colors.amber,
                      labelBackgroundColor: Colors.amber),
                if (newDonorList.isNotEmpty)
                  SpeedDialChild(
                      onTap: _clearAll,
                      label: "Clear all",
                      child: const Icon(Icons.clear_rounded),
                      backgroundColor: Colors.amber,
                      labelBackgroundColor: Colors.amber)
              ],
            ),
          )
        ],
      ),
    );
  }

  void _uploadAll() {
    if (newDonorList.isEmpty) {
      ConstUI.showErrorToast(context, () {}, "No new donors to upload.");
      return;
    }

    for (NewDonor donor in newDonorList) {
      
    }
  }

  // clears all the data in the excel widget
  void _clearAll() {
    setState(() {
      msg.clear();
      msg.write("Import an excel file.");
      newDonorList.clear();
      lastDonationMap.clear();
    });
  }

  /// uploads an excel file
  ///
  void _uploadFile() async {
    // see: https://pub.dev/packages/file_picker
    final result = await FilePicker.platform
        .pickFiles(allowedExtensions: ['xlsx'], type: FileType.custom);

    if (result == null) {
      Log.d(tag, "No file Picked");
      return;
    }

    PlatformFile file =
        result.files.first; // get the first file from the picked files

    Log.d(tag, "Imported excel file name: ${file.name}");

    // update the message in the top bar
    msg.clear(); // clear "Import an excel file" message
    msg.write("File name: ${file.name}, ");

    // https://github.com/Badhan-BUET-Zone/badhan-datainput/issues/29
    // Handle other files beside xlsx files
    if (file.extension != "xlsx") {
      ConstUI.showErrorToast(
          context, _clearAll, "Unexpected file! Only .xlxs files are allowed.");
      return;
    }

    // https: //stackoverflow.com/questions/45924474/how-do-you-detect-the-host-platform-from-dart-code
    //_openFile(file.path!);
    if (kIsWeb && file.bytes != null) {
      _openFileFromByte(file.bytes!);
    } else if (file.path != null) {
      _openFile(file.path!);
    }
  }

  /// read the data as bytes
  /// this is for desktop app
  void _openFile(String filePath) {
    Log.d(tag, "opening file from : $filePath");
    List<int> bytes = File(filePath).readAsBytesSync();
    _openFileFromByte(bytes);
  }

  /// this is for web app
  void _openFileFromByte(List<int> bytes) async {
    // clear the list to show new data
    // to render new data
    newDonorList.clear();

    Excel excel = Excel.decodeBytes(bytes);

    // frist we check if the data in the 1st sheet of the excel =============
    String sheetName;
    try {
      sheetName = excel.tables.keys.first; // get the 1st sheet name
    } catch (_) {
      ConstUI.showErrorToast(context, _clearAll,
          "No sheet found! Data must be in 1st sheet of the excel file.");
      return;
    }

    // show the sheet name in the ui ====================
    //Log.d(tag, "$fName $sheetName"); //sheet Name
    msg.write("Sheet: $sheetName");

    // now iterate row by row to get the data ==========
    List<String> header = [];

    try {
      int r = 1; // row number
      for (List<Data?> row in excel.tables[sheetName]!.rows) {
        // data of the current row
        Map<String, dynamic> dataMap = {};

        int c = 0; // column number
        //Log.d(tag, "$row");
        for (Data? data in row) {
          /// handle the empty cells ====================================
          if (data == null) {
            if (c >= header.length) {
              continue;
            }
            String h = header[c];
            if (!(h == "comment" || h == "lastDonation" || h == "address")) {
              Log.d(tag, "Empty cell of column $h");
              ConstUI.showErrorToast(
                  context, _clearAll, "Empty cell on row $r, column ${c + 1}");
              return;
            } else {
              c++;
              continue;
            }
          }

          try {
            // first row contains the header names
            if (r == 1) {
              if (data.value != null) {
                header.add(BadhanConst.headerMap(
                    "${data.value}")); // get the mapped header name
              }
            } else {
              if (header.length < 11) {
                // at least 11 fields are required
                ConstUI.showErrorToast(context, _clearAll,
                    "Excel file doesn't contain all the required columns. Please see the instructions!");
                return;
              }

              if (c >= header.length) {
                continue;
              }

              //parse last donation separately
              if (header[c] == "lastDonation") {
                try {
                  if (data.value.toString() != "0") {
                    Log.d(tag, "$r ${c + 1} date: $data");
                    DateTime dateTime = DateTime.parse(data.value.toString());
                    lastDonationMap[dataMap['phone']] = dateTime;
                  }
                } catch (_) {
                  /// https://github.com/Badhan-BUET-Zone/badhan-datainput/issues/26
                  ConstUI.showErrorToast(context, _clearAll,
                      "Invalid last donation date format on row $r, column ${c + 1}. \nDate format must be dd-mm-yyyy.");
                  return;
                }
              } else {
                dataMap[header[c]] = BadhanConst.dataMap(header[c], data.value);
              }
            }
          } on Exception catch (e) {
            String msg = "Error on row $r, column ${c + 1}.\n${e.toString()}.";
            ConstUI.showErrorToast(context, _clearAll, msg);
            return;
          }

          c++; // next column
        }
        if (r > 1) {
          //Log.d(tag, "datamap: $dataMap");
          NewDonor newDonor = NewDonor.fromJson(dataMap);
          newDonorList.add(newDonor);
        }
        r++; // new row
      }
    } catch (_) {
      ConstUI.showErrorToast(context, _clearAll,
          "Error parsing excel information! Please read the instructions carefully.");
    }

    setState(() {});

    /// render the UI with new data
  }
}
