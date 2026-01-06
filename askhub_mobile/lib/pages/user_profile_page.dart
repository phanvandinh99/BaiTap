import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  final String? userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _apiService.getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName ?? 'User Profile'),
        centerTitle: true,
        elevation: 0,
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Avatar Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
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
                                color: Colors.green.shade600,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['fullName'] != null && user['fullName']!.isNotEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Name'),
                            subtitle: Text(
                              user['fullName'] ?? 'Not set',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (user['fullName'] != null &&
                          user['fullName']!.isNotEmpty)
                        const SizedBox(height: 12),
                      if (user['bio'] != null && user['bio']!.isNotEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Bio'),
                            subtitle: Text(
                              user['bio'] ?? 'No bio',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (user['bio'] != null && user['bio']!.isNotEmpty)
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
                      const SizedBox(height: 12),
                      // Stats Section
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            title: 'Questions',
                            value: _getIntValue(user['questionsCount']).toString(),
                            icon: Icons.help,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            title: 'Answers',
                            value: _getIntValue(user['answersCount']).toString(),
                            icon: Icons.done,
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            title: 'Comments',
                            value: _getIntValue(user['commentsCount']).toString(),
                            icon: Icons.message,
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            title: 'Reputation',
                            value: _getIntValue(user['reputation']).toString(),
                            icon: Icons.star,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    return 0;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
