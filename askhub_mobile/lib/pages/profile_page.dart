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
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                        Colors.blue.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: (user['avatarUrl'] != null &&
                                  user['avatarUrl']!.isNotEmpty)
                              ? NetworkImage(user['avatarUrl'])
                              : null,
                          child: (user['avatarUrl'] == null ||
                                  user['avatarUrl']!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue.shade600,
                                )
                              : null,
                        ),
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
                            _buildInfoCard(
                              icon: Icons.person,
                              iconColor: Colors.blue,
                              title: 'Full Name',
                              value: user['fullName'] ?? 'Not set',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              icon: Icons.email,
                              iconColor: Colors.green,
                              title: 'Email',
                              value: user['email'] ?? 'Not set',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              icon: Icons.description,
                              iconColor: Colors.orange,
                              title: 'Bio',
                              value: user['bio'] ?? 'No bio',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              icon: Icons.calendar_today,
                              iconColor: Colors.purple,
                              title: 'Joined',
                              value: user['createdAt'] ?? 'Unknown',
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              iconColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
