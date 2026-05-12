import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  List<XFile> _selectedFiles = [];
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedFiles.add(picked);
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      List<String> mediaUrls = [];
      
      for (var file in _selectedFiles) {
        final result = await _api.uploadXFile(file, folder: 'posts');
        if (result.containsKey('url')) {
          mediaUrls.add(result['url']);
        }
      }

      await _api.createPost(
        content: content,
        mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate post created
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: AppPalette.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppPalette.textPrimary),
        title: const Text('Create Post', style: TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.primaryAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isPosting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(fontSize: 16, color: AppPalette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind? Share an insight, deal, or update...",
                        hintStyle: TextStyle(color: AppPalette.textTerenary, fontSize: 16),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedFiles.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _selectedFiles.map((file) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.network(
                                        file.path,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(file.path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFiles.remove(file);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.image, color: AppPalette.primaryAccent),
                    onPressed: _pickImage,
                    tooltip: 'Add Image',
                  ),
                  // Additional media types can be added here
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
