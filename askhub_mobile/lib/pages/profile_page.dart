import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userFuture;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;

  @override
  void initState() {
    super.initState();
    _userFuture = _apiService.getUser(widget.userId);
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
    _avatarUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _apiService.updateUser(widget.userId, {
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatarUrl': _avatarUrlController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _userFuture = _apiService.getUser(widget.userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userFuture = _apiService.getUser(widget.userId);
                      });
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

          final user = snapshot.data!;

          if (!_isEditing) {
            _fullNameController.text = user['fullName'] ?? '';
            _bioController.text = user['bio'] ?? '';
            _avatarUrlController.text = user['avatarUrl'] ?? '';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Avatar Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: (user['avatarUrl'] != null &&
                                user['avatarUrl']!.isNotEmpty)
                            ? NetworkImage(user['avatarUrl'])
                            : null,
                        child: (user['avatarUrl'] == null ||
                                user['avatarUrl']!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.blue.shade600,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bioController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Bio',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _avatarUrlController,
                              decoration: InputDecoration(
                                labelText: 'Avatar URL',
                                prefixIcon: const Icon(Icons.image),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: const Text('Full Name'),
                                subtitle: Text(
                                  user['fullName'] ?? 'Not set',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Email'),
                                subtitle: Text(
                                  user['email'] ?? 'Not set',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.description),
                                title: const Text('Bio'),
                                subtitle: Text(
                                  user['bio'] ?? 'No bio',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Joined'),
                                subtitle: Text(
                                  user['createdAt'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
