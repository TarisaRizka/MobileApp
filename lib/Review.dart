import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
// Optional: import for QR code scanning package
// import 'package:mobile_scanner/mobile_scanner.dart';

class EssayAnswerTab extends StatefulWidget {
  const EssayAnswerTab({Key? key}) : super(key: key);

  @override
  _EssayAnswerTabState createState() => _EssayAnswerTabState();
}

class _EssayAnswerTabState extends State<EssayAnswerTab> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _kodeKuisController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();

  List<Map<String, dynamic>> _allAnswers = [];
  List<Map<String, dynamic>> _filteredAnswers = [];

  bool _loading = false;
  String? _error;
  String? _currentKodeKuis;

  // Ratings stored as {id: rating} (1-100)
  Map<int, int> _ratings = {};
  Map<int, bool> _submittingRatings = {};
  Map<int, TextEditingController> _ratingControllers = {};

  @override
  void dispose() {
    _kodeKuisController.dispose();
    _filterController.dispose();
    // Dispose all rating controllers
    _ratingControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchAnswers() async {
    final kodeKuis = _kodeKuisController.text.trim();

    if (kodeKuis.isEmpty) {
      setState(() {
        _error = 'Please enter a Kode Kuis or scan QR code';
        _allAnswers = [];
        _filteredAnswers = [];
        _currentKodeKuis = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _allAnswers = [];
      _filteredAnswers = [];
      _ratings.clear();
      // Clear existing controllers
      _ratingControllers.values.forEach((controller) => controller.dispose());
      _ratingControllers.clear();
    });

    try {
      // Updated query to match your database structure
      final response = await supabase
          .from('essay_answer')
          .select('id, question, answer, kuis_kode')
          .eq('kuis_kode', kodeKuis)
          .order('id', ascending: true);

      final data = response as List<dynamic>;

      if (data.isEmpty) {
        setState(() {
          _error = 'No answers found for kode kuis: $kodeKuis';
          _loading = false;
          _currentKodeKuis = null;
        });
        return;
      }

      final answers = data.map((e) => Map<String, dynamic>.from(e)).toList();

      // Initialize rating controllers for each answer
      for (var answer in answers) {
        final id = answer['id'] as int;
        _ratingControllers[id] = TextEditingController();
      }

      // Load existing ratings if any
      await _loadExistingRatings(answers.map((e) => e['id'] as int).toList());

      setState(() {
        _allAnswers = answers;
        _filteredAnswers = answers;
        _loading = false;
        _currentKodeKuis = kodeKuis;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${answers.length} answers'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _loading = false;
        _currentKodeKuis = null;
      });
    }
  }

  Future<void> _loadExistingRatings(List<int> answerIds) async {
    try {
      // Load existing ratings from essay_ratings table
      final response = await supabase
          .from('essay_ratings')
          .select('answer_id, rating')
          .inFilter('answer_id', answerIds);

      final data = response as List<dynamic>;

      for (var rating in data) {
        final answerId = rating['answer_id'] as int;
        final ratingValue = rating['rating'] as int;
        setState(() {
          _ratings[answerId] = ratingValue;
        });
        if (_ratingControllers[answerId] != null) {
          _ratingControllers[answerId]!.text = ratingValue.toString();
        }
      }
    } catch (e) {
      // If table doesn't exist or error occurs, we'll just start fresh
      print('Error loading existing ratings: $e');
    }
  }

  void _filterQuestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAnswers = _allAnswers;
      });
      return;
    }

    query = query.toLowerCase();

    List<Map<String, dynamic>> filtered = _allAnswers.where((item) {
      final question = (item['question'] as String? ?? '').toLowerCase();
      final answer = (item['answer'] as String? ?? '').toLowerCase();
      return question.contains(query) || answer.contains(query);
    }).toList();

    setState(() {
      _filteredAnswers = filtered;
    });
  }

  Future<void> _saveRating(int answerId, int rating) async {
    if (rating < 1 || rating > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating must be between 1 and 100'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _submittingRatings[answerId] = true;
    });

    try {
      // Get the answer data
      final answerData =
          _allAnswers.firstWhere((answer) => answer['id'] == answerId);

      // Save to essay_ratings table with proper conflict resolution
      final response = await supabase.from('essay_ratings').upsert(
        {
          'answer_id': answerId,
          'kode_kuis': answerData['kuis_kode'],
          'question': answerData['question'],
          'answer': answerData['answer'],
          'rating': rating,
          'rated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update local state only after successful save
      setState(() {
        _ratings[answerId] = rating;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating saved: $rating/100'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rating: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Reset the controller text on error
      final controller = _ratingControllers[answerId];
      if (controller != null) {
        final currentRating = _ratings[answerId];
        controller.text = currentRating?.toString() ?? '';
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingRatings[answerId] = false;
        });
      }
    }
  }

  void _onScanQRPressed() async {
    // Implement QR scanner
    // For mobile_scanner package:
    /*
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(),
      ),
    );
    
    if (result != null) {
      _kodeKuisController.text = result;
      await _fetchAnswers();
    }
    */

    // Placeholder dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('QR Scanner'),
          ],
        ),
        content: Text('QR code scanning is not implemented yet.\n\n'
            'To implement:\n'
            '1. Add mobile_scanner package\n'
            '2. Request camera permissions\n'
            '3. Create scanner screen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _filterController.clear();
    setState(() {
      _filteredAnswers = _allAnswers;
    });
  }

  void _clearAll() {
    _kodeKuisController.clear();
    _filterController.clear();
    // Clear rating controllers
    _ratingControllers.values.forEach((controller) => controller.dispose());
    _ratingControllers.clear();
    setState(() {
      _allAnswers = [];
      _filteredAnswers = [];
      _ratings.clear();
      _submittingRatings.clear();
      _error = null;
      _currentKodeKuis = null;
    });
  }

  Widget _buildRatingInput(int id) {
    final currentRating = _ratings[id];
    final isSubmitting = _submittingRatings[id] ?? false;
    final controller = _ratingControllers[id];

    if (controller == null) {
      return Container();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate this answer (1-100):',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final int? value = int.tryParse(newValue.text);
                      if (value == null || value < 1 || value > 100) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: '1-100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixText: '/100',
                  ),
                  enabled: !isSubmitting,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final rating = int.tryParse(value);
                      if (rating != null && rating >= 1 && rating <= 100) {
                        _saveRating(id, rating);
                      }
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            final rating = int.tryParse(text);
                            if (rating != null &&
                                rating >= 1 &&
                                rating <= 100) {
                              _saveRating(id, rating);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please enter a valid rating (1-100)'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a rating'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Save'),
                ),
              ),
            ],
          ),
          if (currentRating != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(currentRating),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Current Rating: $currentRating/100',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 80) return Colors.green;
    if (rating >= 60) return Colors.orange;
    if (rating >= 40) return Colors.yellow[700]!;
    return Colors.red;
  }

  Widget _buildSearchHeader() {
    return Column(
      children: [
        // Kode Kuis Input Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kodeKuisController,
                decoration: InputDecoration(
                  labelText: 'Kode Kuis',
                  hintText: 'Enter quiz code or scan QR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.vpn_key),
                  suffixIcon: _kodeKuisController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _kodeKuisController.clear();
                            _clearAll();
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _fetchAnswers(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR Code',
              onPressed: _onScanQRPressed,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                padding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text('Search'),
              onPressed: _kodeKuisController.text.trim().isEmpty
                  ? null
                  : _fetchAnswers,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Filter Row (only show when we have data)
        if (_allAnswers.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    labelText: 'Filter Questions/Answers',
                    hintText: 'Search in questions and answers...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.filter_list),
                    suffixIcon: _filterController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: _clearFilters,
                          )
                        : null,
                  ),
                  onChanged: _filterQuestions,
                ),
              ),
              if (_filterController.text.isNotEmpty) ...[
                SizedBox(width: 8),
                Chip(
                  label:
                      Text('${_filteredAnswers.length}/${_allAnswers.length}'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> item, int index) {
    final id = item['id'] as int;
    final question = item['question'] as String? ?? '';
    final answer = item['answer'] as String? ?? '';

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with question number
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'ID: $id',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Question
            Text(
              'Question:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                question,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            SizedBox(height: 16),

            // Answer
            Text(
              'Answer:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            SizedBox(height: 16),

            // Rating section
            _buildRatingInput(id),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Essay Answers'),
        actions: [
          if (_currentKodeKuis != null) ...[
            Chip(
              label: Text(_currentKodeKuis!),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _currentKodeKuis != null ? _fetchAnswers : null,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchHeader(),
            SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading answers...'),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Retry'),
                                onPressed: _fetchAnswers,
                              ),
                            ],
                          ),
                        )
                      : _filteredAnswers.isEmpty && _currentKodeKuis == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.quiz_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Enter a Kode Kuis to view essay answers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'You can type the code or scan a QR code',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : _filteredAnswers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No answers match your filter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _clearFilters,
                                        child: Text('Clear Filter'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filteredAnswers.length,
                                  itemBuilder: (context, index) {
                                    return _buildAnswerCard(
                                        _filteredAnswers[index], index);
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }
}
