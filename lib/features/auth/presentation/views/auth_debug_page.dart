import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDebugPage extends ConsumerStatefulWidget {
  const AuthDebugPage({super.key});

  @override
  ConsumerState<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends ConsumerState<AuthDebugPage> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugMessage(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  Future<void> _testFirestoreConnection() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addDebugMessage('🔥 Testing Firestore connection...');

      // Test 1: Check if Firestore is accessible
      final firestore = FirebaseFirestore.instance;
      _addDebugMessage('✅ Firestore instance created');

      // Test 2: Try to read from users collection
      _addDebugMessage('📖 Attempting to read users collection...');
      final usersSnapshot = await firestore.collection('users').limit(1).get();
      _addDebugMessage(
        '✅ Users collection accessible. Found ${usersSnapshot.docs.length} documents',
      );

      // Test 3: Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _addDebugMessage(
          '👤 Current user: ${currentUser.email} (${currentUser.uid})',
        );

        // Test 4: Try to create a test document as authenticated user
        _addDebugMessage('📝 Creating test document as authenticated user...');
        final testDocRef = firestore
            .collection('users')
            .doc('test-user-${DateTime.now().millisecondsSinceEpoch}');
        await testDocRef.set({
          'email': 'test@example.com',
          'username': 'testuser',
          'registeredAt': Timestamp.now(),
          'isTest': true,
        });
        _addDebugMessage('✅ Test document created successfully');

        // Test 5: Read the test document back
        _addDebugMessage('📖 Reading test document back...');
        final testDoc = await testDocRef.get();
        if (testDoc.exists) {
          _addDebugMessage('✅ Test document read successfully');
          _addDebugMessage('📄 Document data: ${testDoc.data()}');
        }

        // Test 6: Delete the test document
        _addDebugMessage('🗑️ Cleaning up test document...');
        await testDocRef.delete();
        _addDebugMessage('✅ Test document deleted');
      } else {
        _addDebugMessage(
          '⚠️ No authenticated user - some tests will be skipped',
        );
        _addDebugMessage('💡 Sign in first to test authenticated operations');
      }

      _addDebugMessage(
        '🎉 All Firestore tests passed! Database is working correctly.',
      );
    } catch (e) {
      _addDebugMessage('❌ Firestore test failed: $e');

      if (e.toString().contains('PERMISSION_DENIED')) {
        _addDebugMessage(
          '🔒 Permission denied - Firestore security rules may be too restrictive',
        );
        _addDebugMessage('💡 Solution: Enable test mode in Firestore console');
      } else if (e.toString().contains('NOT_FOUND')) {
        _addDebugMessage('🔍 Firestore database not found');
        _addDebugMessage(
          '💡 Solution: Create Firestore database in Firebase console',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _listAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addDebugMessage('👥 Fetching all users from Firestore...');

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('registeredAt', descending: true)
          .get();

      _addDebugMessage(
        '📊 Found ${usersSnapshot.docs.length} users in database',
      );

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        _addDebugMessage(
          '👤 User: ${data['username']} (${data['email']}) - Registered: ${data['registeredAt']?.toDate()}',
        );
      }

      if (usersSnapshot.docs.isEmpty) {
        _addDebugMessage('📭 No users found. Try creating an account first.');
      }
    } catch (e) {
      _addDebugMessage('❌ Failed to list users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Firestore Debug'),
        backgroundColor: Colors.orange.withOpacity(0.1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '🔥 Firestore Database Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testFirestoreConnection,
                      icon: const Icon(Icons.science),
                      label: const Text('Test Firestore Connection'),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _listAllUsers,
                      icon: const Icon(Icons.people),
                      label: const Text('List All Users'),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _debugOutput = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Output'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '📋 Debug Output',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _debugOutput.isEmpty
                                  ? 'Tap "Test Firestore Connection" to start debugging...'
                                  : _debugOutput,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
