import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EssayQuestion {
  int? id;
  String question;
  String? kodeQuestion; // Foreign key ke tabel kelas
  DateTime createdAt;

  EssayQuestion({
    this.id,
    required this.question,
    this.kodeQuestion,
    required this.createdAt,
  });

  // Convert dari JSON (dari Supabase)
  factory EssayQuestion.fromJson(Map<String, dynamic> json) {
    return EssayQuestion(
      id: json['id'],
      question: json['question'] ?? '',
      kodeQuestion: json['kode_kuis'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert ke JSON (untuk Supabase)
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'kode_kuis': kodeQuestion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class KelasOption {
  String kodeQuestion;
  String? mk; // nama mata kuliah atau deskripsi

  KelasOption({
    required this.kodeQuestion,
    this.mk,
  });

  factory KelasOption.fromJson(Map<String, dynamic> json) {
    return KelasOption(
      kodeQuestion: json['kode_kuis'] ?? '',
      mk: json['mk'],
    );
  }
}

class EssayQuestionApp extends StatefulWidget {
  @override
  _EssayQuestionAppState createState() => _EssayQuestionAppState();
}

class _EssayQuestionAppState extends State<EssayQuestionApp>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late TabController _tabController;
  List<EssayQuestion> questions = [];
  List<KelasOption> kelasOptions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuestions();
    _loadKelasOptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load data dari tabel essay_question
  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('essay_question')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        questions = response
            .map<EssayQuestion>((json) => EssayQuestion.fromJson(json))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $error')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load data kelas untuk dropdown
  Future<void> _loadKelasOptions() async {
    try {
      final response = await supabase.from('kelas').select('kode_kuis, mk');

      setState(() {
        kelasOptions = response
            .map<KelasOption>((json) => KelasOption.fromJson(json))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading kelas options: $error')),
        );
      }
    }
  }

  // Create - Tambah ke tabel essay_question
  Future<void> _addQuestion(EssayQuestion question) async {
    try {
      final response = await supabase
          .from('essay_question')
          .insert(question.toJson())
          .select()
          .single();

      final newQuestion = EssayQuestion.fromJson(response);

      setState(() {
        questions.insert(0, newQuestion);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soal berhasil ditambahkan!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding question: $error')),
        );
      }
    }
  }

  // Update - Update di tabel essay_question
  Future<void> _updateQuestion(int index, EssayQuestion updatedQuestion) async {
    try {
      await supabase.from('essay_question').update({
        'question': updatedQuestion.question,
        'kode_kuis': updatedQuestion.kodeQuestion,
      }).eq('id', updatedQuestion.id!);

      setState(() {
        questions[index] = updatedQuestion;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soal berhasil diupdate!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating question: $error')),
        );
      }
    }
  }

  // Delete - Hapus dari tabel essay_question
  Future<void> _deleteQuestion(int index) async {
    final question = questions[index];

    try {
      await supabase.from('essay_question').delete().eq('id', question.id!);

      setState(() {
        questions.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soal berhasil dihapus!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting question: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soal Essay CRUD'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadQuestions();
              _loadKelasOptions();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.add), text: 'Tambah'),
            Tab(icon: Icon(Icons.list), text: 'Daftar'),
            Tab(icon: Icon(Icons.search), text: 'Cari'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                AddQuestionTab(
                  onAddQuestion: _addQuestion,
                  kelasOptions: kelasOptions,
                ),
                QuestionListTab(
                  questions: questions,
                  kelasOptions: kelasOptions,
                  onUpdateQuestion: _updateQuestion,
                  onDeleteQuestion: _deleteQuestion,
                ),
                SearchQuestionTab(questions: questions),
              ],
            ),
    );
  }
}

// Tab untuk menambah soal
class AddQuestionTab extends StatefulWidget {
  final Function(EssayQuestion) onAddQuestion;
  final List<KelasOption> kelasOptions;

  AddQuestionTab({
    required this.onAddQuestion,
    required this.kelasOptions,
  });

  @override
  _AddQuestionTabState createState() => _AddQuestionTabState();
}

class _AddQuestionTabState extends State<AddQuestionTab> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  String? _selectedKodeQuestion;
  bool _isSubmitting = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final newQuestion = EssayQuestion(
        question: _questionController.text.trim(),
        kodeQuestion: _selectedKodeQuestion,
        createdAt: DateTime.now(),
      );

      await widget.onAddQuestion(newQuestion);

      // Clear form
      _questionController.clear();
      setState(() {
        _selectedKodeQuestion = null;
      });

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Dropdown untuk memilih kelas
            DropdownButtonFormField<String>(
              value: _selectedKodeQuestion,
              decoration: InputDecoration(
                labelText: 'Pilih Kelas',
                border: OutlineInputBorder(),
                hintText: 'Pilih kode kelas...',
              ),
              items: widget.kelasOptions.map((kelas) {
                return DropdownMenuItem<String>(
                  value: kelas.kodeQuestion,
                  child: Text(
                      '${kelas.kodeQuestion}${kelas.mk != null ? ' - ${kelas.mk}' : ''}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedKodeQuestion = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mohon pilih kelas';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // Text field untuk pertanyaan
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Pertanyaan',
                border: OutlineInputBorder(),
                hintText: 'Masukkan pertanyaan essay...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mohon masukkan pertanyaan';
                }
                if (value.trim().length < 10) {
                  return 'Pertanyaan minimal 10 karakter';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Menambahkan...'),
                      ],
                    )
                  : Text('Tambah Soal'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}

// Tab untuk menampilkan daftar soal
class QuestionListTab extends StatelessWidget {
  final List<EssayQuestion> questions;
  final List<KelasOption> kelasOptions;
  final Function(int, EssayQuestion) onUpdateQuestion;
  final Function(int) onDeleteQuestion;

  QuestionListTab({
    required this.questions,
    required this.kelasOptions,
    required this.onUpdateQuestion,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada soal yang ditambahkan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Gunakan tab "Tambah" untuk menambah soal baru',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final kelasInfo = kelasOptions.firstWhere(
          (kelas) => kelas.kodeQuestion == question.kodeQuestion,
          orElse: () =>
              KelasOption(kodeQuestion: question.kodeQuestion ?? 'Unknown'),
        );

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              question.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelas: ${question.kodeQuestion ?? 'Tidak ada'}${kelasInfo.mk != null ? ' - ${kelasInfo.mk}' : ''}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Dibuat: ${_formatDate(question.createdAt)}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Lihat Detail'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showQuestionDetail(context, question, kelasInfo);
                    break;
                  case 'edit':
                    _showEditDialog(context, index, question);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, index, question.question);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showQuestionDetail(
      BuildContext context, EssayQuestion question, KelasOption kelasInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Soal'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${question.id}'),
              SizedBox(height: 10),
              Text('Kode Kelas:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '${question.kodeQuestion ?? 'Tidak ada'}${kelasInfo.mk != null ? ' - ${kelasInfo.mk}' : ''}'),
              SizedBox(height: 10),
              Text('Pertanyaan:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(question.question),
              SizedBox(height: 10),
              Text('Dibuat:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatDate(question.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, int index, EssayQuestion question) {
    final questionController = TextEditingController(text: question.question);
    String? selectedKodeQuestion = question.kodeQuestion;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Soal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedKodeQuestion,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: kelasOptions.map((kelas) {
                    return DropdownMenuItem<String>(
                      value: kelas.kodeQuestion,
                      child: Text(
                          '${kelas.kodeQuestion}${kelas.mk != null ? ' - ${kelas.mk}' : ''}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedKodeQuestion = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Pertanyaan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.trim().isNotEmpty &&
                    selectedKodeQuestion != null) {
                  final updatedQuestion = EssayQuestion(
                    id: question.id,
                    question: questionController.text.trim(),
                    kodeQuestion: selectedKodeQuestion,
                    createdAt: question.createdAt,
                  );
                  onUpdateQuestion(index, updatedQuestion);
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index, String questionText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Soal'),
        content: Text(
          'Apakah Anda yakin ingin menghapus soal ini?\n\n"${questionText.length > 50 ? questionText.substring(0, 50) + '...' : questionText}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              onDeleteQuestion(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// Tab untuk mencari soal
class SearchQuestionTab extends StatefulWidget {
  final List<EssayQuestion> questions;

  SearchQuestionTab({required this.questions});

  @override
  _SearchQuestionTabState createState() => _SearchQuestionTabState();
}

class _SearchQuestionTabState extends State<SearchQuestionTab> {
  final _searchController = TextEditingController();
  List<EssayQuestion> _filteredQuestions = [];

  @override
  void initState() {
    super.initState();
    _filteredQuestions = widget.questions;
  }

  @override
  void didUpdateWidget(SearchQuestionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filterQuestions(_searchController.text);
  }

  void _filterQuestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = widget.questions;
      } else {
        _filteredQuestions = widget.questions
            .where((question) =>
                question.question.toLowerCase().contains(query.toLowerCase()) ||
                (question.kodeQuestion != null &&
                    question.kodeQuestion!
                        .toLowerCase()
                        .contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari soal atau kode kelas...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterQuestions('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterQuestions,
          ),
        ),
        Expanded(
          child: _filteredQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchController.text.isEmpty
                            ? Icons.search
                            : Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Ketik untuk mencari soal'
                            : 'Tidak ada soal yang ditemukan',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final question = _filteredQuestions[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(
                          question.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelas: ${question.kodeQuestion ?? 'Tidak ada'}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Dibuat: ${question.createdAt.day}/${question.createdAt.month}/${question.createdAt.year}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () => _showQuestionDetail(context, question),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showQuestionDetail(BuildContext context, EssayQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Soal'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${question.id}'),
              SizedBox(height: 10),
              Text('Kode Kelas:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${question.kodeQuestion ?? 'Tidak ada'}'),
              SizedBox(height: 10),
              Text('Pertanyaan:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(question.question),
              SizedBox(height: 10),
              Text('Dibuat:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${question.createdAt.day}/${question.createdAt.month}/${question.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
