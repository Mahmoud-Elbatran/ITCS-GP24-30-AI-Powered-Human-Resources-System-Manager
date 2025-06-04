import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'chatbot_hr.dart';
import 'resumescreening.dart';
import 'FeedbackAnalysisPage.dart';
import 'CalendarPage.dart';

class HREmployeePage extends StatelessWidget {
  final String userEmail;
  const HREmployeePage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("REBOTA HR Dashboard", style: TextStyle(color: Colors.black)),
            actions: [
              TextButton.icon(
                onPressed: () {
                  // Add logout logic
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome, ${userEmail.split('@')[0]}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text("HR Manager",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _statCard("28", "Active Jobs", Colors.blue[100]!, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _statCard("156", "Applications", Colors.green[100]!, Colors.green)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Quick Actions Grid
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _dashboardTile(
                          icon: Icons.android,
                          label: "AI Chatbot",
                          subLabel: "Quick responses",
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                        ),
                        _dashboardTile(
                          icon: Icons.description,
                          label: "Resume Screening",
                          subLabel: "Review CVs",
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const ResumeScreeningPage())),
                        ),
                        _dashboardTile(
                          icon: Icons.bar_chart,
                          label: "Feedback",
                          subLabel: "Analysis",
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const FeedbackAnalysisPage())),
                        ),
                        _dashboardTile(
                          icon: Icons.calendar_month,
                          label: "Calendar",
                          subLabel: "Schedule",
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const CalendarPage())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    const Text(
                      "Upcoming Events",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('calendarEvents')
                          .orderBy('date')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final now = DateTime.now();

                        final upcomingEvents = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final rawDate = data['date'];

                          try {
                            DateTime eventDate;

                            if (rawDate is String) {
                              eventDate = DateTime.parse(rawDate);
                            } else if (rawDate is Timestamp) {
                              eventDate = rawDate.toDate();
                            } else {
                              return false;
                            }

                            return eventDate.isAfter(now);
                          } catch (_) {
                            return false;
                          }
                        }).toList();

                        if (upcomingEvents.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text("No upcoming events."),
                          );
                        }

                        return Column(
                          children: upcomingEvents.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final rawDate = data['date'];

                            DateTime eventDate;
                            if (rawDate is String) {
                              eventDate = DateTime.parse(rawDate);
                            } else {
                              eventDate = (rawDate as Timestamp).toDate();
                            }

                            final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(eventDate);

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.event, color: Colors.blue),
                                title: Text(data['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedDate),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label, Color bgColor, Color textColor) {
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _dashboardTile({
    required IconData icon,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.blue),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
