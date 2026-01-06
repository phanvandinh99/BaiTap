import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCommentsPage extends StatefulWidget {
  const AdminCommentsPage({super.key});

  @override
  State<AdminCommentsPage> createState() => AdminCommentsPageState();
}

class AdminCommentsPageState extends State<AdminCommentsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allComments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllComments();
  }

  Future<void> _loadAllComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all questions first, then get comments for each
      final questions = await _apiService.getQuestions();
      List<dynamic> allComments = [];
      
      // Get comments for questions
      for (var question in questions) {
        try {
          final comments = await _apiService.getComments('QUESTION', question['id']);
          for (var comment in comments) {
            comment['targetTitle'] = question['title'];
            comment['targetType'] = 'QUESTION';
            allComments.add(comment);
          }
        } catch (e) {
          // Skip if error
        }
      }

      // Get comments for answers
      for (var question in questions) {
        try {
          final answers = await _apiService.getAnswers(question['id']);
          for (var answer in answers) {
            try {
              final comments = await _apiService.getComments('ANSWER', answer['id']);
              for (var comment in comments) {
                comment['targetTitle'] = 'Answer to: ${question['title']}';
                comment['targetType'] = 'ANSWER';
                allComments.add(comment);
              }
            } catch (e) {
              // Skip if error
            }
          }
        } catch (e) {
          // Skip if error
        }
      }

      if (mounted) {
        setState(() {
          _allComments = allComments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load comments: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
      await _apiService.deleteComment(commentId);
      if (mounted) {
        _loadAllComments();
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
    return RefreshIndicator(
      onRefresh: _loadAllComments,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAllComments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _allComments.isEmpty
                  ? const Center(child: Text('No comments found'))
                  : ListView.builder(
                      itemCount: _allComments.length,
                      itemBuilder: (context, index) {
                        final comment = _allComments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.comment, color: Colors.orange),
                            ),
                            title: Text(
                              comment['targetTitle'] ?? 'Unknown Target',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(comment['content'] ?? ''),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: comment['targetType'] == 'QUESTION'
                                            ? Colors.blue.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        comment['targetType'] ?? 'UNKNOWN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: comment['targetType'] == 'QUESTION'
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      comment['username'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteComment(comment['id']),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

