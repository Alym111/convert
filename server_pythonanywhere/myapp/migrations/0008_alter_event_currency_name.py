# Generated by Django 5.1.4 on 2024-12-28 11:14

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("myapp", "0007_event_delete_currencydata"),
    ]

    operations = [
        migrations.AlterField(
            model_name="event",
            name="currency_name",
            field=models.CharField(max_length=100),
        ),
    ]
