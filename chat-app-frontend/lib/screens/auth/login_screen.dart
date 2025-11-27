import 'package:chat_app_frontend/services/snackbar_service.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/string_constants.dart';
import '../../services/api_service.dart';
import '../../services/response_handler.dart';
import '../main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // need for fast login during demo
    if (_emailController.text=="a") {
      _emailController.text = "a@g.com";
      _passwordController.text = "123456";
    } else if (_emailController.text=="b") {
      _emailController.text = "b@g.com";
      _passwordController.text = "123456";
    } else if (_emailController.text=="c") {
      _emailController.text = "c@g.com";
      _passwordController.text = "123456";
    } else if (_emailController.text.contains("loadtest_")) {
      // _emailController.text = "c@g.com";
      _passwordController.text = "password123";
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    setState(() => _isLoading = true);

    await ResponseHandler.handleApiCall(
      context,
      () async {
        await ApiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      },
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      },
      onError: (error, context) {
        if (mounted) {
          SnackbarService.showError('Either email or password is incorrect');
          setState(() => _isLoading = false);
        }
      },
    );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 24),
                    _buildWelcomeText(),
                    const SizedBox(height: 48),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 32),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Icon(
      Icons.chat_bubble_rounded,
      size: 80,
      color: AppTheme.accentColor,
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          StringConstants.welcomeBack,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          StringConstants.signInToContinue,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: StringConstants.email,
        hintText: StringConstants.enterEmail,
        prefixIcon: Icon(Icons.email_outlined),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: StringConstants.password,
        hintText: StringConstants.enterPassword,
        prefixIcon: const Icon(Icons.lock_outline),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return StringConstants.passwordRequired;
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                StringConstants.signIn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          StringConstants.dontHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: const Text(
            StringConstants.signUp,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return StringConstants.emailRequired;
    }
    if (!value.contains('@')) {
      return StringConstants.emailInvalid;
    }
    return null;
  }
}
