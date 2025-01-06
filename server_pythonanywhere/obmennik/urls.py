"""obmennik URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path
from myapp import views  # Import views from the current application
from django.contrib import admin

urlpatterns = [
    path('clear-events/', views.clear_events, name='clear-events'),
    path('kassa/', views.kassa_data, name='kassa-data'),
    path('get_events/', views.get_events, name='get_events'),
    path('delete_event/<int:event_id>/', views.delete_event, name='delete_event'),
    path('update_event/<int:event_id>/', views.update_event, name='update_event'),
    path('add_event/', views.add_event, name='add_event'),
    path('admin/', admin.site.urls),
    path('', views.home, name='home'),  # Home page route
    path('login/', views.login_view, name='login'),
    path('users/',views.get_users,name='users'),  # Include routes from myapp.urls
    path('get_som/',views.get_som,name='som'),  # Include routes from myapp.urls
    path('add_user/',views.add_user,name='adduser'),
    path('add_currency/',views.add_currency,name='addcurrency'),
    path('get_currenciescode/',views.get_currenciescode,name='currencycode'),
    path('get_currenciesname/',views.get_currenciesname,name='currencyname'),
]