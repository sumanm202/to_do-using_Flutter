import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '/task_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> fetchTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);
    return response.map((task) => Task.fromJson(task)).toList();
  }

  Future<void> addTask(String title, {String? description}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await _client.from('tasks').insert({
      'user_id': user.id,
      'title': title,
      'description': description,
      'is_done': false,
    });
  }

  Future<void> updateTask(String id, bool isDone, [String? title, String? description]) async {
    final updates = {
      'is_done': isDone,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };
    await _client.from('tasks').update(updates).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateProfile(String userId, String name, String phoneNumber, String? profilePictureUrl) async {
    print('Updating profile for user: $userId');
    print('Data: {user_id: $userId, name: $name, phone_number: $phoneNumber, profile_picture_url: $profilePictureUrl}');
    final data = {
      'user_id': userId,
      'name': name.isNotEmpty ? name : null,
      'phone_number': phoneNumber.isNotEmpty ? phoneNumber : null,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      final existingProfile = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (existingProfile == null) {
        await _client.from('profiles').insert(data);
        print('Profile inserted successfully');
      } else {
        await _client.from('profiles').update(data).eq('user_id', userId);
        print('Profile updated successfully');
      }
    } catch (e) {
      print('Supabase operation error: $e');
      throw e;
    }
  }

  Future<String> uploadProfilePicture(String userId, dynamic imageFile) async {
    final fileName = '$userId/profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      if (kIsWeb) {
        if (imageFile is XFile) {
          final bytes = await imageFile.readAsBytes();
          await _client.storage
              .from('profile-pictures')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
        } else {
          throw Exception('Unsupported image file type on web');
        }
      } else {
        if (imageFile is File) {
          await _client.storage
              .from('profile-pictures')
              .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));
        } else {
          throw Exception('Unsupported image file type on mobile');
        }
      }
      final imageUrl = _client.storage.from('profile-pictures').getPublicUrl(fileName);
      print('Uploaded image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw e;
    }
  }
}