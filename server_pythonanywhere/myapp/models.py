from django.db import models

class User(models.Model):
    name = models.CharField(max_length=100)
    password = models.IntegerField()

    def __str__(self):
        return self.name

class Currency(models.Model):
    name = models.CharField(max_length=50, unique=True)  # Название валюты, например, "Доллар США"
    code = models.CharField(max_length=3, unique=True)  # Код валюты (ISO 4217), например, "USD"

    def __str__(self):
        return self.name


class Event(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    currency_name = models.CharField(max_length=100)
    amount = models.FloatField()
    rate = models.FloatField()
    result = models.FloatField()
    transaction_type = models.CharField(max_length=10)

    def __str__(self):
        return f"{self.currency_name} - {self.transaction_type}"

class GlobalSom(models.Model):
    som = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    def __str__(self):
        return f"Global SOM: {self.som}"