from decimal import Decimal
# views.py
import logging
from django.shortcuts import render
import json
from django.http import JsonResponse
from rest_framework.decorators import api_view
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password
from django.utils.timezone import now
from datetime import datetime
from .models import Event, GlobalSom

from django.db.models import Sum, Avg

@csrf_exempt
def clear_events(request):
    if request.method == "POST":
        try:
            # Удаляем все события из базы данных
            Event.objects.all().delete()

            # Сбрасываем значение som
            global_som, created = GlobalSom.objects.get_or_create(id=1)  # Получаем или создаём запись с ID=1
            global_som.som = 0
            global_som.save()

            return JsonResponse({"message": "События успешно очищены, значение SOM сброшено."}, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    return JsonResponse({"error": "Неверный метод запроса."}, status=405)


def kassa_data(request):
    """
    Функция для подсчёта данных по валютам.
    Возвращает JSON в формате:
    [
        ["USD", 1000, 200, 1500, 300, 500.0],
        ["EUR", 800, 160, 1200, 240, 400.0],
        ["KGS", 500, 100, 700, 140, 200.0]
    ]
    """
    # Получение уникальных валют
    currencies = Event.objects.values('currency_name').distinct()
    response_data = []

    for currency in currencies:
        currency_name = currency['currency_name']
        events = Event.objects.filter(currency_name=currency_name)

        # Подсчёт покупок
        total_purchase = events.filter(transaction_type="BUY").aggregate(Sum('amount'))['amount__sum'] or 0
        avg_purchase = events.filter(transaction_type="BUY").aggregate(Avg('rate'))['rate__avg'] or 0

        # Подсчёт продаж
        total_sales = events.filter(transaction_type="SELL").aggregate(Sum('amount'))['amount__sum'] or 0
        avg_sales = events.filter(transaction_type="SELL").aggregate(Avg('rate'))['rate__avg'] or 0

        # Подсчёт прибыли
        profit = total_sales*(avg_sales - avg_purchase)

        # Добавление данных по валюте
        response_data.append([currency_name, total_purchase, avg_purchase, total_sales, avg_sales, profit])

    # Отправка данных в JSON-формате
    return JsonResponse(response_data, safe=False)

logger = logging.getLogger(__name__)

def delete_event(request, event_id):
    if request.method == 'DELETE':
        try:
            # Получаем событие по ID
            event = Event.objects.get(id=event_id)
            logger.info(f"Deleting event with ID: {event_id}")

            # Получаем текущий global_som для изменения
            global_som, created = GlobalSom.objects.get_or_create(id=1)

            # Сохраняем результат и тип транзакции
            old_result = Decimal(str(event.result))  # Конвертируем результат в Decimal для точности
            old_transaction_type = event.transaction_type
            logger.info(f"Old result: {old_result}, Old transaction type: {old_transaction_type}")

            # Обновление som: откатываем изменения в зависимости от типа транзакции
            if old_transaction_type == 'BUY':
                global_som.som += old_result  # Если было BUY, откатываем старое изменение
            elif old_transaction_type == 'SELL':
                global_som.som -= old_result  # Если было SELL, откатываем старое изменение

            # Убедимся, что результат корректно сохранен
            logger.info(f"Updated global som after deletion: {global_som.som}")

            # Сохраняем глобальный som после удаления
            global_som.save()

            # Удаляем событие
            event.delete()

            logger.info(f"Event {event_id} deleted successfully.")
            return JsonResponse({'message': 'Event deleted successfully'}, status=200)

        except Event.DoesNotExist:
            logger.error(f"Event {event_id} not found.")
            return JsonResponse({'error': 'Event not found'}, status=404)
        except Exception as e:
            logger.error(f"Error deleting event: {str(e)}")
            return JsonResponse({'error': f'Error deleting event: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=405)



def update_event(request, event_id):
    if request.method == 'PUT':
        try:
            # Получаем событие по ID
            event = Event.objects.get(id=event_id)
            data = json.loads(request.body)

            logger.info(f"Received data for event {event_id}: {data}")

            # Проверка и преобразование даты
            created_at_str = data.get('created_at', None)
            if created_at_str:
                try:
                    created_at = datetime.fromisoformat(created_at_str)  # Преобразуем строку в datetime
                    logger.info(f"Parsed created_at: {created_at}")
                except ValueError:
                    logger.error(f"Invalid date format: {created_at_str}")
                    return JsonResponse({'error': 'Invalid date format. Use ISO 8601 format.'}, status=400)
            else:
                created_at = event.created_at  # Если дата не передана, оставляем старую

            # Преобразуем amount и rate в Decimal для точности
            amount = Decimal(str(data.get('amount', event.amount)))  # Используем str() для точности
            rate = Decimal(str(data.get('rate', event.rate)))
            logger.info(f"Parsed amount: {amount}, rate: {rate}")

            # Получаем текущий global_som для изменения
            global_som, created = GlobalSom.objects.get_or_create(id=1)

            # Сохраняем старое значение som для корректировки
            old_result = Decimal(str(event.result))  # Конвертируем результат в Decimal для корректности
            old_transaction_type = event.transaction_type
            logger.info(f"Old result: {old_result}, Old transaction type: {old_transaction_type}")

            # Вычисляем новый результат
            new_result = amount * rate
            logger.info(f"New result calculated: {new_result}")
            event.result = new_result  # Обновляем результат события

            # Обновление som: откатываем старое изменение и применяем новое
            if old_transaction_type == 'BUY':
                global_som.som += old_result  # Если была операция BUY, откатываем старое изменение
            elif old_transaction_type == 'SELL':
                global_som.som -= old_result  # Если была операция SELL, откатываем старое изменение

            # Обновляем som в зависимости от нового типа транзакции
            new_transaction_type = data.get('transaction_type', event.transaction_type)
            if new_transaction_type == 'BUY':
                global_som.som -= new_result  # Если новая операция BUY, уменьшаем som
            elif new_transaction_type == 'SELL':
                global_som.som += new_result  # Если новая операция SELL, увеличиваем som
            logger.info(f"Updated global som: {global_som.som}")

            # Сохраняем глобальный som
            global_som.save()

            # Обновляем само событие
            event.created_at = created_at
            event.transaction_type = new_transaction_type
            event.currency_name = data.get('currency_name', event.currency_name)
            event.amount = amount
            event.rate = rate
            event.save()

            logger.info(f"Event {event_id} updated successfully.")
            return JsonResponse({'message': 'Event updated successfully'}, status=200)

        except Event.DoesNotExist:
            logger.error(f"Event {event_id} not found.")
            return JsonResponse({'error': 'Event not found'}, status=404)
        except ValueError as e:
            logger.error(f"Invalid value: {str(e)}")
            return JsonResponse({'error': f'Invalid value: {str(e)}'}, status=400)
        except json.JSONDecodeError:
            logger.error("Invalid JSON format")
            return JsonResponse({'error': 'Invalid JSON format'}, status=400)
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            return JsonResponse({'error': f'Unexpected error: {str(e)}'}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=405)



from .models import Currency

def get_currencies(request):
    try:
        currencies = Currency.objects.all()
        currency_data = [
            {'currency_code': currency.code, 'currency_name': currency.name} for currency in currencies
        ]
        return JsonResponse(currency_data, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_events(request):
    try:
        events = Event.objects.all().order_by('-created_at')
        event_data = [
            {
                'id': event.id,
                'created_at': event.created_at,
                'transaction_type': event.transaction_type,
                'currency_name': event.currency_name,
                'amount': event.amount,
                'rate': event.rate,
                'result': event.result,
            }
            for event in events
        ]
        return JsonResponse(event_data, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


logger = logging.getLogger(__name__)

@csrf_exempt
def add_currency(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            # Make sure the data is in the expected format
            name = data.get('name')
            code = data.get('code')

            if not name or not code:
                return JsonResponse({'error': 'Missing name or code'}, status=400)

            # Process the data, save to DB, etc.
            # Assuming you have a Currency model
            Currency.objects.create(name=name, code=code)

            return JsonResponse({'message': 'Currency added successfully'}, status=200)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
@csrf_exempt
def add_event(request):
    if request.method == 'POST':
        try:
            logger.info(f"Полученный JSON: {request.body}")

            # Парсим тело запроса
            data = json.loads(request.body)
            currency_data = data.get('currency_data', [])

            if not isinstance(currency_data, list):
                return JsonResponse({'error': 'currency_data должен быть списком'}, status=400)

            events = []
            for entry in currency_data:
                # Проверяем наличие всех ключей
                required_keys = ['currency_name', 'amount', 'rate', 'result', 'transaction_type']
                if not all(key in entry for key in required_keys):
                    return JsonResponse({'error': f'Некорректный формат данных: {entry}'}, status=400)

                # Получаем текущий som из GlobalSom (если он не существует, создаём новый)
                global_som, created = GlobalSom.objects.get_or_create(id=1, defaults={'som': 0.0})

                # Логика для обновления общего som в зависимости от transaction_type
                if entry['transaction_type'] == 'BUY':
                    global_som.som -= Decimal(entry['result'])
                elif entry['transaction_type'] == 'SELL':
                    global_som.som += Decimal(entry['result'])

                # Сохраняем обновленный som
                global_som.save()

                # Создаем объект для добавления в базу (но не сохраняем som в Event)
                event = Event(
                    created_at=now(),  # Используем django.utils.timezone.now()
                    currency_name=entry['currency_name'],
                    amount=entry['amount'],
                    rate=entry['rate'],
                    result=entry['result'],
                    transaction_type=entry['transaction_type'],
                )

                events.append(event)

            # Сохраняем события в базу одним запросом
            Event.objects.bulk_create(events)

            return JsonResponse({'message': 'Данные успешно сохранены!'}, status=200)

        except Exception as e:
            logger.error(f"Ошибка при добавлении события: {e}")
            return JsonResponse({'error': str(e)}, status=500)


@api_view(['POST'])
def add_user(request):
    # Получаем данные из запроса
    username = request.data.get('username')
    password = request.data.get('password')

    # Проверка, что имя пользователя и пароль переданы
    if not username or not password:
        return JsonResponse({'status': 'failed', 'message': 'Username and password are required'}, status=400)

    # Проверка, существует ли уже пользователь с таким именем
    if User.objects.filter(username=username).exists():
        return JsonResponse({'status': 'failed', 'message': 'Username already exists'}, status=400)

    # Хэшируем пароль перед сохранением
    hashed_password = make_password(password)

    try:
        # Создаём нового пользователя
        User.objects.create(username=username, password=hashed_password)
        # Возвращаем успешный ответ
        return JsonResponse({'status': 'success', 'message': 'User created successfully'}, status=201)
    except Exception as e:
        # Если произошла ошибка при создании пользователя, возвращаем ошибку
        return JsonResponse({'status': 'failed', 'message': str(e)}, status=500)


@csrf_exempt  # Если у вас возникают проблемы с CSRF, можно использовать декоратор @csrf_exempt
def login_view(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)  # Преобразуем тело запроса в JSON
            username = data.get('username')  # Получаем имя пользователя
            password = data.get('password')  # Получаем парол

            user = authenticate(username=username, password=password)
            if user is not None:
                # Пользователь найден, возвращаем успешный ответ
                return JsonResponse({'status': 'success'}, status=200)
            else:
                # Неверные данные
                return JsonResponse({'status': 'failed', 'message': 'Invalid username or password'}, status=400)

        except json.JSONDecodeError:
            return JsonResponse({'status': 'failed', 'message': 'Invalid JSON data'}, status=400)
    else:
        return JsonResponse({'status': 'failed', 'message': 'Invalid request method'}, status=405)

def home(request):
    return render(request, 'home.html')

# # Получение списка пользователей
@api_view(['GET'])
def get_users(request):
    users = User.objects.values_list('username', flat=True)
    return JsonResponse(list(users), safe=False)

@api_view(['GET'])
def get_currenciesname(request):
    # Получаем все валюты из базы данных
    currencies = Currency.objects.values_list('name', flat=True)

    # Возвращаем список валют в формате JSON
    return JsonResponse(list(currencies), safe=False)
@api_view(['GET'])
def get_currenciescode(request):
    # Получаем все валюты из базы данных
    currencies = Currency.objects.values_list('code', flat=True)
    return JsonResponse(list(currencies), safe=False)
def get_som(request):
    try:
        # Получаем текущий объект GlobalSom (предполагается, что id=1)
        global_som = GlobalSom.objects.get(id=1)
        # Отправляем текущее значение som в ответе
        return JsonResponse({'som': str(global_som.som)}, status=200)
    except GlobalSom.DoesNotExist:
        # Если объекта не существует, создаем новый с начальным значением
        global_som = GlobalSom.objects.create(som=0)
        return JsonResponse({'som': str(global_som.som)}, status=200)


