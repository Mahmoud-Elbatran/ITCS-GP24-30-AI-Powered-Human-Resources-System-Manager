import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  final TextEditingController titleController = TextEditingController();
  String? selectedNotification;

  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> saveEvent() async {
    if (titleController.text.isEmpty || selectedNotification == null || selectedTime == null) return;

    final DateTime fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await FirebaseFirestore.instance.collection('calendarEvents').add({
      'title': titleController.text,
      'date': Timestamp.fromDate(fullDateTime),
      'notification': selectedNotification,
    });

    titleController.clear();
    setState(() {
      selectedNotification = null;
      selectedTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = selectedTime != null
        ? selectedTime!.format(context)
        : "No time selected";

    return Scaffold(
      appBar: AppBar(title: const Text("Calendar")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add New Event", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Event Title"),
                  ),
                  const SizedBox(height: 20),
                  Text("Event Date: ${selectedDate.toIso8601String().substring(0, 10)}"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Event Time: "),
                      Text(formattedTime),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: pickTime,
                        child: const Text("Pick Time"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedNotification,
                    hint: const Text("Select notification time"),
                    onChanged: (value) {
                      setState(() {
                        selectedNotification = value;
                      });
                    },
                    items: [
                      '5 minutes before',
                      '10 minutes before',
                      '1 hour before',
                      '1 day before',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveEvent,
                    child: const Text("Save Event"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
