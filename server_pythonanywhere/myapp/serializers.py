from rest_framework import serializers # Импорт модели

from .models import Event

class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ['created_at', 'transaction_type', 'currency_name', 'amount', 'rate', 'result']
