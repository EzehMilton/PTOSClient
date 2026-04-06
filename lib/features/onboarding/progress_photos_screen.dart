import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/constants.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  _SelectedPhoto? _frontPhoto;
  _SelectedPhoto? _sidePhoto;
  _SelectedPhoto? _backPhoto;

  bool _submitting = false;
  String? _error;

  Future<void> _pickPhoto(
    _PhotoSlot slot,
    ImageSource source,
  ) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No photo selected')),
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _error = null;
        switch (slot) {
          case _PhotoSlot.front:
            _frontPhoto = _SelectedPhoto(file: picked, bytes: bytes);
          case _PhotoSlot.side:
            _sidePhoto = _SelectedPhoto(file: picked, bytes: bytes);
          case _PhotoSlot.back:
            _backPhoto = _SelectedPhoto(file: picked, bytes: bytes);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not access your camera or photo library. Check permissions and try again.',
          ),
        ),
      );
    }
  }

  void _removePhoto(_PhotoSlot slot) {
    setState(() {
      switch (slot) {
        case _PhotoSlot.front:
          _frontPhoto = null;
        case _PhotoSlot.side:
          _sidePhoto = null;
        case _PhotoSlot.back:
          _backPhoto = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_frontPhoto == null && _sidePhoto == null && _backPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one photo or choose Skip for now'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiClient.instance.uploadProfilePhotos(
        frontPhoto: _frontPhoto?.file,
        sidePhoto: _sidePhoto?.file,
        backPhoto: _backPhoto?.file,
      );

      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress photos uploaded')),
      );
      context.go(Routes.connectHealthData);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = message ?? 'Failed to upload progress photos';
      });
    }
  }

  void _skip() {
    context.go(Routes.connectHealthData);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B5CF6);
    const panel = Color(0xFF171826);
    const field = Color(0xFF1E2031);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF11131C),
              Color(0xFF0C0D14),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2A000000),
                        blurRadius: 32,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go(Routes.experienceAndHealth),
                            style: IconButton.styleFrom(
                              backgroundColor: field,
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                          const Spacer(),
                          const _ProgressStepIndicator(
                            currentStep: 6,
                            totalSteps: 7,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Progress photos',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Upload clear front, side, and back photos so your PT can track progress accurately over time.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Tip: stand in good lighting against a plain background and keep the camera at chest height for each shot.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _PhotoCard(
                        title: 'Front photo',
                        photo: _frontPhoto,
                        onUpload: () => _pickPhoto(_PhotoSlot.front, ImageSource.gallery),
                        onCapture: () => _pickPhoto(_PhotoSlot.front, ImageSource.camera),
                        onRemove: () => _removePhoto(_PhotoSlot.front),
                      ),
                      const SizedBox(height: 14),
                      _PhotoCard(
                        title: 'Side photo',
                        photo: _sidePhoto,
                        onUpload: () => _pickPhoto(_PhotoSlot.side, ImageSource.gallery),
                        onCapture: () => _pickPhoto(_PhotoSlot.side, ImageSource.camera),
                        onRemove: () => _removePhoto(_PhotoSlot.side),
                      ),
                      const SizedBox(height: 14),
                      _PhotoCard(
                        title: 'Back photo',
                        photo: _backPhoto,
                        onUpload: () => _pickPhoto(_PhotoSlot.back, ImageSource.gallery),
                        onCapture: () => _pickPhoto(_PhotoSlot.back, ImageSource.camera),
                        onRemove: () => _removePhoto(_PhotoSlot.back),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFF7A7A)),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            disabledBackgroundColor:
                                accent.withValues(alpha: 0.55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Upload photos',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PhotoSlot {
  front,
  side,
  back,
}

class _SelectedPhoto {
  const _SelectedPhoto({
    required this.file,
    required this.bytes,
  });

  final XFile file;
  final Uint8List bytes;
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.title,
    required this.photo,
    required this.onUpload,
    required this.onCapture,
    required this.onRemove,
  });

  final String title;
  final _SelectedPhoto? photo;
  final VoidCallback onUpload;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2031),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (photo != null)
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF12131C),
                child: photo == null
                    ? Center(
                        child: Text(
                          'No photo selected',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                        ),
                      )
                    : Image.memory(
                        photo!.bytes,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUpload,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Upload'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onCapture,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Capture'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStepIndicator extends StatelessWidget {
  const _ProgressStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Step $currentStep',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isComplete = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;
            final color = isCurrent
                ? const Color(0xFF7B5CF6)
                : isComplete
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16);

            return Container(
              width: isCurrent ? 30 : 18,
              height: 6,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
