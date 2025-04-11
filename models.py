from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Date
from sqlalchemy.orm import relationship
from flask_login import UserMixin
from datetime import datetime

from database import Base

class User(UserMixin, Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(64), unique=True, nullable=False, index=True)
    email = Column(String(120), unique=True, nullable=False, index=True)
    password = Column(String(128), nullable=False)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.now)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Devotee(Base):
    __tablename__ = 'devotees'
    
    id = Column(Integer, primary_key=True)
    devotee_id = Column(String(20), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    phone = Column(String(20))
    email = Column(String(120))
    address = Column(String(200))
    created_at = Column(DateTime, default=datetime.now)
    
    visits = relationship('Visit', backref='devotee', lazy=True)
    
    def __repr__(self):
        return f'<Devotee {self.devotee_id}: {self.name}>'

class Item(Base):
    __tablename__ = 'items'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    description = Column(String(200))
    
    visits = relationship('Visit', backref='item', lazy=True)
    
    def __repr__(self):
        return f'<Item {self.name}>'

class Visit(Base):
    __tablename__ = 'visits'
    
    id = Column(Integer, primary_key=True)
    devotee_id = Column(Integer, ForeignKey('devotees.id'), nullable=False)
    item_id = Column(Integer, ForeignKey('items.id'), nullable=False)
    visit_date = Column(DateTime, default=datetime.now, nullable=False)
    
    def __repr__(self):
        return f'<Visit {self.devotee_id} on {self.visit_date}>'
