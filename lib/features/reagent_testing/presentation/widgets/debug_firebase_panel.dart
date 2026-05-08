import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/services/unified_data_service.dart';
import '../providers/reagent_testing_providers.dart';

class DebugFirebasePanel extends ConsumerWidget {
  const DebugFirebasePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Unified Data Service
    final unifiedService = ref.watch(unifiedDataServiceProvider);

    return StreamBuilder<DataSnapshot>(
      stream: unifiedService.onSnapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            color: Colors.black87,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '🛠 Debug: Waiting for Remote Config...',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final FirebaseApp app = Firebase.app();
        final String projectId = app.options.projectId;

        return Card(
          color: Colors.black87,
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🛠 Firebase & RC Debug Panel',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                      tooltip: 'Force Refresh Remote Config',
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forcing Remote Config Fetch...')),
                        );
                        try {
                          await unifiedService.refresh();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to fetch: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                _buildRow(
                  'Connected to Project ID:', 
                  projectId, 
                  Colors.lightBlueAccent,
                ),
                _buildRow(
                  'Firebase Connected:', 
                  data.isFirebase ? 'YES (Online)' : 'NO (Offline)', 
                  data.isFirebase ? Colors.greenAccent : Colors.redAccent,
                ),
                _buildRow(
                  'Data Source Status:', 
                  data.source.name.toUpperCase(), 
                  Colors.amberAccent,
                ),
                _buildRow(
                  'Number of Tests Loaded:', 
                  '${data.reagents.length} tests', 
                  Colors.white,
                ),
                _buildRow(
                  'Last RC Fetch Time:', 
                  _formatTime(data.loadedAt), 
                  Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor, 
                fontSize: 13, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
