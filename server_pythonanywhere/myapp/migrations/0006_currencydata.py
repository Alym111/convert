# Generated by Django 5.1.4 on 2024-12-27 13:34

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("myapp", "0005_currency"),
    ]

    operations = [
        migrations.CreateModel(
            name="CurrencyData",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("currency_name", models.CharField(max_length=10)),
                ("amount", models.FloatField()),
                ("rate", models.FloatField()),
                ("result", models.FloatField()),
                ("transaction_type", models.CharField(max_length=10)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
    ]
