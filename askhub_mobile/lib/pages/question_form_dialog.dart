import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuestionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final List<dynamic> topics;
  final Function(dynamic) onSave;

  const QuestionFormDialog({
    super.key,
    this.question,
    required this.topics,
    required this.onSave,
  });

  @override
  State<QuestionFormDialog> createState() => QuestionFormDialogState();
}

class QuestionFormDialogState extends State<QuestionFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  int? _selectedTopicId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.question?['title'] ?? '');
    _contentController = TextEditingController(text: widget.question?['content'] ?? '');
    _selectedTopicId = widget.question?['topicId'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Title is required');
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Content is required');
      return;
    }
    if (_selectedTopicId == null) {
      setState(() => _errorMessage = 'Please select a topic');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      if (widget.question == null) {
        // Create new question
        await apiService.createQuestion(
          _titleController.text.trim(),
          _contentController.text.trim(),
          _selectedTopicId!,
        );
      } else {
        // Update existing question
        await apiService.updateQuestion(
          widget.question!['id'],
          {
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'topicId': _selectedTopicId,
          },
        );
      }

      if (mounted) {
        widget.onSave(null);
        Navigator.of(context).pop();
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
      title: Text(widget.question == null ? 'Ask a Question' : 'Edit Question'),
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
            // Topic Dropdown
            DropdownButtonFormField<int>(
              initialValue: _selectedTopicId,
              decoration: InputDecoration(
                labelText: 'Topic',
                hintText: 'Select a topic',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.topics
                  .map((topic) => DropdownMenuItem<int>(
                        value: topic['id'] as int,
                        child: Text(topic['name']),
                      ))
                  .toList(),
              onChanged: _isLoading ? null : (value) => setState(() => _selectedTopicId = value),
            ),
            const SizedBox(height: 12),
            // Title Field
            TextField(
              controller: _titleController,
              enabled: !_isLoading,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What is your question?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            // Content Field
            TextField(
              controller: _contentController,
              enabled: !_isLoading,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Details',
                hintText: 'Provide more details about your question...',
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
          onPressed: _isLoading ? null : _saveQuestion,
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
