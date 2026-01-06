import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAnswersPage extends StatefulWidget {
  const AdminAnswersPage({super.key});

  @override
  State<AdminAnswersPage> createState() => AdminAnswersPageState();
}

class AdminAnswersPageState extends State<AdminAnswersPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allAnswers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllAnswers();
  }

  Future<void> _loadAllAnswers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all questions first, then get answers for each
      final questions = await _apiService.getQuestions();
      List<dynamic> allAnswers = [];
      
      for (var question in questions) {
        try {
          final answers = await _apiService.getAnswers(question['id']);
          for (var answer in answers) {
            answer['questionTitle'] = question['title'];
            answer['questionId'] = question['id'];
            allAnswers.add(answer);
          }
        } catch (e) {
          // Skip if error loading answers for a question
        }
      }

      if (mounted) {
        setState(() {
          _allAnswers = allAnswers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load answers: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAnswer(int answerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Answer'),
        content: const Text('Are you sure you want to delete this answer?'),
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
        _loadAllAnswers();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllAnswers,
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
                        onPressed: _loadAllAnswers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _allAnswers.isEmpty
                  ? const Center(child: Text('No answers found'))
                  : ListView.builder(
                      itemCount: _allAnswers.length,
                      itemBuilder: (context, index) {
                        final answer = _allAnswers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: answer['isAccepted'] == true ? 3 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: answer['isAccepted'] == true
                                ? BorderSide(color: Colors.green.shade300, width: 2)
                                : BorderSide.none,
                          ),
                          color: answer['isAccepted'] == true ? Colors.green.shade50 : Colors.white,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.reply, color: Colors.green),
                            ),
                            title: Text(
                              answer['questionTitle'] ?? 'Unknown Question',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  answer['content'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      answer['username'] ?? answer['userName'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (answer['isAccepted'] == true) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ACCEPTED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAnswer(answer['id']),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

