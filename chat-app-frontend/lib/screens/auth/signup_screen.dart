import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/string_constants.dart';
import '../../services/api_service.dart';
import '../../services/response_handler.dart';
import '../main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    setState(() => _isLoading = true);

    await ResponseHandler.handleApiCall(
      context,
      () async {
        await ApiService.signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      },
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                    _buildTitleText(),
                    const SizedBox(height: 48),
                    _buildNameFields(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 32),
                    _buildSignUpButton(),
                    const SizedBox(height: 24),
                    _buildSignInLink(),
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

  Widget _buildTitleText() {
    return Column(
      children: [
        Text(
          StringConstants.createAccount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          StringConstants.signUpToGetStarted,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 400) {
          return _buildNameFieldsRow();
        } else {
          return _buildNameFieldsColumn();
        }
      },
    );
  }

  Widget _buildNameFieldsRow() {
    return Row(
      children: [
        Expanded(child: _buildFirstNameField()),
        const SizedBox(width: 16),
        Expanded(child: _buildLastNameField()),
      ],
    );
  }

  Widget _buildNameFieldsColumn() {
    return Column(
      children: [
        _buildFirstNameField(),
        const SizedBox(height: 16),
        _buildLastNameField(),
      ],
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      decoration: const InputDecoration(
        labelText: StringConstants.firstName,
        hintText: StringConstants.enterFirstName,
        prefixIcon: Icon(Icons.person_outline),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return StringConstants.firstNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      decoration: const InputDecoration(
        labelText: StringConstants.lastName,
        hintText: StringConstants.enterLastName,
        prefixIcon: Icon(Icons.person_outline),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return StringConstants.lastNameRequired;
        }
        return null;
      },
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return StringConstants.emailRequired;
        }
        if (!value.contains('@')) {
          return StringConstants.emailInvalid;
        }
        return null;
      },
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
        if (value.length < 6) {
          return StringConstants.passwordTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
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
                StringConstants.signUp,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          StringConstants.alreadyHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            StringConstants.signIn,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
