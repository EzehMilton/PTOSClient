import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';

class CheckInProvider extends ChangeNotifier {
  // -----------------------------------------------------------------------
  // Form state
  // -----------------------------------------------------------------------
  String weight = '';
  double mood = 3;
  double energy = 3;
  double sleep = 3;
  String notes = '';

  File? photoFront;
  File? photoSide;
  File? photoBack;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  // -----------------------------------------------------------------------
  // History list state
  // -----------------------------------------------------------------------
  List<Map<String, dynamic>> _checkins = [];
  List<Map<String, dynamic>> get checkins => _checkins;

  bool _loadingList = false;
  bool get loadingList => _loadingList;

  String? _listError;
  String? get listError => _listError;

  // -----------------------------------------------------------------------
  // Detail state
  // -----------------------------------------------------------------------
  Map<String, dynamic>? _selectedCheckin;
  Map<String, dynamic>? get selectedCheckin => _selectedCheckin;

  bool _loadingDetail = false;
  bool get loadingDetail => _loadingDetail;

  String? _detailError;
  String? get detailError => _detailError;

  final _picker = ImagePicker();

  Future<void> pickPhoto(String position) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);
    switch (position) {
      case 'front':
        photoFront = file;
      case 'side':
        photoSide = file;
      case 'back':
        photoBack = file;
    }
    notifyListeners();
  }

  void removePhoto(String position) {
    switch (position) {
      case 'front':
        photoFront = null;
      case 'side':
        photoSide = null;
      case 'back':
        photoBack = null;
    }
    notifyListeners();
  }

  void reset() {
    weight = '';
    mood = 3;
    energy = 3;
    sleep = 3;
    notes = '';
    photoFront = null;
    photoSide = null;
    photoBack = null;
    _submitting = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'weight': weight,
        'mood': mood.round(),
        'energy': energy.round(),
        'sleep': sleep.round(),
        if (notes.isNotEmpty) 'notes': notes,
      });

      Future<MultipartFile> _multipart(File file, String field) async {
        final ext = file.path.split('.').last.toLowerCase();
        final mime = ext == 'png'
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');
        return MultipartFile.fromFile(file.path,
            filename: '$field.$ext', contentType: mime);
      }

      if (photoFront != null) {
        formData.files
            .add(MapEntry('photoFront', await _multipart(photoFront!, 'front')));
      }
      if (photoSide != null) {
        formData.files
            .add(MapEntry('photoSide', await _multipart(photoSide!, 'side')));
      }
      if (photoBack != null) {
        formData.files
            .add(MapEntry('photoBack', await _multipart(photoBack!, 'back')));
      }

      await ApiClient.instance.dio.post(
        '/api/client/checkins',
        data: formData,
      );

      _submitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      _error = message ?? 'Failed to submit check-in';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // History list
  // -----------------------------------------------------------------------
  Future<void> loadCheckins() async {
    _loadingList = true;
    _listError = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/checkins');
      final list = response.data as List<dynamic>;
      _checkins = list.cast<Map<String, dynamic>>();
      _loadingList = false;
      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      _listError = message ?? 'Failed to load check-ins';
      _loadingList = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------
  // Detail
  // -----------------------------------------------------------------------
  Future<void> loadCheckinDetail(String id) async {
    _loadingDetail = true;
    _detailError = null;
    _selectedCheckin = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/checkins/$id');
      _selectedCheckin = response.data as Map<String, dynamic>;
      _loadingDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      _detailError = message ?? 'Failed to load check-in';
      _loadingDetail = false;
      notifyListeners();
    }
  }
}
