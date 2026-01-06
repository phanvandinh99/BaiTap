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
  bool _isAdmin = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    _currentUserId = await ApiService.getCurrentUserId();
    _isAdmin = await ApiService.isAdmin();
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
        title: const Text(
          'Question',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
            ),
          ),
        ),
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

          // API returns nested object: {question: {...}, answers: [...], comments: [...]}
          final responseData = snapshot.data!;
          final question = responseData['question'] ?? responseData; // Support both nested and flat structure
          // Ensure proper type comparison (int to int)
          final questionUserId = question['userId'] is int 
              ? question['userId'] 
              : (question['userId'] is String 
                  ? int.tryParse(question['userId']) 
                  : null);
          _isQuestionOwner = _currentUserId != null && questionUserId == _currentUserId;

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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                          if (_isQuestionOwner || _isAdmin)
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
                            question['username'] ?? question['userName'] ?? 'Unknown',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(question['createdAt']),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${question['viewCount'] ?? question['views'] ?? 0} views',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
                          const Spacer(),
                          // Vote Buttons for Question
                          if (_currentUserId != null)
                            _VoteButtons(
                              apiService: _apiService,
                              targetType: 'QUESTION',
                              targetId: question['id'],
                              currentUserId: _currentUserId!,
                              onUpdate: _loadData,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Question Comments Section
                if (_currentUserId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _CommentsSection(
                      apiService: _apiService,
                      targetType: 'QUESTION',
                      targetId: widget.questionId,
                      currentUserId: _currentUserId,
                      onUpdate: _loadData,
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
                              // Ensure proper type comparison (int to int)
                              final answerUserId = answer['userId'] is int 
                                  ? answer['userId'] 
                                  : (answer['userId'] is String 
                                      ? int.tryParse(answer['userId']) 
                                      : null);
                              final isAnswerOwner = _currentUserId != null && answerUserId == _currentUserId;
                              final canAccept = _isQuestionOwner && !answer['isAccepted'];
                              final canEdit = isAnswerOwner;
                              final canDelete = isAnswerOwner || _isAdmin;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: answer['isAccepted'] == true ? 3 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: answer['isAccepted'] == true
                                      ? BorderSide(
                                          color: Colors.green.shade300,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                color: answer['isAccepted'] == true 
                                    ? Colors.green.shade50 
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
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
                                      
                                      // Vote Buttons for Answer
                                      if (_currentUserId != null) ...[
                                        const SizedBox(height: 8),
                                        _VoteButtons(
                                          apiService: _apiService,
                                          targetType: 'ANSWER',
                                          targetId: answer['id'],
                                          currentUserId: _currentUserId!,
                                          onUpdate: _loadData,
                                        ),
                                      ],
                                      
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
                                      
                                      // Answer Comments Section
                                      if (_currentUserId != null) ...[
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        _CommentsSection(
                                          apiService: _apiService,
                                          targetType: 'ANSWER',
                                          targetId: answer['id'],
                                          currentUserId: _currentUserId,
                                          onUpdate: _loadData,
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

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Unknown';
    if (dateValue is String) {
      try {
        // Try to parse and format the date string
        final date = DateTime.parse(dateValue);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateValue; // Return as-is if parsing fails
      }
    }
    return 'Unknown';
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

// Comments Section Widget
class _CommentsSection extends StatefulWidget {
  final ApiService apiService;
  final String targetType; // 'QUESTION' or 'ANSWER'
  final int targetId;
  final int? currentUserId;
  final VoidCallback onUpdate;

  const _CommentsSection({
    required this.apiService,
    required this.targetType,
    required this.targetId,
    required this.currentUserId,
    required this.onUpdate,
  });

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  late Future<List<dynamic>> _commentsFuture;
  bool _isExpanded = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    _isAdmin = await ApiService.isAdmin();
    if (mounted) setState(() {});
  }

  void _loadComments() {
    setState(() {
      _commentsFuture = widget.apiService.getComments(
        widget.targetType,
        widget.targetId,
      );
    });
  }

  Future<void> _createComment() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CommentFormDialog(
        targetType: widget.targetType,
        targetId: widget.targetId,
      ),
    );

    if (result != null && result['success'] == true) {
      _loadComments();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added')),
        );
      }
    }
  }

  Future<void> _editComment(Map<String, dynamic> comment) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CommentFormDialog(
        targetType: widget.targetType,
        targetId: widget.targetId,
        commentId: comment['id'],
        initialContent: comment['content'],
      ),
    );

    if (result != null && result['success'] == true) {
      _loadComments();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
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
      await widget.apiService.deleteComment(commentId);
      if (mounted) {
        _loadComments();
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments Header
        InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Row(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              FutureBuilder<List<dynamic>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Text(
                    '$count ${count == 1 ? 'comment' : 'comments'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              const Spacer(),
              if (widget.currentUserId != null)
                TextButton.icon(
                  onPressed: _createComment,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),

        // Comments List
        if (_isExpanded)
          FutureBuilder<List<dynamic>>(
            future: _commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error loading comments: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                );
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              }

              return Column(
                children: comments.map((comment) {
                  // Ensure proper type comparison (int to int)
                  final commentUserId = comment['userId'] is int 
                      ? comment['userId'] 
                      : (comment['userId'] is String 
                          ? int.tryParse(comment['userId']) 
                          : null);
                  final isCommentOwner = widget.currentUserId != null && commentUserId == widget.currentUserId;
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comment Content
                        Text(
                          comment['content'] ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        // Comment Footer
                        Row(
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              comment['username'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            // Edit/Delete Buttons
                            if (isCommentOwner || _isAdmin) ...[
                              if (isCommentOwner)
                                TextButton(
                                  onPressed: () => _editComment(comment),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11, color: Colors.blue),
                                  ),
                                ),
                              if (isCommentOwner) const SizedBox(width: 4),
                              TextButton(
                                onPressed: () => _deleteComment(comment['id']),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

// Comment Form Dialog
class CommentFormDialog extends StatefulWidget {
  final String targetType;
  final int targetId;
  final int? commentId; // null for create, non-null for edit
  final String? initialContent;

  const CommentFormDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    this.commentId,
    this.initialContent,
  });

  @override
  State<CommentFormDialog> createState() => CommentFormDialogState();
}

class CommentFormDialogState extends State<CommentFormDialog> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditMode => widget.commentId != null;

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

  Future<void> _saveComment() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Comment cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isEditMode) {
        await ApiService().updateComment(
          widget.commentId!,
          _contentController.text.trim(),
        );
      } else {
        await ApiService().createComment(
          widget.targetType,
          widget.targetId,
          _contentController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop({'success': true});
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
      title: Text(isEditMode ? 'Edit Comment' : 'Add Comment'),
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
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
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
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Your Comment',
                hintText: 'Write a comment...',
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
          onPressed: _isLoading ? null : _saveComment,
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

// Vote Buttons Widget
class _VoteButtons extends StatefulWidget {
  final ApiService apiService;
  final String targetType; // 'QUESTION' or 'ANSWER'
  final int targetId;
  final int currentUserId;
  final VoidCallback onUpdate;

  const _VoteButtons({
    required this.apiService,
    required this.targetType,
    required this.targetId,
    required this.currentUserId,
    required this.onUpdate,
  });

  @override
  State<_VoteButtons> createState() => _VoteButtonsState();
}

class _VoteButtonsState extends State<_VoteButtons> {
  late Future<Map<String, dynamic>> _voteInfoFuture;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _loadVoteInfo();
  }

  void _loadVoteInfo() {
    setState(() {
      _voteInfoFuture = widget.apiService.getVoteInfo(
        widget.targetType,
        widget.targetId,
      );
    });
  }

  Future<void> _handleVote(String voteType) async {
    if (_isVoting) return;

    setState(() => _isVoting = true);

    try {
      // Get current vote info
      final currentInfo = await widget.apiService.getVoteInfo(
        widget.targetType,
        widget.targetId,
      );
      final myVote = currentInfo['myVote'] as String?;

      // If already voted with same type, remove vote
      if (myVote == voteType) {
        await widget.apiService.removeVote(
          widget.targetType,
          widget.targetId,
        );
      } else {
        // Otherwise, vote (will toggle if different type)
        await widget.apiService.vote(
          widget.targetType,
          widget.targetId,
          voteType,
        );
      }

      if (mounted) {
        _loadVoteInfo();
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _voteInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 80,
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final voteInfo = snapshot.data ?? {};
        final voteCount = voteInfo['voteCount'] ?? 0;
        final myVote = voteInfo['myVote'] as String?;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upvote Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isVoting ? null : () => _handleVote('UPVOTE'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: myVote == 'UPVOTE'
                          ? Colors.orange.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 22,
                      color: myVote == 'UPVOTE'
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              // Vote Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$voteCount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              // Downvote Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isVoting ? null : () => _handleVote('DOWNVOTE'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: myVote == 'DOWNVOTE'
                          ? Colors.blue.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 22,
                      color: myVote == 'DOWNVOTE'
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
