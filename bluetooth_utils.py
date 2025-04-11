"""
This file contains utility functions for Bluetooth connectivity.
Note: Direct Bluetooth connectivity from Python is complex and depends on the system.
We'll use the Web Bluetooth API through the browser for the connection and printer operations.
This file provides support functions for that approach.
"""

import logging

logger = logging.getLogger(__name__)

def get_connection_status():
    """
    Get the connection status from the client
    This is a placeholder as the actual connection status is managed by the front-end
    """
    return {
        'connected': False,
        'device_name': None
    }

def format_printer_command(prn_template, data):
    """
    Format a printer command based on the template and data
    """
    try:
        formatted_command = prn_template
        for key, value in data.items():
            placeholder = f"{{{key}}}"
            formatted_command = formatted_command.replace(placeholder, str(value))
        return formatted_command
    except Exception as e:
        logger.error(f"Error formatting printer command: {e}")
        return None

def validate_printer_data(data):
    """
    Validate the data for printer before sending
    """
    required_fields = ['devotee_id', 'item', 'date']
    
    for field in required_fields:
        if field not in data or not data[field]:
            return False, f"Missing required field: {field}"
    
    return True, "Data valid"
