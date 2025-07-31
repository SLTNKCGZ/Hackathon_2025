import 'package:hackathon_2025/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key}) ;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        prefixIcon: const Icon(Icons.account_circle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı giriniz';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre giriniz';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.blueAccent,
                          elevation: 4,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final response = await http.post(
                              Uri.parse('http://10.0.2.2:8000/auth/login'),
                              body: {
                                'username': _usernameController.text,
                                'password': _passwordController.text,
                              },
                            );

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              final token = data['access_token'];
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage(token: token)),
                              );
                            } else {
                              // Giriş başarısız
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Kullanıcı adı veya şifre yanlış!')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PasswordResetPage()),
                        );
                      },
                      child: const Text('Şifremi unuttum'),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: const Text('Hesabınız yok mu? Kayıt olun'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  Future<void> _sendResetCode() async {
    setState(() { _loading = true; });
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/auth/forgot-password-send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _emailController.text}),
    );
    setState(() { _loading = false; });
    if (response.statusCode == 200) {
      setState(() { _codeSent = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kod e-posta adresinize gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta gönderilemedi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCodeAndGoToNewPassword() async {
    setState(() { _loading = true; });
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/auth/forgot-password-verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text,
        'code': _codeController.text,
      }),
    );
    setState(() { _loading = false; });
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordPage(
            email: _emailController.text,
            code: _codeController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kod hatalı veya süresi dolmuş.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _loading
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'İşlem yapılıyor...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _codeSent ? Icons.verified_user : Icons.lock_reset,
                          size: 64,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _codeSent ? 'Doğrulama Kodu' : 'Şifre Sıfırlama',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _codeSent 
                            ? 'E-posta adresinize gönderilen 6 haneli kodu giriniz'
                            : 'E-posta adresinizi giriniz, size şifre sıfırlama kodu göndereceğiz',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_codeSent) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-posta Adresi',
                              hintText: 'ornek@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _sendResetCode,
                              child: const Text(
                                'Kodu Gönder',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: 'Doğrulama Kodu',
                              hintText: '123456',
                              prefixIcon: const Icon(Icons.security),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _verifyCodeAndGoToNewPassword,
                              child: const Text(
                                'Kodu Doğrula',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _codeSent = false;
                                _codeController.clear();
                              });
                            },
                            child: const Text(
                              'Farklı e-posta kullan',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class NewPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const NewPasswordPage({super.key, required this.email, required this.code});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler eşleşmiyor!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre en az 6 karakter olmalıdır!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() { _loading = true; });
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/auth/forgot-password-verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'new_password': _newPasswordController.text,
      }),
    );
    setState(() { _loading = false; });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre başarıyla değiştirildi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre değiştirme başarısız.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Yeni Şifre Belirle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _loading
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Şifre değiştiriliyor...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Yeni Şifre Belirle',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Güvenli bir şifre belirleyiniz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre',
                            hintText: 'En az 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Şifreyi Tekrarla',
                            hintText: 'Şifrenizi tekrar girin',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _resetPassword,
                            child: const Text(
                              'Şifreyi Değiştir',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
