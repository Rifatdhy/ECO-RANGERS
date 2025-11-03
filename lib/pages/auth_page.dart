import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_admin_page.dart'; // Impor dashboard admin
import 'dashboard_user_page.dart';
import '../locator.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final authService = locator<AuthService>();

    try {
      if (_isRegister) {
        await authService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Setelah register, langsung login
        final user = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _handleLoginSuccess(user.isAdmin);
      } else {
        // Proses login
        final user = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _handleLoginSuccess(user.isAdmin);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleLoginSuccess(bool isAdmin) {
    if (!mounted) return;
    // Arahkan berdasarkan status admin
    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardAdminPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardUserPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ganti judul agar lebih umum
        title: Text(_isRegister ? 'Buat Akun Baru' : 'Login Eco Rangers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isRegister)
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Minimal 3 karakter'
                      : null,
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email tidak valid'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: _loading ? null : _submit,
                child: Text(
                  _loading
                      ? 'MOHON TUNGGU...'
                      : (_isRegister ? 'DAFTAR' : 'LOGIN'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister
                      ? 'Sudah punya akun? Login di sini'
                      : 'Belum punya akun? Buat akun baru',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
