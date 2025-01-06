from django.urls import path
from myapp import views

urlpatterns = [
    path('', views.home, name='home'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register, name='register'),# Главная страница приложения
    path('users/',views.get_users,name='users'),
]

# urlpatterns = [
#     # path('api/add_currency_data/', views.add_currency_data, name='add_currency_data'),
#     # path('users/', views.get_users, name='get_users'),
#     # path('users/', views.add_user, name='add_user'),
#     # path('login/', views.login_user, name='login_user'),
# ]