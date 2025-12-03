import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

Future<void> openReceiptScanner() async {
  if (kIsWeb) {
    await customDialog(title: "Attach File", child: ReceiptFilePickerDialog());
  } else {
    Get.to(() => const ReceiptScanningOutputScreen());
  }
}

class ReceiptScanningOutputScreen extends StatefulWidget {
  const ReceiptScanningOutputScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReceiptScanningOutputScreenState createState() =>
      _ReceiptScanningOutputScreenState();
}

class _ReceiptScanningOutputScreenState
    extends State<ReceiptScanningOutputScreen> {
  String merchant = "PHOSPHOR";
  String date = "April 21, 2024";
  double amount = 29.99;
  XFile? _capturedImage;
  bool _isLoading = false;

  Future<void> _captureImage() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      final image = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(camera: firstCamera),
        ),
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isLoading = true;
        });

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      showSnackBar("Error accessing camera: $e", isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text("Receipt Scanner")),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  AppText(
                    "Processing receipt...",
                    color: colorScheme.onSurface,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _capturedImage != null
                        ? Image.file(
                            File(_capturedImage!.path),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 50,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppText(
                                  "No receipt captured",
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _row(context, "Merchant:", merchant),
                        const SizedBox(height: 8),
                        _row(context, "Date:", date),
                        const SizedBox(height: 8),
                        _row(context, "Amount:", "\$$amount", isGreen: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: _captureImage,
                    child: const AppText(
                      "Retake Photo",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'merchant': merchant,
                        'date': date,
                        'amount': amount,
                        'imagePath': _capturedImage?.path,
                      });
                    },
                    child: const AppText(
                      "Attach to Transaction",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool isGreen = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          fontSize: 12,
        ),
        AppText(
          value,
          color: isGreen ? Colors.green : colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}

// ====================
// Camera Screen
// ====================

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text("Capture Receipt")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            Navigator.pop(context, image);
          } catch (_) {}
        },
        child: Icon(Icons.camera_alt, color: colorScheme.onPrimary),
      ),
    );
  }
}

// ====================
// File Picker Dialog
// ====================

class ReceiptFilePickerDialog extends StatefulWidget {
  const ReceiptFilePickerDialog({super.key});

  @override
  State<ReceiptFilePickerDialog> createState() =>
      _ReceiptFilePickerDialogState();
}

class _ReceiptFilePickerDialogState extends State<ReceiptFilePickerDialog> {
  String merchant = "PHOSPHOR";
  String date = "April 21, 2024";
  double amount = 29.99;
  String? _filePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _filePath = result.files.single.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Upload Receipt",
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 16),

              _filePath == null
                  ? InkWell(
                      onTap: _pickFile,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 48,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                "Select receipt image",
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_filePath!), height: 180),
                    ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _row(context, "Merchant:", merchant),
                    _row(context, "Date:", date),
                    _row(context, "Amount:", "\$$amount", isGreen: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppText("Cancel", fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: _filePath == null
                        ? null
                        : () => Navigator.pop(context, {
                            'merchant': merchant,
                            'date': date,
                            'amount': amount,
                            'imagePath': _filePath,
                          }),
                    child: const AppText(
                      "Attach",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool isGreen = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, fontSize: 14, fontWeight: FontWeight.bold),
          AppText(
            value,
            fontSize: 14,
            color: isGreen ? Colors.green : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
