import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePicture(File file, String userId) async {
    final ref = _storage.ref().child('profile_pictures/$userId');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadPostImage(File file) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('posts/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadProductImage(File file) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('products/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadEventImage(File file) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('events/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String folder,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
