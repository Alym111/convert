# myapp/middleware.py
import logging

logger = logging.getLogger(__name__)

class LogRequestMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        logger.debug(f"Request Path: {request.path} | User: {request.user}")
        response = self.get_response(request)
        logger.debug(f"Response status: {response.status_code}")
        return response
