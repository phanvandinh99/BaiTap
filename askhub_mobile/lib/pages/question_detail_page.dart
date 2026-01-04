import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuestionDetailPage extends StatefulWidget {
  final int questionId;

  const QuestionDetailPage({super.key, required this.questionId});

  @override
  State<QuestionDetailPage> createState() => QuestionDetailPageState();
}

class QuestionDetailPageState extends State<QuestionDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _questionFuture;
  late Future<List<dynamic>> _answersFuture;
  bool _isOwner = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    _currentUserId = await ApiService.getCurrentUserId();
    setState(() {});
  }

  void _loadData() {
    _questionFuture = _apiService.getQuestion(widget.questionId);
    _answersFuture = _apiService.getAnswers(widget.questionId);
  }

  Future<void> _deleteQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteQuestion(questionId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _questionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loadData());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          final question = snapshot.data!;
          _isOwner = _currentUserId == question['userId'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              question['title'] ?? 'No title',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isOwner)
                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteQuestion(question['id']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question['content'] ?? 'No content',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            question['userName'] ?? 'Unknown',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            question['createdAt'] ?? 'Unknown',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${question['views'] ?? 0} views',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(question['status']).withValues(alpha: 0.2),
                          border: Border.all(
                            color: _getStatusColor(question['status']),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (question['status'] ?? 'open').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(question['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Answers Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Answers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<dynamic>>(
                        future: _answersFuture,
                        builder: (context, answerSnapshot) {
                          if (answerSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final answers = answerSnapshot.data ?? [];
                          if (answers.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No answers yet',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: answers.length,
                            itemBuilder: (context, index) {
                              final answer = answers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        answer['content'] ?? 'No content',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            answer['userName'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (answer['isAccepted'] == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                border: Border.all(color: Colors.green),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'Accepted',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open answer form
          showDialog(
            context: context,
            builder: (_) => AnswerFormDialog(
              questionId: widget.questionId,
              onSave: () {
                setState(() => _loadData());
              },
            ),
          );
        },
        tooltip: 'Post Answer',
        child: const Icon(Icons.reply),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'answered':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class AnswerFormDialog extends StatefulWidget {
  final int questionId;
  final VoidCallback onSave;

  const AnswerFormDialog({
    super.key,
    required this.questionId,
    required this.onSave,
  });

  @override
  State<AnswerFormDialog> createState() => AnswerFormDialogState();
}

class AnswerFormDialogState extends State<AnswerFormDialog> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _postAnswer() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Answer cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().createAnswer(
        widget.questionId,
        _contentController.text.trim(),
      );

      if (mounted) {
        widget.onSave();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post Your Answer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              enabled: !_isLoading,
              minLines: 6,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Your Answer',
                hintText: 'Share your knowledge...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _postAnswer,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }
}
