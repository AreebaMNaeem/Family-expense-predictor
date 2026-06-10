// lib/services/family_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  FamilyService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<String> createFamilyGroup({
    required String familyName,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final trimmedName = familyName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Enter a family name.');
    }

    final familyRef = _families.doc();
    final code = await _generateUniqueGroupCode();

    final batch = _firestore.batch();

    batch.set(familyRef, {
      'name': trimmedName,
      'code': code,
      'createdBy': user.uid,
      'memberIds': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      _users.doc(user.uid),
      {
        'uid': user.uid,
        'email': user.email,
        'fullName': user.displayName ?? '',
        'familyId': familyRef.id,
        'familyCode': code,
        'familyName': trimmedName,
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return code;
  }

  Future<void> joinFamilyGroupByCode({
    required String code,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw Exception('Enter a family code.');
    }

    final query = await _families
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No family found with this code.');
    }

    final familyDoc = query.docs.first;
    final familyData = familyDoc.data();

    await _firestore.runTransaction((transaction) async {
      final freshFamily = await transaction.get(familyDoc.reference);
      final currentMembers =
          List<String>.from(freshFamily.data()?['memberIds'] ?? const []);

      if (!currentMembers.contains(user.uid)) {
        currentMembers.add(user.uid);
      }

      transaction.update(familyDoc.reference, {
        'memberIds': currentMembers,
      });

      transaction.set(
        _users.doc(user.uid),
        {
          'uid': user.uid,
          'email': user.email,
          'fullName': user.displayName ?? '',
          'familyId': familyDoc.id,
          'familyCode': familyData['code'] as String? ?? normalizedCode,
          'familyName': familyData['name'] as String? ?? '',
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<String> _generateUniqueGroupCode() async {
    for (int i = 0; i < 10; i++) {
      final code = _randomCode(length: 6);
      final existing =
          await _families.where('code', isEqualTo: code).limit(1).get();

      if (existing.docs.isEmpty) {
        return code;
      }
    }

    throw Exception('Could not generate a unique family code. Try again.');
  }

  String _randomCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}