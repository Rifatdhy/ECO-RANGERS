import 'package:eco_rangers/ui/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';
import '../locator.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Tambahkan listener untuk mengubah state saat tab berganti
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await locator<AuthService>().login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      _handleLoginSuccess(user.isAdmin);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await locator<AuthService>().register(
        username: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      final user = await locator<AuthService>().login(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      _handleLoginSuccess(user.isAdmin);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleLoginSuccess(bool isAdmin) {
    if (!mounted) return;
    final pageRoute = MaterialPageRoute(
      builder: (_) => isAdmin ? const DashboardAdminPage() : const DashboardUserPage(),
    );
    Navigator.pushReplacement(context, pageRoute);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco_outlined, size: 64, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Eco Rangers', style: textTheme.headlineMedium?.copyWith(color: AppTheme.primaryColor)),
                Text('Menjaga Lingkungan, Satu Laporan pada Satu Waktu', style: textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 32),

                TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Masuk'), Tab(text: 'Daftar')],
                  labelStyle: textTheme.titleMedium,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(height: 24),

                // FIX: Menggunakan IndexedStack sebagai pengganti TabBarView
                IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        Form(
          key: _loginFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _loginEmailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loginPasswordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _isLoading ? null : _handleLogin, child: _isLoading ? const CircularProgressIndicator() : const Text('Masuk')),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        Form(
          key: _registerFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _registerNameController,
                decoration: const InputDecoration(labelText: 'Nama Pengguna', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 karakter' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registerEmailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registerPasswordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
                validator: (v) => (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _isLoading ? null : _handleRegister, child: _isLoading ? const CircularProgressIndicator() : const Text('Daftar Akun Baru')),
      ],
    );
  }
}
