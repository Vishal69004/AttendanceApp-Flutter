import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/faculty_log.dart';

class SubjectDetailsWidget extends StatefulWidget {
  final String subject;
  final String section;
  final String time;
  final DateTime? selectedDate;

  const SubjectDetailsWidget({
    required this.subject,
    required this.section,
    required this.time,
    this.selectedDate,
    Key? key,
  }) : super(key: key);

  @override
  _SubjectDetailsWidgetState createState() => _SubjectDetailsWidgetState();
}

class _SubjectDetailsWidgetState extends State<SubjectDetailsWidget> {
  Map<String, bool> buttonStates = {};
  Map<String, String> attendanceData = {};
  Map<String, String> studentNames = {}; // To store student names
  List<String> sortedKeys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final date = widget.selectedDate ?? DateTime.now();
    final formattedDate = '${date.day}-${date.month}-${date.year}';

    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.section)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null) {
        List<String> keys = [];
        for (var key in data.keys) {
          if (data[key] is List<dynamic>) {
            List<dynamic> list = data[key];
            String roll = list[0];
            String name = list[1]; // Extract the student's name
            studentNames[roll] = name; // Store the name in the map
            keys.add(roll);

            final snapshot2 = await FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.section)
                .collection(roll)
                .doc(widget.subject)
                .get();

            if (snapshot2.exists) {
              final data2 = snapshot2.data();
              if (data2 != null) {
                for (var key in data2.keys) {
                  print(key.split(' -')[0] + "1");
                  print(formattedDate +
                      " " +
                      widget.time.split('-')[0].split(' ')[0] +
                      "2");
                  if (key.split(' -')[0].compareTo(formattedDate +
                          " " +
                          widget.time.split('-')[0].split(' ')[0]) ==
                      0) {
                    print("hi");
                    attendanceData[roll] = data2[key] == 'p' ? 'p' : 'a';
                    buttonStates[roll] = data2[key] != 'p';
                  }
                }
              }
            } else {
              attendanceData[roll] = 'p'; // Default to 'p' if no data exists
              buttonStates[roll] = false;
            }
          }
        }

        // Sort the keys based on the last three digits
        keys.sort((a, b) {
          String lastThreeDigitsA = a.padLeft(3, '0').substring(a.length - 3);
          String lastThreeDigitsB = b.padLeft(3, '0').substring(b.length - 3);
          return lastThreeDigitsA.compareTo(lastThreeDigitsB);
        });

        setState(() {
          sortedKeys = keys;
          isLoading = false;
        });
      }
    }
  }

  int getTotalStudents() {
    return sortedKeys.length;
  }

  int getPresentCount() {
    return attendanceData.values.where((status) => status == 'p').length;
  }

  int getAbsentCount() {
    return attendanceData.values.where((status) => status == 'a').length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "ATTENDANCE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        ),
        backgroundColor: const Color.fromARGB(255, 151, 195, 220),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    int totalStudents = getTotalStudents();
    int presentCount = getPresentCount();
    int absentCount = getAbsentCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ATTENDANCE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Total: $totalStudents',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Present: $presentCount',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Absent: $absentCount',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final roll = sortedKeys[index];
                final isButtonPressed = buttonStates[roll] ?? false;
                final isAbsent = attendanceData[roll] == 'a';
                final studentName =
                    studentNames[roll] ?? 'Unknown'; // Get the student's name

                // Extract the last 3 characters from roll
                String lastThreeChars =
                    roll.length >= 3 ? roll.substring(roll.length - 3) : roll;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        buttonStates[roll] = !isButtonPressed;
                        attendanceData[roll] = isButtonPressed ? 'p' : 'a';
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        isAbsent ? Colors.red : Colors.white,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 10.0,
                        ),
                        Text(lastThreeChars), // Use the last 3 characters
                        const SizedBox(
                          width: 70.0,
                        ),
                        Text(studentName), // Display the student's name
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                submitAttendance();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const FacultyLog()),
                  (Route<dynamic> route) =>
                      false, // This predicate removes all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  void submitAttendance() async {
    final date = widget.selectedDate ?? DateTime.now();
    final formattedDate = '${date.day}-${date.month}-${date.year}';

    // Initialize attendance data for all students with default value 'p'
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.section)
        .get();
    final data = snapshot.data();
    if (data != null) {
      for (var key in data.keys) {
        if (data[key] is List<dynamic>) {
          List<dynamic> list = data[key];
          String roll = list[0];
          // Ensure each roll is present in attendanceData
          if (!attendanceData.containsKey(roll)) {
            attendanceData[roll] = 'p';
          }
        }
      }
    }

    // Update attendance status based on button states
    for (var roll in attendanceData.keys) {
      bool isPressed = buttonStates[roll] ?? false;
      attendanceData[roll] = isPressed ? 'a' : 'p';
    }

    // Calculate the number of periods based on the time difference
    final times = widget.time.split('-');
    final startTime = times[0];
    final endTime = times[1];

    final startHourMinute = startTime.split(':').map(int.parse).toList();
    final endHourMinute = endTime.split(':').map(int.parse).toList();

    final startMinutes = startHourMinute[0] * 60 + startHourMinute[1];
    final endMinutes = endHourMinute[0] * 60 + endHourMinute[1];

    final timeDifference = endMinutes - startMinutes;
    final numPeriods =
        (timeDifference / 45).floor(); // Calculate number of periods

    print(startMinutes);
    print(endMinutes);
    print(numPeriods);

    if (numPeriods == 1) {
      // Update Firestore with the attendance data for the single period
      for (var entry in attendanceData.entries) {
        String studentId = entry.key;
        String status = entry.value;
        String periodTime = '$formattedDate $startTime -${startMinutes + 45}';
        await updateAttendance(studentId, status, periodTime);
      }
    } else {
      // Update Firestore with the attendance data for each period
      for (int period = 0; period < numPeriods; period++) {
        for (var entry in attendanceData.entries) {
          String studentId = entry.key;
          String status = entry.value;
          String periodTime =
              '$formattedDate $startTime-${startMinutes + 45 * (period + 1)}';
          await updateAttendance(studentId, status, periodTime);
        }
      }
    }
  }

  Future<void> updateAttendance(
      String studentId, String status, String formattedDate) async {
    final attendanceRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.section)
        .collection(studentId)
        .doc(widget.subject);

    // Set attendance for current date
    await attendanceRef.set({
      formattedDate: status,
    }, SetOptions(merge: true));

    // Retrieve updated data to calculate the attendance percentage
    final querySnapshot = await attendanceRef.get();
    final attendanceData = querySnapshot.data() as Map<String, dynamic>?;

    // Handle the case where attendanceData is null or empty
    if (attendanceData == null || attendanceData.isEmpty) {
      // Set initial values for percentage and totalClasses
      await attendanceRef.set({
        'percentage': status == 'p' ? 100.0 : 0.0,
        'totalClasses': 1,
      }, SetOptions(merge: true));
      return;
    }

    // Remove 'percentage' and 'totalClasses' entries for counting
    final dataToCount = Map.of(attendanceData);
    dataToCount.remove('percentage');
    dataToCount.remove('totalClasses');

    final totalEntries = dataToCount.length;
    final absentCount =
        dataToCount.values.where((value) => value == 'a').length;
    final presentCount = totalEntries - absentCount;
    final attendancePercentage =
        totalEntries > 0 ? (presentCount / totalEntries) * 100 : 0.0;

    // Update attendance percentage for the student
    await attendanceRef.set({
      'percentage': attendancePercentage,
      'totalClasses': totalEntries,
    }, SetOptions(merge: true));
  }
}
