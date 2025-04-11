import os
import webbrowser
from datetime import datetime
from flask import Flask, render_template, redirect, url_for, flash, request, jsonify, session
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import Date
import random
import json

from config import Config
from database import init_db, db_session
from models import User, Devotee, Visit, Item
from forms import LoginForm, DevoteeForm, DevoteeIDForm, AdminSetupForm
from utils.printer import generate_prn_template
from utils.report_generator import generate_report

app = Flask(__name__)
app.config.from_object(Config)

# Initialize login manager
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# Initialize the database
init_db()

# Insert default items if they don't exist
def initialize_items():
    if Item.query.count() == 0:
        items = [
            "Prasad 1", "Prasad 2", "Prasad 3", "Prasad 4", "Prasad 5", 
            "Prasad 6", "Prasad 7", "Prasad 8", "Prasad 9", "Prasad 10",
            "Prasad 11", "Prasad 12", "Prasad 13", "Prasad 14", "Prasad 15",
            "Prasad 16", "Prasad 17", "Prasad 18"
        ]
        for item_name in items:
            item = Item(name=item_name)
            db_session.add(item)
        db_session.commit()

# Initialize app activation status
def check_app_activated():
    return User.query.filter_by(is_admin=True).first() is not None

# Routes
@app.route('/')
def index():
    if not check_app_activated():
        return redirect(url_for('admin_setup'))
    return render_template('home.html', app_activated=check_app_activated())

@app.route('/admin_setup', methods=['GET', 'POST'])
def admin_setup():
    if check_app_activated():
        flash('Application is already activated', 'info')
        return redirect(url_for('index'))
    
    form = AdminSetupForm()
    if form.validate_on_submit():
        hashed_password = generate_password_hash(form.password.data)
        admin = User(
            username=form.username.data,
            email=form.email.data,
            password=hashed_password,
            is_admin=True
        )
        db_session.add(admin)
        db_session.commit()
        flash('Admin account created! Application activated.', 'success')
        return redirect(url_for('login'))
    return render_template('admin_setup.html', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if not check_app_activated():
        return redirect(url_for('admin_setup'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and check_password_hash(user.password, form.password.data):
            login_user(user)
            next_page = request.args.get('next')
            flash('Login successful!', 'success')
            return redirect(next_page or url_for('index'))
        flash('Invalid username or password', 'danger')
    return render_template('login.html', form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out', 'info')
    return redirect(url_for('index'))

@app.route('/devotee', methods=['GET', 'POST'])
def devotee():
    if not check_app_activated():
        return redirect(url_for('admin_setup'))
    
    form = DevoteeIDForm()
    if form.validate_on_submit():
        devotee_id = form.devotee_id.data
        devotee = Devotee.query.filter_by(devotee_id=devotee_id).first()
        
        if not devotee:
            flash('Devotee ID not found!', 'danger')
            return redirect(url_for('devotee'))
        
        # Get a random item
        all_items = Item.query.all()
        selected_item = random.choice(all_items)
        
        # Record the visit
        visit = Visit(
            devotee_id=devotee.id,
            item_id=selected_item.id,
            visit_date=datetime.now()
        )
        db_session.add(visit)
        db_session.commit()
        
        # Generate PRN template for the selected item
        prn_data = {
            'devotee_id': devotee_id,
            'devotee_name': devotee.name,
            'item': selected_item.name,
            'date': datetime.now().strftime('%Y-%m-%d')
        }
        prn_template = generate_prn_template(prn_data)
        
        # Store data in session for display
        session['print_data'] = {
            'devotee_id': devotee_id,
            'devotee_name': devotee.name,
            'item': selected_item.name,
            'date': datetime.now().strftime('%Y-%m-%d'),
            'prn_template': prn_template
        }
        
        return render_template('devotee.html', form=form, print_data=session['print_data'])
    
    print_data = session.get('print_data', None)
    return render_template('devotee.html', form=form, print_data=print_data)

@app.route('/dashboard')
@login_required
def dashboard():
    devotees = Devotee.query.all()
    total_visits = Visit.query.count()
    
    # Get daily visits
    today = datetime.now().date()
    daily_visits = Visit.query.filter(Visit.visit_date.cast(Date) == today).count()
    
    # Get monthly visits
    month_start = datetime(today.year, today.month, 1).date()
    monthly_visits = Visit.query.filter(Visit.visit_date.cast(Date) >= month_start).count()
    
    # Get yearly visits
    year_start = datetime(today.year, 1, 1).date()
    yearly_visits = Visit.query.filter(Visit.visit_date.cast(Date) >= year_start).count()
    
    return render_template(
        'dashboard.html',
        devotees=devotees,
        total_visits=total_visits,
        daily_visits=daily_visits,
        monthly_visits=monthly_visits,
        yearly_visits=yearly_visits
    )

@app.route('/add_devotee', methods=['GET', 'POST'])
@login_required
def add_devotee():
    form = DevoteeForm()
    if form.validate_on_submit():
        devotee = Devotee(
            devotee_id=form.devotee_id.data,
            name=form.name.data,
            phone=form.phone.data,
            email=form.email.data,
            address=form.address.data
        )
        db_session.add(devotee)
        db_session.commit()
        flash('Devotee added successfully!', 'success')
        return redirect(url_for('add_devotee'))
    return render_template('add_devotee.html', form=form)

@app.route('/api/reports/<report_type>')
@login_required
def get_report(report_type):
    data = generate_report(report_type)
    return jsonify(data)

@app.route('/api/devotee/<devotee_id>/visits')
@login_required
def get_devotee_visits(devotee_id):
    devotee = Devotee.query.filter_by(devotee_id=devotee_id).first()
    if not devotee:
        return jsonify({'error': 'Devotee not found'}), 404
    
    visits = Visit.query.filter_by(devotee_id=devotee.id).all()
    visit_data = []
    for visit in visits:
        item = Item.query.get(visit.item_id)
        visit_data.append({
            'date': visit.visit_date.strftime('%Y-%m-%d'),
            'item': item.name if item else 'Unknown'
        })
    
    return jsonify({
        'devotee': {
            'id': devotee.devotee_id,
            'name': devotee.name
        },
        'visits': visit_data
    })

@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()

if __name__ == '__main__':
    # Initialize items on startup
    initialize_items()
    # Open the browser automatically
    webbrowser.open('http://localhost:5000')
    # Run the app
    app.run(host='0.0.0.0', port=5000, debug=True)
