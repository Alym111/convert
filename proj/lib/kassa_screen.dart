import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KassaScreen extends StatefulWidget {
  KassaScreen({super.key});

  @override
  _KassaScreenState createState() => _KassaScreenState();
}

class _KassaScreenState extends State<KassaScreen> {
  // Заголовки таблицы
  final List<String> headers = [
    "Currency",
    "Total purchase",
    "Average purchase",
    "Total sales",
    "Average sales",
    "Profit",
  ];

  List<List<dynamic>> rows = [];  // Здесь храним данные для таблицы
  double som = 0.0;  // Изначальное значение som
  double income = 0.0;  // Изначальное значение для прибыли
  String errorMessage = ''; // Переменная для ошибок

  // Метод для загрузки данных с сервера для som
  Future<void> fetchSom() async {
    try {
      final response = await http.get(Uri.parse('http://alym.pythonanywhere.com/get_som/'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Печатаем полученные данные для отладки
        print("Ответ от сервера: $data");

        // Убедимся, что ключ 'som' существует в данных
        if (data.containsKey('som')) {
          // Преобразуем значение som из строки в double
          var somString = data['som'].toString();  // Преобразуем значение в строку
          try {
            setState(() {
              som = double.parse(somString);  // Преобразуем строку в double
            });
          } catch (e) {
            print("Ошибка при преобразовании som в double: $e");
            setState(() {
              errorMessage = "Ошибка преобразования значения som в число";  // Устанавливаем сообщение об ошибке
              som = 0.0;  // В случае ошибки присваиваем значение 0.0
            });
          }
        } else {
          setState(() {
            errorMessage = "Ключ 'som' не найден в ответе от сервера";
          });
          print("Ключ 'som' не найден в ответе");
        }
      } else {
        throw Exception('Не удалось загрузить som. Статус ответа: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при запросе som: $e';  // Показываем ошибку пользователю
      });
      print("Ошибка при запросе som: $e");
    }
  }

  // Метод для загрузки данных по событиям (или прибыли) с сервера
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://alym.pythonanywhere.com/kassa/'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Печатаем полученные данные для отладки
        print("Fetched data: $data");

        double totalProfit = 0.0;  // Переменная для хранения общей прибыли

        // Обновляем состояние и преобразуем данные в нужный формат
        setState(() {
          rows = data.map((item) {
            double profit = item[5] ?? 0.0;  // Предположим, что прибыль на 5-й позиции
            totalProfit += profit;  // Добавляем прибыль из текущего элемента
            return [
              item[0],  // currency
              item[1],  // total_purchase
              item[2],  // average_purchase
              item[3],  // total_sales
              item[4],  // average_sales
              profit,   // profit
            ];
          }).toList();
          income = totalProfit;  // Устанавливаем общую прибыль
        });
      } else {
        throw Exception('Не удалось загрузить данные событий');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при запросе данных: $e';  // Показываем ошибку
      });
      print("Ошибка при запросе данных: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSom();  // Загружаем данные для som
    fetchData();  // Загружаем данные для кassa
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Касса"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "KASSA",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Если есть ошибка, отображаем её
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: Map<int, TableColumnWidth>.fromIterable(
                    List.generate(headers.length, (index) => index),
                    value: (index) => FlexColumnWidth(),
                  ),
                  children: [
                    // Строка заголовков
                    TableRow(
                      children: headers
                          .map((header) => _buildCell(header, isHeader: true))
                          .toList(),
                    ),
                    // Строки данных, если данные уже загружены
                    if (rows.isNotEmpty)
                      for (var row in rows)
                        TableRow(
                          children: row
                              .map((value) => _buildCell(value.toString()))
                              .toList(),
                        ),
                    // Если данные еще не загружены, показываем загрузку
                    if (rows.isEmpty)
                      TableRow(
                        children: [
                          _buildCell("Loading...", isHeader: false),
                          _buildCell("Loading...", isHeader: false),
                          _buildCell("Loading...", isHeader: false),
                          _buildCell("Loading...", isHeader: false),
                          _buildCell("Loading...", isHeader: false),
                          _buildCell("Loading...", isHeader: false),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Som: "),
                    SizedBox(width: 10),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          som.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Income: "),
                    SizedBox(width: 10),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          income.toStringAsFixed(2),  // Отображаем прибыль
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
