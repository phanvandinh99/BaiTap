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
  bool _isQuestionOwner = false;
  int? _currentUserId;
  Map<String, dynamic>? _questionData;

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
    setState(() {
      _questionFuture = _apiService.getQuestion(widget.questionId);
      _answersFuture = _apiService.getAnswers(widget.questionId);
    });
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
          _questionData = question;
          _isQuestionOwner = _currentUserId == question['userId'];

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
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
                          if (_isQuestionOwner)
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
                              final isAnswerOwner = _currentUserId == answer['userId'];
                              final canAccept = _isQuestionOwner && !answer['isAccepted'];
                              final canEdit = isAnswerOwner;
                              final canDelete = isAnswerOwner; // Admin check can be added later
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: answer['isAccepted'] == true 
                                    ? Colors.green.shade50 
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Answer Content
                                      Text(
                                        answer['content'] ?? 'No content',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Answer Footer
                                      Row(
                                        children: [
                                          // Author Info
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  answer['username'] ?? answer['userName'] ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Vote Count
                                                Icon(Icons.thumb_up, size: 14, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${answer['voteCount'] ?? 0}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Accepted Badge
                                          if (answer['isAccepted'] == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                border: Border.all(color: Colors.green),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 14,
                                                    color: Colors.green.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Accepted',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      
                                      // Action Buttons
                                      if (canAccept || canEdit || canDelete) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Accept Button (only question owner)
                                            if (canAccept)
                                              TextButton.icon(
                                                onPressed: () => _acceptAnswer(answer['id']),
                                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                                label: const Text('Accept'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.green,
                                                ),
                                              ),
                                            // Edit Button (only answer owner)
                                            if (canEdit)
                                              TextButton.icon(
                                                onPressed: () => _editAnswer(answer),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: const Text('Edit'),
                                              ),
                                            // Delete Button (only answer owner)
                                            if (canDelete)
                                              TextButton.icon(
                                                onPressed: () => _deleteAnswer(answer['id']),
                                                icon: const Icon(Icons.delete, size: 16),
                                                label: const Text('Delete'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
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
          ),
        );
        },
      ),
      floatingActionButton: _currentUserId != null
          ? FloatingActionButton(
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
      )
      : null,
    );
  }

  Future<void> _acceptAnswer(int answerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Answer'),
        content: const Text('Mark this answer as accepted?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.acceptAnswer(answerId);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer accepted')),
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

  Future<void> _editAnswer(Map<String, dynamic> answer) async {
    showDialog(
      context: context,
      builder: (_) => AnswerFormDialog(
        questionId: widget.questionId,
        answerId: answer['id'],
        initialContent: answer['content'],
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteAnswer(int answerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Answer'),
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
      await _apiService.deleteAnswer(answerId);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer deleted')),
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
  final int? answerId; // null for create, non-null for edit
  final String? initialContent;
  final VoidCallback onSave;

  const AnswerFormDialog({
    super.key,
    required this.questionId,
    this.answerId,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<AnswerFormDialog> createState() => AnswerFormDialogState();
}

class AnswerFormDialogState extends State<AnswerFormDialog> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditMode => widget.answerId != null;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveAnswer() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Answer cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isEditMode) {
        // Update existing answer
        await ApiService().updateAnswer(
          widget.answerId!,
          _contentController.text.trim(),
        );
      } else {
        // Create new answer
        await ApiService().createAnswer(
          widget.questionId,
          _contentController.text.trim(),
        );
      }

      if (mounted) {
        widget.onSave();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode 
                ? 'Answer updated successfully' 
                : 'Answer posted successfully'),
          ),
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
      title: Text(isEditMode ? 'Edit Answer' : 'Post Your Answer'),
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
          onPressed: _isLoading ? null : _saveAnswer,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditMode ? 'Update' : 'Post'),
        ),
      ],
    );
  }
}
