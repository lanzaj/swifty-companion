import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback logout;

  const SearchPage({super.key, required this.logout});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _searchUser() async {
    final login = _controller.text.trim();
    if (login.isEmpty) return;

    setState(() => _isLoading = true);

    final user = await _apiService.fetchUser(login);

    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(user: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found or network error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter 42 Login',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
