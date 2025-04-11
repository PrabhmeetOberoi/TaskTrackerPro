import os
import secrets

class Config:
    # Generate a random secret key if not provided
    SECRET_KEY = os.environ.get('SECRET_KEY', secrets.token_hex(16))
    
    # Database settings
    SQLALCHEMY_DATABASE_URI = 'sqlite:///temple_management.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # App settings
    APP_NAME = "Temple Management System"
    
    # Items to be selected randomly
    ITEMS_COUNT = 18
