import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Список пользователей
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Загружаем пользователей при старте
  }

  // Получение списка пользователей
  Future<void> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('https://Alym.pythonanywhere.com/users/'), // Адрес для получения пользователей
    );

    if (response.statusCode == 200) {
      setState(() {
        _users = List<String>.from(json.decode(response.body)); // Обновляем список пользователей
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Функция для добавления нового пользователя
  Future<void> _addUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('https://Alym.pythonanywhere.com/add_user/'), // Адрес для добавления пользователей
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password, // Добавляем пароль
      }),
    );

    if (response.statusCode == 201) {
      _fetchUsers(); // Перезагружаем список после добавления
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      _showErrorDialog(context, error['message']); // Показываем сообщение об ошибке
    } else {
      throw Exception('Failed to add user');
    }
  }

  // Диалоговое окно для добавления нового пользователя
  void _showAddUserDialog() {
    String username = '';
    String password = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New User'),
          backgroundColor: Colors.green,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  username = value; // Запоминаем имя пользователя
                },
                decoration: const InputDecoration(
                  labelText: 'User Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  password = value; // Запоминаем пароль
                },
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Скрытие пароля
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (username.isNotEmpty && password.isNotEmpty) {
                  _addUser(username, password); // Добавление пользователя
                  Navigator.of(context).pop(); // Закрытие диалога
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Функция для отображения ошибки
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Container(
          width: 300,
          height: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        _users[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _showAddUserDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'New User',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
