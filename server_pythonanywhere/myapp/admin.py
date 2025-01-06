from django.contrib import admin
from .models import User,Event

class UserAdmin(admin.ModelAdmin):
    list_display = ('name', 'password')  # Поля, которые будут отображаться в списке
    search_fields = ('name',)           # Поля для поиска

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'currency_name', 'amount', 'rate', 'result', 'transaction_type')
    list_filter = ('transaction_type', 'currency_name')  # Фильтры в боковой панели
    search_fields = ('currency_name', 'transaction_type')  # Поля для поиска

admin.site.register(User, UserAdmin)