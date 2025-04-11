from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, EmailField, TextAreaField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError
from models import User, Devotee

class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')

class AdminSetupForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=4, max=20)])
    email = EmailField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[
        DataRequired(), 
        Length(min=6, message='Password must be at least 6 characters')
    ])
    confirm_password = PasswordField('Confirm Password', validators=[
        DataRequired(), 
        EqualTo('password', message='Passwords must match')
    ])
    submit = SubmitField('Create Admin Account')
    
    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user:
            raise ValidationError('Username already taken. Please choose a different one.')
    
    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user:
            raise ValidationError('Email already registered. Please use a different one.')

class DevoteeForm(FlaskForm):
    devotee_id = StringField('Devotee ID', validators=[DataRequired()])
    name = StringField('Name', validators=[DataRequired()])
    phone = StringField('Phone Number')
    email = EmailField('Email')
    address = TextAreaField('Address')
    submit = SubmitField('Add Devotee')
    
    def validate_devotee_id(self, devotee_id):
        devotee = Devotee.query.filter_by(devotee_id=devotee_id.data).first()
        if devotee:
            raise ValidationError('Devotee ID already exists. Please use a different one.')

class DevoteeIDForm(FlaskForm):
    devotee_id = StringField('Devotee ID', validators=[DataRequired()])
    submit = SubmitField('Submit')
