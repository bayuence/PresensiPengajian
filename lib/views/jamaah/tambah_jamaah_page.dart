import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/jamaah.dart';
import '../../controllers/jamaah_controller.dart';
import '../../config/api.dart';

class TambahJamaahPage extends StatefulWidget {
  final Jamaah? jamaah;

  const TambahJamaahPage({super.key, this.jamaah});

  @override
  State<TambahJamaahPage> createState() => _TambahJamaahPageState();
}

class _TambahJamaahPageState extends State<TambahJamaahPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jamaahController = JamaahController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.jamaah != null) {
      _namaController.text = widget.jamaah!.nama;
      _existingPhotoUrl = widget.jamaah!.foto;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null && mounted) {
        final File imageFile = File(pickedFile.path);
        if (await imageFile.exists()) {
          setState(() {
            _imageFile = imageFile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengambil foto: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.jamaah == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto harus diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      bool success;
      
      // Convert File to bytes if image is selected
      Uint8List? fotoBytes;
      String? fotoName;
      
      if (_imageFile != null) {
        fotoBytes = await _imageFile!.readAsBytes();
        fotoName = _imageFile!.path.split('/').last;
        // Handle Windows path separator
        if (fotoName.contains('\\')) {
          fotoName = fotoName.split('\\').last;
        }
      }

      if (widget.jamaah == null) {
        success = await _jamaahController.addJamaah(
          nama: _namaController.text, 
          fotoBytes: fotoBytes,
          fotoName: fotoName,
        );
      } else {
        success = await _jamaahController.updateJamaah(
          id: widget.jamaah!.id, 
          nama: _namaController.text, 
          fotoBytes: fotoBytes,
          fotoName: fotoName,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.jamaah == null ? 'Jamaah berhasil ditambahkan' : 'Jamaah berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan data'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jamaah == null ? 'Tambah Jamaah' : 'Edit Jamaah'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                            ? NetworkImage(Api.uploadUrl(_existingPhotoUrl!))
                            : null) as ImageProvider?,
                    child: (_imageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF2E7D32),
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _showImageSourceDialog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.jamaah == null)
              const Text(
                '* Foto wajib diisi',
                style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Jamaah',
                hintText: 'Masukkan nama jamaah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      widget.jamaah == null ? 'Tambah Jamaah' : 'Update Jamaah',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 2, // Jamaah tab
          onTap: (index) {
            Navigator.pop(context);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Jamaah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
