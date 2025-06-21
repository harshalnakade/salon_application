import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';

class SalonMoreDetailsFormScreen extends StatefulWidget {
  const SalonMoreDetailsFormScreen({super.key, required String salonId});

  @override
  State<SalonMoreDetailsFormScreen> createState() =>
      _SalonMoreDetailsFormScreenState();
}

class _SalonMoreDetailsFormScreenState
    extends State<SalonMoreDetailsFormScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();

  List<File> _selectedImages = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _uploadedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchUploadedImages();
  }

  Future<void> _fetchUploadedImages() async {
    final salonId = Provider.of<UserProvider>(context, listen: false).salonId;
    final response = await supabase
        .from('salon_images')
        .select()
        .eq('salon_id', salonId as Object)
        .order('created_at');
    setState(() {
      _uploadedImages = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((x) => File(x.path)).toList();
      });
    }
  }

  Future<void> _uploadImages(String salonId) async {
    for (File file in _selectedImages) {
      try {
        final fileExt = file.path.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = 'salons/$salonId/$timestamp.$fileExt';
        final bytes = await file.readAsBytes();

        await supabase.storage
            .from('salon-images')
            .uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl = supabase.storage.from('salon-images').getPublicUrl(filePath);

        await supabase.from('salon_images').insert({
          'salon_id': salonId,
          'image_url': publicUrl,
        });
      } catch (e) {
        print('Upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e')),
        );
      }
    }
    _selectedImages.clear();
    await _fetchUploadedImages();
  }

  Future<void> _deleteImage(String imageUrl, String id) async {
    final path = Uri.parse(imageUrl).pathSegments.skipWhile((p) => p != 'salon-images').skip(1).join('/');

    try {
      await supabase.storage.from('salon-images').remove([path]);
      await supabase.from('salon_images').delete().eq('id', id);
      _fetchUploadedImages();
    } catch (e) {
      print('Delete error: $e');
    }
  }

  Future<void> _submit() async {
    final salonId = Provider.of<UserProvider>(context, listen: false).salonId;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.from('salons').update({
        'description': descriptionController.text,
      }).eq('id', salonId as Object);

      if (_selectedImages.isNotEmpty) {
        await _uploadImages(salonId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon details updated successfully')),
      );
    } catch (e) {
      print('Supabase update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More Salon Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Upload Salon Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text("Pick Images"),
                onPressed: _pickImages,
              ),
              const SizedBox(height: 8),
              if (_selectedImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages
                      .map((file) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, height: 100, width: 100, fit: BoxFit.cover),
                  ))
                      .toList(),
                ),
              const SizedBox(height: 24),
              const Text("Salon Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField(descriptionController, 'Enter your salon description...'),
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              const Text("Uploaded Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _uploadedImages.isEmpty
                  ? const Text('No images uploaded yet.')
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _uploadedImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final img = _uploadedImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          img['image_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _deleteImage(img['image_url'], img['id']),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Save Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
