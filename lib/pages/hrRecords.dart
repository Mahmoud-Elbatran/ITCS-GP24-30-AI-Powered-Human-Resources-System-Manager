import 'package:flutter/material.dart';

class HRRecordsPage extends StatelessWidget {
  HRRecordsPage({super.key});

  final Map<String, dynamic> user = {
    'name': 'zeina zidan w as7bha',
    'position': 'Software Engineer',
    'employeeId': 'EMP2025-0456',
    'department': 'Engineering',
    'joinDate': 'April 20, 2024',
    'annualLeaveDays': 14,
    'sickLeaveDays': 6,
    'baseSalary': 78000,
    'bonus': 4000,
    'performanceReviews': [
      {

        'title': 'Q1 2025 Review',
        'rating': 4.7,
        'comment': 'Exceeds Expectations'
      },
      {
        'title': 'Q4 2024 Review',
        'rating': 4.3,
        'comment': 'Meets Expectations'
      },
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Your HR Records'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildLeaveBalance(),
            const SizedBox(height: 16),
            _buildSalaryDetails(),
            const SizedBox(height: 16),
            _buildPerformanceReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/profile.png'), // optional
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user['position'],
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Employee ID', user['employeeId']),
                      _buildInfoColumn('Department', user['department']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoColumn('Join Date', user['joinDate']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLeaveBalance() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Balance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLeaveCard('Annual Leave',
                    '${user['annualLeaveDays']} days', Colors.blue.shade50),
                const SizedBox(width: 12),
                _buildLeaveCard('Sick Leave', '${user['sickLeaveDays']} days',
                    Colors.green.shade50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveCard(String title, String days, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(days,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryDetails() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Salary Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSalaryRow('Base Salary', '\$${user['baseSalary']}/year'),
            const Divider(),
            _buildSalaryRow('Bonus', '\$${user['bonus']}'),
            const Divider(),
            _buildSalaryRow(
                'Total', '\$${user['baseSalary'] + user['bonus']}/year',
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceReviews() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(user['performanceReviews'].length, (index) {
              final review = user['performanceReviews'][index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(review['title']),
                subtitle: Text(review['comment']),
                trailing: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${review['rating']}/5',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
