"""
Utility functions for generating printer-compatible content
"""

def generate_prn_template(data):
    """
    Generate a PRN template for a barcode printer.
    
    Args:
        data (dict): A dictionary containing the data to be printed on the label
            - devotee_id: The devotee's ID
            - devotee_name: The devotee's name
            - item: The randomly selected item
            - date: The date of the visit
    
    Returns:
        str: The PRN template with data inserted
    """
    # This is a simplified example of a PRN template for a generic barcode printer
    # Real PRN templates will vary based on your specific printer model
    
    # Extract data with defaults
    devotee_id = data.get('devotee_id', 'Unknown')
    devotee_name = data.get('devotee_name', 'Unknown')
    item = data.get('item', 'Unknown Item')
    date = data.get('date', 'Unknown Date')
    
    # Create a sample PRN template
    # The format would need to be adjusted for your specific printer model
    prn_template = f"""
N
D11
B50,20,0,1,2,8,40,B,"{devotee_id}"
A60,70,0,3,1,1,N,"{devotee_name}"
A60,100,0,3,1,1,N,"Item: {item}"
A60,130,0,2,1,1,N,"Date: {date}"
P1
"""
    
    return prn_template

def format_label_for_printer(data):
    """
    Format data for a label printer.
    
    Args:
        data (dict): Data to be printed on the label
    
    Returns:
        dict: Formatted data for the label printer
    """
    # Process the data for printing
    formatted_data = {
        'devotee_id': data.get('devotee_id', 'Unknown'),
        'devotee_name': data.get('devotee_name', 'Unknown'),
        'item': data.get('item', 'Unknown Item'),
        'date': data.get('date', 'Unknown Date')
    }
    
    return formatted_data
