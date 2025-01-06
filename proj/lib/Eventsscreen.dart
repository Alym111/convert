import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<List<dynamic>> events = [];
  List<List<dynamic>> filteredEvents = [];  // Список для отфильтрованных данных
  String selectedCurrency = "Currencies"; // Выбранная валюта
  String selectedTransactionType = "Transaction Type"; // Выбранный тип транзакции
  List<String> currencies = []; // Список валют для Dropdown
  List<String> transactionTypes = ["Transaction Type", "BUY", "SELL"]; // Список типов транзакций для Dropdown
  List<String> filteredCurrencies = [];
  // Функция для получения данных о валютах с сервера
Future<void> _fetchCurrencies() async {
  const url = 'https://alym.pythonanywhere.com/get_currenciescode/';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Fetched data: $data");  // Для отладки

      setState(() {
        // Присваиваем полученные данные в список валют
        currencies = List<String>.from(data);
        currencies.insert(0, "Currencies"); // Добавляем "Currency" как первый элемент
      });
    } else {
      throw Exception('Failed to load currencies');
    }
  } catch (e) {
    print('Error loading currencies: $e');
  }
}

  // Функция для получения данных с сервера о событиях
  Future<void> _fetchEvents() async {
    const url = 'https://Alym.pythonanywhere.com/get_events'; // Замените на реальный URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          events = data.map((event) {
            return [
              event['id'],  // Добавляем ID события
              event['created_at'],  // Время из ответа
              event['transaction_type'],
              event['currency_name'],
              event['amount'],
              event['rate'],
              event['result'],
            ];
          }).toList();
          filteredEvents = List.from(events);  // Инициализируем filteredEvents при загрузке
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  // Функция для фильтрации событий по валюте и типу транзакции
  void _updateEvents() {
    List<List<dynamic>> tempEvents = List.from(events);

    // Фильтрация по валюте
    if (selectedCurrency != "Currencies") {
      tempEvents = tempEvents.where((event) => event[3] == selectedCurrency).toList();
    }

    // Фильтрация по типу транзакции
    if (selectedTransactionType != "Transaction Type") {
      tempEvents = tempEvents.where((event) => event[2] == selectedTransactionType).toList();
    }

    setState(() {
      filteredEvents = tempEvents;
    });
  }

  // Функция для форматирования времени
  String formatDateTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();  // Загружаем валюты при инициализации
    _fetchEvents(); 
    filteredCurrencies = List.from(currencies); // Загружаем события при инициализации
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        "Events",
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.deepPurple,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Размещаем два Dropdown кнопки в одну строку
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown для выбора типа транзакции
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.deepPurple.shade50,
                ),
                child: DropdownButton<String>(
                  value: selectedTransactionType,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                  iconSize: 30,
                  elevation: 16,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.deepPurple),
                  items: transactionTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTransactionType = value!;
                    });
                    _updateEvents();  // Обновляем список событий
                  },
                ),
              ),
              
              // Кнопка для выбора валюты с поиском
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade300,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                        filteredCurrencies = currencies
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
                  if (selected != null) {
                    setState(() {
                      selectedCurrency = selected;
                    });
                    _updateEvents();
                  }
                },
                child: Text(
                  selectedCurrency,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Time: ${formatDateTime(event[1])}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        Text("Type: ${event[2]}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        Text("Currency: ${event[3]}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        Text("Amount: ${event[4]}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        Text("Rate: ${event[5]}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                        Text("Total: ${event[6]}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => editEvent(events.indexOf(event)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteEvent(events.indexOf(event)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}



  void deleteEvent(int index) async {
  final event = events[index];
  String eventId = event[0].toString(); // ID события - это первый элемент массива

  // Логируем ID для проверки
  print('Deleting event with ID: $eventId');

  final response = await http.delete(
    Uri.parse('https://Alym.pythonanywhere.com/delete_event/$eventId/'), // URL для удаления
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    setState(() {
      // Удаляем событие из локального списка
      _fetchEvents();
      events.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event deleted successfully')),
    );
  } else {
    print('Failed to delete event: ${response.body}'); // Логируем ошибку
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete event ${response.statusCode }')),
    );
  }
}



     // Функция редактирования события
  void editEvent(int index) {
    final event = events[index];
    String time = event[1];  // Время из ответа
    String type = event[2];
    String currency = event[3];
    String amount = event[4].toString();
    String rate = event[5].toString();
    String eventId = event[0].toString();  // ID события

    // Контроллеры для редактируемых полей
    TextEditingController timeController = TextEditingController(text: time);
    TextEditingController amountController = TextEditingController(text: amount);
    TextEditingController rateController = TextEditingController(text: rate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Time (e.g., 12:00)"),
                controller: timeController,
                onChanged: (value) => time = value,  // Обновляем время
              ),
              DropdownButton<String>(
                value: type,
                items: ["BUY", "SELL"].map((String value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    type = value!;  // Обновляем тип транзакции
                  });
                },
              ),
              DropdownButton<String>(
                value: currency,
                items: currencies.map((String value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    currency = value!;  // Обновляем валюту
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                controller: amountController,
                onChanged: (value) => amount = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Rate"),
                keyboardType: TextInputType.number,
                controller: rateController,
                onChanged: (value) => rate = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (time.isNotEmpty && amount.isNotEmpty && rate.isNotEmpty) {
                  // Преобразуем время в формат ISO 8601
                  final DateFormat dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
                  String formattedTime = dateFormat.format(DateTime.parse(time));  // Преобразуем в ISO 8601

                  final updatedEvent = {
                    'created_at': formattedTime,  // Время в нужном формате
                    'transaction_type': type,
                    'currency_name': currency,
                    'amount': double.parse(amount),
                    'rate': double.parse(rate),
                    'result': double.parse(amount) * double.parse(rate),
                  };

                  // Отправляем на сервер
                  _updateEvent(eventId, updatedEvent);
                  Navigator.of(context).pop(); // Закрыть диалог
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
  // Функция для обновления события на сервере
  Future<void> _updateEvent(String eventId, Map<String, dynamic> updatedEvent) async {
  final url = 'https://Alym.pythonanywhere.com/update_event/$eventId/';  // Реальный URL для обновления события
  print('Updating event with ID: $eventId');  // Логируем ID события для обновления

  try {
    final response = await http.put(
      Uri.parse(url),
      body: jsonEncode(updatedEvent),  // Форматируем данные в JSON
      headers: {'Content-Type': 'application/json'},  // Указываем тип контента
    );

    if (response.statusCode == 200) {
      setState(() {
        // После успешного обновления, загружаем все события заново с сервера
        _fetchEvents();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event updated successfully')),
      );
    } else {
      print('Failed to update event: ${response.statusCode} - ${response.body}'); // Логируем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event ${response.statusCode}')),
      );
    }
  } catch (e) {
    // Логируем исключение, если что-то пошло не так
    print('Error updating event: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating event')),
    );
  }
}
}
