import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all addresses for a user with real-time updates
  Stream<List<AddressModel>> getAddresses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      final addresses = snapshot.docs
          .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in memory: default first, then by creation date
      addresses.sort((a, b) {
        // First, sort by isDefault (true comes first)
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        // Then sort by createdAt (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return addresses;
    });
  }

  /// Add a new address
  Future<String> addAddress(String userId, AddressModel address) async {
    try {
      // If this is the first address or marked as default, ensure it's the only default
      if (address.isDefault) {
        await _unsetAllDefaults(userId);
      }

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .add(address.toMap());

      if (kDebugMode) {
        debugPrint('✅ Address added: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding address: $e');
      }
      rethrow;
    }
  }

  /// Update an existing address
  Future<void> updateAddress(String userId, AddressModel address) async {
    try {
      // If setting as default, unset all others first
      if (address.isDefault) {
        await _unsetAllDefaults(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());

      if (kDebugMode) {
        debugPrint('✅ Address updated: ${address.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating address: $e');
      }
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      // Check if this is the default address
      final addressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .get();

      final wasDefault = addressDoc.data()?['isDefault'] ?? false;

      // Delete the address
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Address deleted: $addressId');
      }

      // If it was default, set another address as default
      if (wasDefault) {
        await _setFirstAddressAsDefault(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting address: $e');
      }
      rethrow;
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // Unset all defaults first
      await _unsetAllDefaults(userId);

      // Set the selected address as default
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});

      if (kDebugMode) {
        debugPrint('✅ Default address set: $addressId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting default address: $e');
      }
      rethrow;
    }
  }

  /// Get the default address (if any)
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return AddressModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting default address: $e');
      }
      return null;
    }
  }

  /// Check if user has any addresses
  Future<bool> hasAddresses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking addresses: $e');
      }
      return false;
    }
  }

  /// Private: Unset all default addresses for a user
  Future<void> _unsetAllDefaults(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  /// Private: Set the first available address as default
  Future<void> _setFirstAddressAsDefault(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('createdAt', descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({'isDefault': true});
      
      if (kDebugMode) {
        debugPrint('✅ Auto-set first address as default');
      }
    }
  }
}
