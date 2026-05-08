import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  final List<Map<String, dynamic>> recentTests = const [
    {
      'name': 'Marquis Test',
      'sample': 'Unknown White Powder',
      'time': '2 hours ago',
      'color': Colors.orange,
    },
    {
      'name': 'Mecke Test',
      'sample': 'Crystalline Fragment',
      'time': '5 hours ago',
      'color': Colors.green,
    },
    {
      'name': 'Simon\'s Test',
      'sample': 'Liquid Sample A',
      'time': '1 day ago',
      'color': Colors.blue,
    },
    {
      'name': 'Ehrlich Test',
      'sample': 'Blotter Paper',
      'time': '2 days ago',
      'color': Colors.purple,
    },
    {
      'name': 'Mandelin Test',
      'sample': 'Pill Crushed',
      'time': '1 week ago',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Test Results'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: recentTests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = recentTests[index];
            return Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(item['sample'], style: TextStyle(color: Colors.grey[700])),
                ),
                trailing: Text(
                  item['time'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );
  }
}
