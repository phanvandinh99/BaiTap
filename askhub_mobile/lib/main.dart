import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/topics_list_page.dart';
import 'pages/question_form_dialog.dart';
import 'pages/question_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskHub Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userId = await ApiService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _isLoggedIn = userId != null;
        _currentUserId = userId;
        _isLoading = false;
      });
    }
  }

  void _refreshAuth() {
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn
        ? QuestionsListPage(
            onLogout: _refreshAuth,
            currentUserId: _currentUserId,
          )
        : const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService()
          .login(_usernameController.text.trim(), _passwordController.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AskHub'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.question_answer, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to AskHub',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Error Message
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text('Register here'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionsListPage extends StatefulWidget {
  final VoidCallback? onLogout;
  final int? currentUserId;

  const QuestionsListPage({
    super.key,
    this.onLogout,
    this.currentUserId,
  });

  @override
  State<QuestionsListPage> createState() => QuestionsListPageState();
}

class QuestionsListPageState extends State<QuestionsListPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _questions = [];
  List<dynamic> _topics = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  int? _selectedTopicId;
  String _sortBy = 'newest'; // newest, popular

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final questions = await _apiService.getQuestions(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        topicId: _selectedTopicId,
      );
      final topics = await _apiService.getTopics();
      if (mounted) {
        setState(() {
          _questions = _sortQuestions(questions);
          _topics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load questions: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _sortQuestions(List<dynamic> questions) {
    final sorted = List.from(questions);
    if (_sortBy == 'popular') {
      sorted.sort((a, b) => (b['votes'] ?? 0).compareTo(a['votes'] ?? 0));
    }
    return sorted;
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AskHub'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.question_answer), text: 'Questions'),
              Tab(icon: Icon(Icons.category), text: 'Topics'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'My Profile',
              onPressed: () {
                if (widget.currentUserId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: widget.currentUserId!),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Questions Tab
            RefreshIndicator(
              onRefresh: _loadData,
              child: _buildQuestionsTab(),
            ),
            // Topics Tab
            TopicsListPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Ask a Question',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => QuestionFormDialog(
                topics: _topics,
                onSave: (_) => _loadData(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _loadData();
                  },
                ),
                const SizedBox(height: 12),
                // Filter and Sort Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _selectedTopicId,
                        hint: const Text('All Topics'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Topics'),
                          ),
                          ..._topics.map((topic) => DropdownMenuItem<int?>(
                            value: topic['id'],
                            child: Text(topic['name'] ?? ''),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedTopicId = value);
                          _loadData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest')),
                          DropdownMenuItem(value: 'popular', child: Text('Popular')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Questions List
        if (_isLoading)
          SliverFillRemaining(
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          SliverFillRemaining(
            child: Center(
              child: Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          )
        else if (_questions.isEmpty)
          SliverFillRemaining(
            child: const Center(
              child: Text('No questions found'),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final question = _questions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionDetailPage(
                            questionId: question['id'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              question['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Content Preview
                            Text(
                              question['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            // Metadata Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Topic Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    question['topicName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                // Stats Row
                                Row(
                                  children: [
                                    // Answers count
                                    Row(
                                      children: [
                                        const Icon(Icons.comment,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${question['answerCount'] ?? 0}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Views
                                    Row(
                                      children: [
                                        const Icon(Icons.visibility,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${question['viewCount'] ?? 0}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _questions.length,
            ),
          ),
      ],
    );
  }
}
