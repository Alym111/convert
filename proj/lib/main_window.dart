import 'package:flutter/material.dart';
import 'package:convertcurrencies/currency_screen.dart';
import 'package:convertcurrencies/users_screen.dart';
import 'package:convertcurrencies/Eventsscreen.dart';
import 'package:convertcurrencies/kassa_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  _MainWindowState createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  double _result = 0.0;
  bool _isUpButtonSelected = false;
  String? _selectedCurrency;
  List<String> _currencies = [];  // Список для хранения валют
  List<String> filteredCurrencies = [];

  // Функция для загрузки валют с API
Future<void> _fetchCurrencies() async {
  const url = 'https://Alym.pythonanywhere.com/get_currenciescode/';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Просто присваиваем данные, так как это уже список строк
      setState(() {
        _currencies = List<String>.from(data);  // Преобразуем в список строк
      });
    } else {
      throw Exception('Не удалось загрузить валюты');
    }
  } catch (e) {
    print('Ошибка: $e'); // Логирование в консоль
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при загрузке валют: $e')),
    );
  }
}



  @override
  void initState() {
    super.initState();
    _fetchCurrencies();  // Загрузка валют при инициализации
    filteredCurrencies = List.from(_currencies);
  }

  // Функция для вычисления результата
  void _calculateResult() {
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _result = rate * amount;
    });
  }
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CurrencyScreen(
                          onCurrencyAdded: _fetchCurrencies,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),

                  child: const Text('Currency'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Логика для кнопки "Report"
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Report'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => KassaScreen()),
                  );
                    // Логика для кнопки "Kassa"
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Kassa'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>  UsersScreen(),
                      ),
                    );
                    // Логика для кнопки "Users"
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Users'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showClearConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  // Функция для отправки данных на сервер
  void _sendData() async {
    // Проверяем, что все обязательные данные заполнены
    if (_selectedCurrency == null || _amountController.text.isEmpty || _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля и выберите валюту')),
      );
      return; // Прекращаем выполнение, если данные не полные
    }

    String transactionType = _isUpButtonSelected ? 'BUY' : 'SELL'; // Тип транзакции

    // Данные для отправки
    Map<String, dynamic> data = {
      'currency_name': _selectedCurrency ?? 'Unknown',
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'rate': double.tryParse(_rateController.text) ?? 0.0,
      'result': _result,
      'transaction_type': transactionType,
    };

    const String url = 'https://Alym.pythonanywhere.com/add_event/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'currency_data': [data]}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно отправлены!')),
        );
        _amountController.clear();
      _rateController.clear();
      _selectedCurrency = null;
      _result = 0.0; // Сброс результата
      setState(() {}); // Обновляем интерфейс
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    }
  }
 Future<void> _clearData(BuildContext context) async {
  final url = Uri.parse('https://Alym.pythonanywhere.com/clear-events/');

  try {
    final response = await http.post(url);

    // Логируем ответ сервера
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Логируем данные, которые пришли от сервера
      print('Response data: $data');

      final message = data['message'] ?? 'Данные успешно очищены!';

      // Проверяем, что контекст все еще действителен
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),  // Показываем сообщение
          ),
        );
      }
    } else {
      final error = jsonDecode(response.body);

      // Логируем ошибку
      print('Error data: $error');

      final errorMessage = error['error'] ?? 'Произошла ошибка при очистке данных.';

      // Проверяем, что контекст все еще действителен
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    }
  } catch (e) {
    // Логируем исключение
    print('Exception: $e');

    // Проверяем, что контекст все еще действителен
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подключения: $e'),
        ),
      );
    }
  }
}


  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('This action will clear all data.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Закрыть диалог
                await _clearData(context); // Вызов функции для отправки запроса
                
                // Логика очистки данных
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
 // Инициализация filteredCurrencies здесь

  return Scaffold(
    backgroundColor: Colors.grey[100], // Light background color
    body: Stack(
      children: [
        Center(
          child: SingleChildScrollView(  // Scrollable body in case of overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Верхние кнопки с изменяющимися цветами
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Кнопка "Up"
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isUpButtonSelected = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUpButtonSelected
                            ? Colors.green
                            : Colors.transparent,
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: Colors.green, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,  // Add elevation for shadow
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    // Кнопка "Down"
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isUpButtonSelected = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isUpButtonSelected
                            ? Colors.red
                            : Colors.transparent,
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,  // Add elevation for shadow
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- New Section for Currency Selection ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    width: 250, // Задаем фиксированную ширину для кнопки
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                String searchQuery = '';
                                return SimpleDialog(
                                  title: Column(
                                    children: [
                                      Text(
                                        'Select Currency',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Search currency',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              searchQuery = value.toLowerCase();
                                              filteredCurrencies = _currencies
                                                  .where((currency) => currency.toLowerCase().contains(searchQuery))
                                                  .toList();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: filteredCurrencies.map((currency) {
                                    return SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(context, currency);
                                      },
                                      child: Text(currency),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                        );
                        if (selected != 'Currency') {
                          setState(() {
                            _selectedCurrency = selected;
                          });
                        }
                      },
                      child: Text(
                        _selectedCurrency ?? 'Currency',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- New Section for "Count" Input ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Count",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _calculateResult(); // Пересчитываем результат при изменении
                      },
                    ),
                  ),
                ),

                // --- New Section for "Rate" Input ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _rateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Rate",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _calculateResult(); // Пересчитываем результат при изменении
                      },
                    ),
                  ),
                ),

                // --- Result Field ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: TextEditingController(
                        text: _result.toStringAsFixed(2), // Форматируем результат
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Result",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      enabled: false, // Запрещаем редактировать
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- "Add" Button ---
                ElevatedButton(
                  onPressed: _sendData, // Вызов функции отправки данных
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,  // Add elevation for shadow
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 18),
                  ),
                ),

                const SizedBox(height: 10),

                // --- "Events" Button ---
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventsScreen()),
                    );
                  },
                  child: const Text(
                    'Events',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Кнопка "Settings" в левом верхнем углу
        Positioned(
          top: 20,
          left: 20,
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.grey,
              size: 40,
            ),
            onPressed: _showSettingsDialog, // Вызываем диалог при нажатии
          ),
        ),
      ],
    ),
  );
}

}
