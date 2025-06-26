import 'package:finalproject_mobapp/Hasil.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Model untuk Essay Question
class EssayQuestion {
  final String kodeKuis;
  final String question;
  final int id;

  EssayQuestion({
    required this.kodeKuis,
    required this.question,
    required this.id,
  });

  factory EssayQuestion.fromJson(Map<String, dynamic> json) {
    return EssayQuestion(
      kodeKuis: json['kode_kuis'] ?? '',
      question: json['question'] ?? '',
      id: json['id'] ?? 0,
    );
  }
}

// Model untuk jawaban
class QuizAnswer {
  final String questionId;
  final String question; // Tambahkan field question
  final String answer;
  final List<File> images;

  QuizAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
    required this.images,
  });
}

// Main App
class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: QuizHomePage(),
    );
  }
}

// Home Page dengan Tab
class QuizHomePage extends StatefulWidget {
  @override
  _QuizHomePageState createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            Tab(icon: Icon(Icons.edit), text: 'Input Kode'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          QRScannerTab(),
          ManualInputTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Tab untuk QR Scanner
class QRScannerTab extends StatefulWidget {
  @override
  _QRScannerTabState createState() => _QRScannerTabState();
}

class _QRScannerTabState extends State<QRScannerTab> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedCode;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  if (isScanning) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        setState(() {
                          scannedCode = barcode.rawValue;
                          isScanning = false;
                        });
                        cameraController.stop();
                        break;
                      }
                    }
                  }
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scannedCode != null
                      ? 'Kode: $scannedCode'
                      : 'Arahkan kamera ke QR Code',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                if (scannedCode != null) ...[
                  ElevatedButton(
                    onPressed: () => _processQuizCode(scannedCode!),
                    child: Text('Mulai Kuis'),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _resetScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Scan Ulang'),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => cameraController.toggleTorch(),
                        icon: Icon(Icons.flash_on),
                        label: Text('Flash'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => cameraController.switchCamera(),
                        icon: Icon(Icons.camera_front),
                        label: Text('Flip'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _resetScanner() {
    setState(() {
      scannedCode = null;
      isScanning = true;
    });
    cameraController.start();
  }

  void _processQuizCode(String code) async {
    await _navigateToQuiz(code);
  }

  Future<void> _navigateToQuiz(String kodeKuis) async {
    try {
      final response = await Supabase.instance.client
          .from('essay_question')
          .select('*')
          .eq('kode_kuis', kodeKuis);

      if (response.isNotEmpty) {
        List<EssayQuestion> questions = response
            .map<EssayQuestion>((item) => EssayQuestion.fromJson(item))
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(
              kodeKuis: kodeKuis,
              questions: questions,
            ),
          ),
        );
      } else {
        _showErrorDialog('Kode kuis tidak ditemukan');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Tab untuk Input Manual
class ManualInputTab extends StatefulWidget {
  @override
  _ManualInputTabState createState() => _ManualInputTabState();
}

class _ManualInputTabState extends State<ManualInputTab> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 64,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Masukkan Kode Kuis',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Kode Kuis',
                      hintText: 'Masukkan kode kuis',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.code),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitCode,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Mulai Kuis',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EssayRatingScreen()),
                      );
                    },
                    child: Text('Review Jawaban'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitCode() async {
    String code = _codeController.text.trim();
    if (code.isEmpty) {
      _showErrorDialog('Silakan masukkan kode kuis');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('essay_question')
          .select('*')
          .eq('kode_kuis', code);

      if (response.isNotEmpty) {
        List<EssayQuestion> questions = response
            .map<EssayQuestion>((item) => EssayQuestion.fromJson(item))
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(
              kodeKuis: code,
              questions: questions,
            ),
          ),
        );
      } else {
        _showErrorDialog('Kode kuis tidak ditemukan');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Fixed QuizPage Widget - Replace the existing QuizPage class with this version
class QuizPage extends StatefulWidget {
  final String kodeKuis;
  final List<EssayQuestion> questions;

  QuizPage({
    required this.kodeKuis,
    required this.questions,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;
  Map<int, QuizAnswer> answers = {};
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Kuis')),
        body: Center(
          child: Text('Tidak ada soal untuk kuis ini'),
        ),
      );
    }

    EssayQuestion currentQuestion = widget.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Kuis ${widget.kodeKuis}'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${currentQuestionIndex + 1}/${widget.questions.length}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar - Fixed height
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / widget.questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),

            // Main content - Flexible to take remaining space
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Question Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soal ${currentQuestionIndex + 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              currentQuestion.question,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Answer Section
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jawaban Anda:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            
                            // Answer TextField with fixed height
                            Container(
                              height: 200, // Fixed height to prevent overflow
                              child: TextField(
                                controller: TextEditingController(
                                  text: answers[currentQuestion.id]?.answer ?? '',
                                ),
                                onChanged: (value) => _saveAnswer(
                                    currentQuestion.id, value, currentQuestion.question),
                                decoration: InputDecoration(
                                  hintText: 'Tuliskan jawaban Anda di sini...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Images Section
                            if (answers[currentQuestion.id]?.images.isNotEmpty == true) ...[
                              Text(
                                'Gambar yang ditambahkan:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: answers[currentQuestion.id]!.images.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.only(right: 8),
                                      width: 80,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              answers[currentQuestion.id]!.images[index],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(currentQuestion.id, index),
                                              child: Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                            ],

                            // Add Image Button
                            ElevatedButton.icon(
                              onPressed: () => _showImageSourceDialog(currentQuestion.id),
                              icon: Icon(Icons.add_photo_alternate, size: 18),
                              label: Text('Tambah Gambar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Extra space before buttons
                  ],
                ),
              ),
            ),

            // Navigation Buttons - Fixed at bottom
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Sebelumnya'),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (currentQuestionIndex < widget.questions.length - 1
                            ? _nextQuestion
                            : _submitQuiz),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSubmitting &&
                            currentQuestionIndex == widget.questions.length - 1
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            currentQuestionIndex < widget.questions.length - 1
                                ? 'Selanjutnya'
                                : 'Selesai',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAnswer(int questionId, String answer, String question) {
    setState(() {
      if (answers[questionId] == null) {
        answers[questionId] = QuizAnswer(
          questionId: questionId.toString(),
          question: question,
          answer: answer,
          images: [],
        );
      } else {
        answers[questionId] = QuizAnswer(
          questionId: questionId.toString(),
          question: question,
          answer: answer,
          images: answers[questionId]!.images,
        );
      }
    });
  }

  void _showImageSourceDialog(int questionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber Gambar'),
        content: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                leading: Icon(Icons.camera_alt),
                title: Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, questionId);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                leading: Icon(Icons.photo_library),
                title: Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, questionId);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _pickImage(ImageSource source, int questionId) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      String questionText =
          widget.questions.firstWhere((q) => q.id == questionId).question;

      setState(() {
        if (answers[questionId] == null) {
          answers[questionId] = QuizAnswer(
            questionId: questionId.toString(),
            question: questionText,
            answer: '',
            images: [File(image.path)],
          );
        } else {
          answers[questionId] = QuizAnswer(
            questionId: questionId.toString(),
            question: questionText,
            answer: answers[questionId]!.answer,
            images: [...answers[questionId]!.images, File(image.path)],
          );
        }
      });
    }
  }

  void _removeImage(int questionId, int imageIndex) {
    setState(() {
      if (answers[questionId] != null) {
        List<File> updatedImages = List.from(answers[questionId]!.images);
        updatedImages.removeAt(imageIndex);

        String questionText =
            widget.questions.firstWhere((q) => q.id == questionId).question;

        answers[questionId] = QuizAnswer(
          questionId: questionId.toString(),
          question: questionText,
          answer: answers[questionId]!.answer,
          images: updatedImages,
        );
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _submitQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selesaikan Kuis'),
        content: Text('Apakah Anda yakin ingin menyelesaikan kuis ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSubmission();
            },
            child: Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _processSubmission() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      for (var questionId in answers.keys) {
        QuizAnswer answer = answers[questionId]!;

        String finalAnswer = answer.answer;
        if (answer.images.isNotEmpty) {
          finalAnswer +=
              '\n\n[Gambar dilampirkan: ${answer.images.length} file]';
        }

        await Supabase.instance.client.from('essay_answer').insert({
          'kuis_kode': widget.kodeKuis,
          'question': answer.question,
          'answer': finalAnswer,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Gagal menyimpan jawaban: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Berhasil'),
          ],
        ),
        content: Text(
            'Kuis telah berhasil diselesaikan dan jawaban telah disimpan!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}