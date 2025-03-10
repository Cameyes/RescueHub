import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_delivery_app/pages/admin/admin_screen.dart';
import 'package:food_delivery_app/pages/login_page.dart';
import 'package:food_delivery_app/service/google_vision_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf_render/pdf_render.dart';

class AdminVerificationScreen extends StatefulWidget {
  final String userId;
  final String enteredName;
  final String enteredDob;
  final String govtIdUrl;
  final String userEmail;

  const AdminVerificationScreen({
    super.key,
    required this.userId,
    required this.enteredName,
    required this.enteredDob,
    required this.govtIdUrl,
    required this.userEmail,
  });

  @override
  _AdminVerificationScreenState createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  bool _isVerifying = true;
  bool _isVerified = false;
  String _failureReason = '';

  @override
  void initState() {
    super.initState();
    _verifyDetails();
  }

  Future<String> _downloadAndProcessPDF(String pdfUrl) async {
    File? tempPdfFile;
    File? tempImageFile;
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) throw Exception("Failed to download PDF.");

      final tempDir = await getTemporaryDirectory();
      final tempPdfPath = '${tempDir.path}/temp.pdf';
      final tempImagePath = '${tempDir.path}/temp.png';

      tempPdfFile = File(tempPdfPath);
      await tempPdfFile.writeAsBytes(response.bodyBytes);

      final doc = await PdfDocument.openFile(tempPdfPath);
      final page = await doc.getPage(1);
      final pageImage = await page.render(width: page.width.toInt(), height: page.height.toInt());
      final pngBytes = await pageImage.createImageDetached();
      final pngData = await pngBytes.toByteData(format: ImageByteFormat.png);

      tempImageFile = File(tempImagePath);
      await tempImageFile.writeAsBytes(
        pngData!.buffer.asUint8List(pngData.offsetInBytes, pngData.lengthInBytes),
      );

      return tempImagePath;
    } catch (e) {
      throw Exception("Failed to process PDF: $e");
    } finally {
      if (tempPdfFile != null && await tempPdfFile.exists()) {
        await tempPdfFile.delete();
      }
    }
  }

  Future<String> _performOCR(String imagePath) async {
    try {
      return await GoogleVisionService.extractTextFromImage(File(imagePath));
    } catch (e) {
      return "";
    }
  }

  bool _checkNameMatch(String extractedText, String enteredName) {
    extractedText = extractedText.toLowerCase().trim();
    enteredName = enteredName.toLowerCase().trim();

    List<String> nameParts = enteredName.split(' ').where((part) => part.length > 1).toList();
    if (nameParts.isEmpty) return false;

    int matchedParts = nameParts.where((part) => extractedText.contains(part)).length;
    return matchedParts / nameParts.length >= 0.7;
  }

  String _normalizeDob(String dob) {
    return dob.replaceAll("/", "-");
  }

  bool _checkDobMatch(String extractedText, String enteredDob) {
    String normalizedEnteredDob = _normalizeDob(enteredDob);
    String normalizedExtractedDob = _normalizeDob(extractedText);
    return normalizedExtractedDob.contains(normalizedEnteredDob);
  }

  Future<void> _verifyDetails() async {
    try {
      await Firebase.initializeApp();
      setState(() => _isVerifying = true);

      final localImagePath = await _downloadAndProcessPDF(widget.govtIdUrl);
      final extractedText = await _performOCR(localImagePath);

      if (extractedText.isEmpty) throw Exception("Could not extract text from document.");

      bool nameMatches = _checkNameMatch(extractedText, widget.enteredName);
      bool dobMatches = _checkDobMatch(extractedText, widget.enteredDob);

      setState(() {
        _isVerified = nameMatches && dobMatches;
        _failureReason = _isVerified
            ? ''
            : "Verification failed. Please ensure your name and DOB match exactly as on your ID.";
      });
    } catch (e) {
      setState(() {
        _isVerified = false;
        _failureReason = "Error processing document: ${e.toString()}";
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _deleteAdminDetails() async {
    try {
      await FirebaseFirestore.instance.collection('adminDetails').doc(widget.userId).delete();
    } catch (e) {
      print("Error deleting admin details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verifying Details")),
      body: Center(
        child: _isVerifying
            ? const CircularProgressIndicator()
            : _isVerified
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 100),
                      const Text("Verification Successful!", style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Fetch the admin's location from Firestore
                          DocumentSnapshot adminDoc = await FirebaseFirestore.instance
                              .collection('adminDetails')
                              .doc(widget.userId)
                              .get();

                          String adminLocation = adminDoc["location"] ?? "Unknown Location";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminScreen(userId: widget.userId, location: adminLocation),
                            ),
                          );
                        },
                        child: const Text("Proceed to Admin Panel"),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 100),
                      Text("Verification Failed!\n$_failureReason", textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _deleteAdminDetails();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => loginScreen()));
                        },
                        child: const Text("Return to Login"),
                      ),
                    ],
                  ),
      ),
    );
  }
}