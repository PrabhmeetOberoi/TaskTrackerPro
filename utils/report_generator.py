"""
Report generation utilities
"""

from datetime import datetime, timedelta
from sqlalchemy import func, cast, Date
import calendar

from database import db_session
from models import Visit, Devotee, Item

def generate_report(report_type):
    """
    Generate a report based on the specified type.
    
    Args:
        report_type (str): The type of report to generate (daily, monthly, yearly, devotees)
    
    Returns:
        dict: A dictionary containing the report data with labels and values
    """
    if report_type == 'daily':
        return generate_daily_report()
    elif report_type == 'monthly':
        return generate_monthly_report()
    elif report_type == 'yearly':
        return generate_yearly_report()
    elif report_type == 'devotees':
        return generate_devotees_report()
    elif report_type == 'items':
        return generate_items_report()
    else:
        # Default to an empty report
        return {
            'labels': [],
            'values': []
        }

def generate_daily_report():
    """
    Generate a report of daily visits for the past 7 days.
    
    Returns:
        dict: A dictionary with labels (dates) and values (visit counts)
    """
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=6)
    
    labels = []
    values = []
    
    current_date = start_date
    while current_date <= end_date:
        # Count visits for the current date
        count = Visit.query.filter(
            cast(Visit.visit_date, Date) == current_date
        ).count()
        
        # Format the date for display
        formatted_date = current_date.strftime('%b %d')
        
        labels.append(formatted_date)
        values.append(count)
        
        # Move to the next day
        current_date += timedelta(days=1)
    
    return {
        'labels': labels,
        'values': values
    }

def generate_monthly_report():
    """
    Generate a report of monthly visits for the past 12 months.
    
    Returns:
        dict: A dictionary with labels (months) and values (visit counts)
    """
    today = datetime.now()
    labels = []
    values = []
    
    # Generate data for the past 12 months
    for i in range(11, -1, -1):
        # Calculate the month
        month = (today.month - i) % 12
        if month == 0:
            month = 12
        year = today.year if month <= today.month else today.year - 1
        
        # Get the first and last day of the month
        _, last_day = calendar.monthrange(year, month)
        first_date = datetime(year, month, 1).date()
        last_date = datetime(year, month, last_day).date()
        
        # Count visits for the month
        count = Visit.query.filter(
            cast(Visit.visit_date, Date) >= first_date,
            cast(Visit.visit_date, Date) <= last_date
        ).count()
        
        # Format the month for display
        month_name = datetime(year, month, 1).strftime('%b %Y')
        
        labels.append(month_name)
        values.append(count)
    
    return {
        'labels': labels,
        'values': values
    }

def generate_yearly_report():
    """
    Generate a report of yearly visits for the past 5 years.
    
    Returns:
        dict: A dictionary with labels (years) and values (visit counts)
    """
    current_year = datetime.now().year
    labels = []
    values = []
    
    # Generate data for the past 5 years
    for year in range(current_year - 4, current_year + 1):
        first_date = datetime(year, 1, 1).date()
        last_date = datetime(year, 12, 31).date()
        
        # Count visits for the year
        count = Visit.query.filter(
            cast(Visit.visit_date, Date) >= first_date,
            cast(Visit.visit_date, Date) <= last_date
        ).count()
        
        labels.append(str(year))
        values.append(count)
    
    return {
        'labels': labels,
        'values': values
    }

def generate_devotees_report():
    """
    Generate a report of the top devotees by visit count.
    
    Returns:
        dict: A dictionary with labels (devotee names) and values (visit counts)
    """
    # Get the top 10 devotees by visit count
    result = db_session.query(
        Devotee.name,
        func.count(Visit.id).label('visit_count')
    ).join(
        Visit, Visit.devotee_id == Devotee.id
    ).group_by(
        Devotee.id
    ).order_by(
        func.count(Visit.id).desc()
    ).limit(10).all()
    
    labels = []
    values = []
    
    for devotee_name, visit_count in result:
        labels.append(devotee_name)
        values.append(visit_count)
    
    # If there are fewer than 10 devotees, add "Others" category
    if len(result) < 10:
        labels.append("Others")
        values.append(Visit.query.count() - sum(values))
    
    return {
        'labels': labels,
        'values': values
    }

def generate_items_report():
    """
    Generate a report of item distribution.
    
    Returns:
        dict: A dictionary with labels (item names) and values (selection counts)
    """
    # Count how many times each item has been selected
    result = db_session.query(
        Item.name,
        func.count(Visit.id).label('selection_count')
    ).join(
        Visit, Visit.item_id == Item.id
    ).group_by(
        Item.id
    ).order_by(
        func.count(Visit.id).desc()
    ).all()
    
    labels = []
    values = []
    
    for item_name, selection_count in result:
        labels.append(item_name)
        values.append(selection_count)
    
    return {
        'labels': labels,
        'values': values
    }
