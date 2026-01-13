import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/jamaah.dart';
import '../controllers/jamaah_controller.dart';

class TambahJamaahPage extends StatefulWidget {
  final Jamaah? jamaah; // null = mode tambah, ada isi = mode edit

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
      // Mode edit
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error mengambil foto: $e')));
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi foto wajib diisi untuk mode tambah
    if (widget.jamaah == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      if (widget.jamaah == null) {
        // Mode tambah
        success = await _jamaahController.addJamaah(
          nama: _namaController.text,
          foto: _imageFile,
        );
      } else {
        // Mode edit
        success = await _jamaahController.updateJamaah(
          id: widget.jamaah!.id,
          nama: _namaController.text,
          foto: _imageFile,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.jamaah == null
                    ? 'Jamaah berhasil ditambahkan'
                    : 'Jamaah berhasil diupdate',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true = refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jamaah == null ? 'Tambah Jamaah' : 'Edit Jamaah'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview Foto
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_existingPhotoUrl != null &&
                                      _existingPhotoUrl!.isNotEmpty
                                  ? NetworkImage(
                                      'http://10.10.10.47/presensi_pengajian/uploads/$_existingPhotoUrl',
                                    )
                                  : null)
                              as ImageProvider?,
                    child:
                        (_imageFile == null &&
                            (_existingPhotoUrl == null ||
                                _existingPhotoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: _showImageSourceDialog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Peringatan foto wajib
            if (widget.jamaah == null)
              const Text(
                '* Foto wajib diisi',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),

            // Input Nama
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

            // Tombol Simpan
            ElevatedButton(
              onPressed: _isLoading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.jamaah == null ? 'Tambah Jamaah' : 'Update Jamaah',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
