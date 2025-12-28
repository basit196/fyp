import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload Profile Image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      String fileName = 'profile_$userId.jpg';
      Reference ref = _storage.ref().child('profiles').child(fileName);

      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Error uploading profile image: $e';
    }
  }

  /// Upload Portfolio Image
  Future<String> uploadPortfolioImage(
      String workerId, File imageFile, int index) async {
    try {
      String fileName = 'portfolio_${workerId}_$index.jpg';
      Reference ref = _storage.ref().child('portfolios').child(fileName);

      // Upload file with metadata
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'workerId': workerId},
        ),
      );

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Error uploading portfolio image: $e';
    }
  }

  /// Delete Image
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Error deleting image: $e';
    }
  }

  /// Upload Multiple Portfolio Images
  Future<List<String>> uploadMultipleImages(
      String workerId, List<File> images) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      String url = await uploadPortfolioImage(workerId, images[i], i);
      urls.add(url);
    }

    return urls;
  }
}


