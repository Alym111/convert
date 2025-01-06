import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_window.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Функция для отправки запроса на сервер для проверки логина и пароля
  Future<void> _login(BuildContext context) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final url = Uri.parse('https://Alym.pythonanywhere.com/login/');

    try {
      final response = await http.post(
        url,
        body: json.encode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.statusCode < 300) {
        // Если успешный ответ от сервера
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainWindow()),
        );
      } else {
        // Если неудачный запрос (например, ошибка авторизации)
        _showErrorDialog(context, 'Invalid username or password! ${response.statusCode}');
      }
    } catch (e) {
      // Ошибка при подключении к серверу
      _showErrorDialog(context, 'Failed to connect to the server: $e');
    }
  }

  // Функция для показа диалога с ошибкой
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Белый фон для страницы
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20), // Меньше отступов
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Новый текст (например, название приложения)
              Text(
                'Welcome !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Яркий цвет
                ),
              ),
              const SizedBox(height: 40),
              // Поле для имени пользователя (уменьшено)
              Container(
                width: 300, // Уменьшили ширину поля
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Светлый фон для поля ввода
                  borderRadius: BorderRadius.circular(6), // Уменьшили радиус
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Поле для пароля (уменьшено)
              Container(
                width: 300, // Уменьшили ширину поля
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Светлый фон для поля ввода
                  borderRadius: BorderRadius.circular(6), // Уменьшили радиус
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Кнопка входа (уменьшена)
              ElevatedButton(
                onPressed: () => _login(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Яркий цвет для кнопки
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40), // Меньше padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Меньше радиус
                  ),
                  elevation: 4, // Тень для кнопки
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
