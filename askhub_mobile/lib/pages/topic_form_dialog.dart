import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TopicFormDialog extends StatefulWidget {
  final Map<String, dynamic>? topic;
  final VoidCallback onSave;

  const TopicFormDialog({
    super.key,
    this.topic,
    required this.onSave,
  });

  @override
  State<TopicFormDialog> createState() => TopicFormDialogState();
}

class TopicFormDialogState extends State<TopicFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topic?['name'] ?? '');
    _slugController = TextEditingController(text: widget.topic?['slug'] ?? '');
    _descriptionController = TextEditingController(text: widget.topic?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  Future<void> _saveTopic() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Topic name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      // Auto-generate slug from topic name
      final slug = _generateSlug(_nameController.text.trim());
      
      if (widget.topic == null) {
        // Create new topic
        await apiService.createTopic(
          _nameController.text.trim(),
          slug,
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        // Update existing topic - use existing slug or generate new one
        final finalSlug = _slugController.text.trim().isNotEmpty 
            ? _slugController.text.trim() 
            : slug;
        await apiService.updateTopic(
          widget.topic!['id'],
          _nameController.text.trim(),
          finalSlug,
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        widget.onSave();
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
      title: Text(widget.topic == null ? 'Create Topic' : 'Edit Topic'),
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
              controller: _nameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Topic Name',
                hintText: 'e.g., Flutter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_isLoading,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe the topic...',
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
          onPressed: _isLoading ? null : _saveTopic,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
