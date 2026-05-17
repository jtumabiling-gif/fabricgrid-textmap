import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDebugService {

  factory FirebaseDebugService() => _instance;

  FirebaseDebugService._internal();
  static final FirebaseDebugService _instance = FirebaseDebugService._internal();
  late FirebaseFirestore _firestore;

  void initialize() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Check all collections in Firestore
  Future<void> listAllCollections() async {
    try {
      print('\n========== FIREBASE DEBUG INFO ==========');
      
      // Check products collection specifically
      print('--- Checking "products" collection ---');
      final productsSnapshot = await _firestore.collection('products').limit(10).get();
      
      print('Total documents in products collection: ${productsSnapshot.size}');
      
      if (productsSnapshot.docs.isEmpty) {
        print('WARNING: No documents found in products collection!');
      } else {
        for (final doc in productsSnapshot.docs) {
          print('\nDocument ID: ${doc.id}');
          print('Data: ${doc.data()}');
        }
      }
      
      print('\n========== END DEBUG INFO ==========\n');
    } catch (e) {
      print('Error during debug: $e');
    }
  }

  /// Check a specific collection
  Future<void> checkCollection(String collectionName) async {
    try {
      print('\n========== Checking collection: $collectionName ==========');
      
      final snapshot = await _firestore.collection(collectionName).limit(5).get();
      
      print('Total documents: ${snapshot.size}');
      
      if (snapshot.docs.isEmpty) {
        print('No documents in this collection');
      } else {
        for (final doc in snapshot.docs) {
          print('\nDoc ID: ${doc.id}');
          print('Data: ${doc.data()}');
        }
      }
      
      print('========== End ==========\n');
    } catch (e) {
      print('Error checking collection: $e');
    }
  }
}
