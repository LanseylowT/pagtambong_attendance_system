import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/resources/CheckgaColors.dart';
import 'package:pagtambong_attendance_system/service/AttendanceService.dart';
import 'package:pagtambong_attendance_system/service/CacheService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/service/OfflineAttendanceService.dart';
import 'package:pagtambong_attendance_system/widgets/generic_form_fields.dart';

LogService logger = LogService();

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // TODO: Check the currently signed in user and implement shit according to role
  final currentUser = FirebaseAuth.instance.currentUser;

  final CollectionReference _studentsDb =
      FirebaseFirestore.instance.collection('student-info');
  final CollectionReference _eventsDB =
      FirebaseFirestore.instance.collection('events');

  HashSet _scannedIdNums = HashSet();
  String _selectedEvent = "Select an event";
  String _output = "";
  bool _scanned = false; // this variable does something now

  // For Internet Connectivity Check
  bool isConnectedToInternet = false;
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<InternetConnectionStatus>?
      _internetConnectionStreamSubscription;

  // For offline shit
  final OfflineAttendanceService _offlineAttendanceService =
      OfflineAttendanceService();
  final EventCacheService _eventCache = EventCacheService();

  @override
  void initState() {
    super.initState();

// Check initial connectivity status
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        isConnectedToInternet = result != ConnectivityResult.none;
      });
      _eventCache.initialize(isConnectedToInternet);
    });

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      setState(() {
        isConnectedToInternet =
            results.isNotEmpty && results.first != ConnectivityResult.none;
      });
      await _offlineAttendanceService.syncPendingAttendance();
      _eventCache.handleConnectivityChange(isConnectedToInternet);
      if (!isConnectedToInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Internet Connection')),
        );
      }
    });

    /*// Check initial connectivity status
    InternetConnectionCheckerPlus().hasConnection.then((connected) {
      setState(() {
        isConnectedToInternet = connected;
      });
      _eventCache.initialize(isConnectedToInternet);
    });
    // Listen for connectivity changes
    _internetConnectionStreamSubscription =
        InternetConnectionCheckerPlus().onStatusChange.listen((event) {
          switch (event) {
            case InternetConnectionStatus.connected:
              setState(() async {
                isConnectedToInternet = true;
                await _offlineAttendanceService.syncPendingAttendance();
              });
              _eventCache.handleConnectivityChange(true);
              break;
            case InternetConnectionStatus.disconnected:
              setState(() {
                isConnectedToInternet = false;
              });
              _eventCache.handleConnectivityChange(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No Internet Connection')),
              );
              break;
          }
        });
    _eventCache.initialize(isConnectedToInternet);
    _lifecycleListener = AppLifecycleListener(
      onResume: _internetConnectionStreamSubscription?.resume,
      onHide: _internetConnectionStreamSubscription?.pause,
      onPause: _internetConnectionStreamSubscription?.pause,
    );*/
  }

  @override
  void dispose() {
    _eventCache.dispose();
    _internetConnectionStreamSubscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      drawer: const DefaultDrawer(),
      body: Center(child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        final Size layoutSize = constraints.biggest;
        const double scanWindowHeight = 100;
        const double scanWindowWidth = 300;

        final Rect scanWindow = Rect.fromCenter(
          center: layoutSize.center(Offset.zero),
          width: scanWindowWidth,
          height: scanWindowHeight,
        );

        return MobileScanner(
          controller: controller,
          scanWindow: scanWindow,
          overlayBuilder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      child: Container(
                        width: scanWindowWidth,
                        height: scanWindowHeight,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          // Transparent background to mimic a scanner window
                          border: Border.all(
                            color: Colors.blue,
                            // Border color to resemble scanner outline
                            width: 5.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          // Rounded corners
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              // Subtle shadow to give it some depth
                              offset: Offset(0, 2),
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: Text(
                          _output,
                          style: const TextStyle(
                            color: Colors.white, // Text color to stand out
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // clears the id number label when switching events
                            _output = "";
                          });

                          showModalBottomSheet<void>(
                            backgroundColor: Colors.white,
                            showDragHandle: true,
                            context: context,
                            builder: (BuildContext context) {
                              final Stream<QuerySnapshot> streamEventsDB =
                                  _eventsDB
                                      .where('is_open', isEqualTo: true)
                                      .snapshots();

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: SizedBox(
                                  height: 300,
                                  child: StreamBuilder<List<Event>>(
                                    stream: _eventCache.getEventStream(),
                                    builder: (context,
                                        AsyncSnapshot<List<Event>> snapshot) {
                                      logger.i("Events: ${snapshot.data}");
                                      if (snapshot.hasData) {
                                        final events = snapshot.data!;
                                        return ListView.separated(
                                          itemCount: events.length,
                                          itemBuilder: (context, index) {
                                            Event eventModel = events[index];
                                            return Material(
                                              color: Colors.white,
                                              child: ListTile(
                                                title: Text(
                                                  eventModel.eventName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 20,
                                                      color: AppColors
                                                          .darkFontColor),
                                                ),
                                                subtitle: Text(
                                                  eventModel.venue,
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .subtitleFontColor),
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedEvent =
                                                        eventModel.eventName;
                                                    _scannedIdNums = HashSet();
                                                  });
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            );
                                          },
                                          separatorBuilder:
                                              (BuildContext context,
                                                      int index) =>
                                                  const Divider(),
                                        );
                                      }
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                  ),

                                  /*StreamBuilder(
                                    stream: streamEventsDB,
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot>
                                            streamSnapshot) {
                                      if (streamSnapshot.hasData) {
                                        // Listview.separated is used for adding gaps
                                        return ListView.separated(
                                            // padding: const EdgeInsets.all(10),
                                            itemCount: streamSnapshot
                                                .data!.docs.length,
                                            itemBuilder: (context, index) {
                                              Event eventModel = Event(
                                                  eventName:
                                                      streamSnapshot.data!.docs[index]
                                                          ['event_name'],
                                                  date: (streamSnapshot.data!.docs[index]
                                                          ['date'] as Timestamp)
                                                      .toDate(),
                                                  isOpen: streamSnapshot.data!
                                                      .docs[index]['is_open'],
                                                  organizer: streamSnapshot
                                                      .data!
                                                      .docs[index]['organizer'],
                                                  venue: streamSnapshot.data!
                                                      .docs[index]['venue']);
                                              return Material(
                                                color: Colors.white,
                                                child: ListTile(
                                                  title: Text(
                                                    eventModel.eventName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 20,
                                                        color: AppColors
                                                            .darkFontColor),
                                                  ),
                                                  subtitle: Text(
                                                    eventModel
                                                        .getFormatedDateString(),
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .subtitleFontColor),
                                                  ),
                                                  trailing: Text(
                                                    eventModel
                                                        .getFormatedTimeString(),
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .acccentFontColor,
                                                        fontSize: 16),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedEvent =
                                                          eventModel.eventName;
                                                      _scannedIdNums =
                                                          HashSet();
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              );
                                            },
                                            separatorBuilder: (BuildContext
                                                        context,
                                                    int index) =>
                                                const SizedBox(
                                                  height: 0,
                                                  //sets the border to 0
                                                  child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                    color: Color.fromARGB(
                                                        255, 0, 42, 77),
                                                  )),
                                                ));
                                      }

                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                  )*/
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Background color
                            borderRadius:
                                BorderRadius.circular(5), // Add rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              child: Row(
                                children: [
                                  Text(
                                    _selectedEvent,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: AppColors.darkFontColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.acccentFontColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
          onDetect: (barcodes) async {
            if (_scanned) return; // useless var
            setState(() {
              _scanned = true;
            });
            if (_selectedEvent == "Select an event") {
              Fluttertoast.showToast(
                msg: "Please select an event",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0,
              );
              setState(() {
                _scanned = false;
              });
              return;
            }
            String output = barcodes.barcodes.first.displayValue!;

            output = output.substring(
                1, output.length); // removes the 's' from the scanned barcode

            // ends the function when the id number does not have exactly 6 digits, starts with 1, and contains letters
            // this speeds up the scanning since it rejects the invalid id numbers
            if (!RegExp(r'^\d{6}$').hasMatch(output) ||
                !output.startsWith('1') ||
                RegExp(r'[A-Za-z]').hasMatch(output)) {
              return;
            }

            if (_scannedIdNums.contains(output)) {
              setState(() {
                _scanned = false;
              });

              return;
            } else {
              _scannedIdNums.add(output);
            }

            await fetchStudentAndEvent(output, _selectedEvent);

            setState(() {
              _output = output;
              _scannedIdNums = _scannedIdNums;
              _scanned = false;
            });
          },
        );
      })),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await fetchLatestData();
              controller.stop();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Manually Add Student',
                  ),
                  content: SizedBox(
                    height: 150,
                    child: GenericFormFields(
                      fields: [
                        FormFieldData(
                            key: 'studentId',
                            label: "Student ID",
                            isChoiceField: false,
                            isDateField: false,
                            isTimeField: false,
                            isNumericOnly: true),
                      ],
                      onSubmit: (Map<String, String> formData) async {
                        try {
                          if (_selectedEvent == "Select an event") {
                            Fluttertoast.showToast(
                                msg: "Please select an event",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                            setState(() {
                              _scanned = false;
                            });
                            return;
                          }

                          final studentID = formData['studentId'];
                          logger.i("Manual Student ID: $studentID");
                          await fetchStudentAndEvent(
                              studentID!, _selectedEvent);

                          setState(() {
                            _output = studentID;
                            _scannedIdNums = _scannedIdNums;
                            _scanned = false;
                          });
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg:
                                "Some error occurred when trying manually add student",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.blue,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          logger.e("Error Manually Adding Student: $e");
                        }
                      },
                    ),
                  ),
                ),
              ).then((_) {
                controller.start();
              });
            },
            child: const Icon(Icons.person_add_alt),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              controller.toggleTorch();
            },
            child: const Icon(Icons.lightbulb_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 0),
    );
  }

  Future<void> fetchStudentAndEvent(
      String studentID, String selectedEvent) async {
    try {
      if (isConnectedToInternet) {
        // Online Mode
        QuerySnapshot student = await _studentsDb
            .where('is_deleted', isEqualTo: false)
            .where('student_id', isEqualTo: studentID)
            .get();

        QuerySnapshot event = await _eventsDB
            .where('is_deleted', isEqualTo: false)
            .where('event_name', isEqualTo: selectedEvent)
            .get();

        // logger.i("Is Student Doc Empty: ${student.docs.isEmpty}");
        // logger.i("Is Event Doc Empty: ${event.docs.isEmpty}");

        if (student.docs.isNotEmpty && event.docs.isNotEmpty) {
          QueryDocumentSnapshot studentQueryDoc = student.docs.first;
          QueryDocumentSnapshot eventQueryDoc = event.docs.first;

          if (studentQueryDoc.data() != null &&
              studentQueryDoc.data() is Map<String, dynamic>) {
            Student studentModel =
                Student.fromMap(studentQueryDoc.data() as Map<String, dynamic>);

            // Cache data for offline use
            logger.i("Student Model: ${studentModel.firstName}");
            logger.i("Event Query Doc: ${eventQueryDoc.id}");

            // await _offlineAttendanceService.cacheStudentData(studentModel);
            // await _offlineAttendanceService.cacheEventReference(eventQueryDoc.id, _selectedEvent);

            // Mark attendance online
            String firstName = studentModel.firstName;
            DocumentReference studentDocRef = studentQueryDoc.reference;
            DocumentReference eventDocRef = eventQueryDoc.reference;

            await AttendanceService.makePresent(studentDocRef, eventDocRef);
            await _offlineAttendanceService.cacheStudentData(studentModel);
            await _offlineAttendanceService.cacheEventReference(
              eventDocRef.id,
              _selectedEvent,
            );
            Fluttertoast.showToast(
              msg: firstName,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            logger.e("Student data is null or not a Map");
            Fluttertoast.showToast(
              msg: "Error: Student data is invalid",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }

          // Cache data for offline use
          // await _offlineAttendanceService.cacheStudentData(studentModel);
          /*await _offlineAttendanceService.cacheEventReference(
            eventQueryDoc.id,
            selectedEvent,
          );

          // Mark attendance online
          String firstName = studentModel.firstName;
          DocumentReference studentDocRef = studentQueryDoc.reference;
          DocumentReference eventDocRef = eventQueryDoc.reference;*/
        } else {
          Fluttertoast.showToast(
              msg: "${studentID} is not found",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      }
    } catch (e) {
      logger.e("Error processing attendance: $e, $isConnectedToInternet");
      Fluttertoast.showToast(
        msg: "${studentID} is not found",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> fetchLatestData() async {
    try {
      QuerySnapshot students = await _studentsDb.get();
      QuerySnapshot events = await _eventsDB.get();

      if (students.docs.isNotEmpty && events.docs.isNotEmpty) {
        setState(() {
          // _output = "Data Synced";
          _scannedIdNums = HashSet();
          _selectedEvent = _selectedEvent;
          isConnectedToInternet = true;
        });
      }
    } catch (e) {
      logger.e("Error fetching latest data: $e");
      Fluttertoast.showToast(
        msg: "Error syncing data",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
  }
}
