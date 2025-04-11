// Global variables for Bluetooth connectivity
let bluetoothDevice = null;
let bluetoothCharacteristic = null;

// Check if Web Bluetooth API is available
function isWebBluetoothAvailable() {
    if (!navigator.bluetooth) {
        console.error('Web Bluetooth API is not available in this browser!');
        return false;
    }
    return true;
}

// Check if a Bluetooth device is connected
function isBluetoothConnected() {
    return bluetoothDevice !== null && bluetoothDevice.gatt.connected;
}

// Get the name of the connected device
function getConnectedDeviceName() {
    return bluetoothDevice ? bluetoothDevice.name : null;
}

// Connect to a Bluetooth printer
async function connectToPrinter() {
    if (!isWebBluetoothAvailable()) {
        showNotification('Web Bluetooth is not available in this browser', 'error');
        return;
    }
    
    // Disconnect from previous device if connected
    if (bluetoothDevice && bluetoothDevice.gatt.connected) {
        await bluetoothDevice.gatt.disconnect();
        bluetoothDevice = null;
        bluetoothCharacteristic = null;
    }
    
    try {
        console.log('Requesting Bluetooth device...');
        bluetoothDevice = await navigator.bluetooth.requestDevice({
            filters: [
                { services: ['000018f0-0000-1000-8000-00805f9b34fb'] }, // Generic printer service UUID
                { namePrefix: 'Printer' },
                { namePrefix: 'BT' }
            ],
            optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb']
        });
        
        console.log('Connecting to GATT server...');
        const server = await bluetoothDevice.gatt.connect();
        
        console.log('Getting primary service...');
        const service = await server.getPrimaryService('000018f0-0000-1000-8000-00805f9b34fb');
        
        console.log('Getting characteristic...');
        bluetoothCharacteristic = await service.getCharacteristic('00002af1-0000-1000-8000-00805f9b34fb');
        
        console.log('Bluetooth device connected:', bluetoothDevice.name);
        showNotification(`Connected to ${bluetoothDevice.name}`, 'success');
        
        // Update UI to show connected device
        updateConnectedDeviceUI();
        
        // Add event listener for disconnection
        bluetoothDevice.addEventListener('gattserverdisconnected', onDisconnected);
        
        return true;
    } catch (error) {
        console.error('Error connecting to Bluetooth device:', error);
        showNotification('Failed to connect: ' + error.message, 'error');
        bluetoothDevice = null;
        bluetoothCharacteristic = null;
        return false;
    }
}

// Handle disconnection event
function onDisconnected() {
    console.log('Bluetooth device disconnected');
    showNotification('Printer disconnected', 'info');
    bluetoothCharacteristic = null;
    
    // Update UI to show disconnected state
    updateConnectedDeviceUI();
}

// Update UI to show connected device or disconnected state
function updateConnectedDeviceUI() {
    const deviceNameElement = document.getElementById('connected-device-name');
    const connectButton = document.getElementById('connect-printer');
    
    if (deviceNameElement) {
        if (bluetoothDevice && bluetoothDevice.gatt.connected) {
            deviceNameElement.textContent = bluetoothDevice.name;
            deviceNameElement.classList.add('connected');
            
            if (connectButton) {
                connectButton.textContent = 'Change Printer';
            }
        } else {
            deviceNameElement.textContent = 'No printer connected';
            deviceNameElement.classList.remove('connected');
            
            if (connectButton) {
                connectButton.textContent = 'Connect Printer';
            }
        }
    }
}

// Send data to the printer
async function sendToPrinter(data) {
    if (!isBluetoothConnected() || !bluetoothCharacteristic) {
        throw new Error('Printer not connected');
    }
    
    try {
        console.log('Sending data to printer:', data);
        
        // For simple text printing, convert to printer-compatible format
        // This is a simplified example - actual implementation depends on your printer
        const encoder = new TextEncoder();
        
        // Create a printer-friendly string with the data
        const printerText = generatePrinterText(data);
        const bytes = encoder.encode(printerText);
        
        // Send the data in chunks if needed (some printers have limitations)
        const CHUNK_SIZE = 20; // Adjust based on your printer's capabilities
        for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
            const chunk = bytes.slice(i, i + CHUNK_SIZE);
            await bluetoothCharacteristic.writeValue(chunk);
            
            // Small delay between chunks to avoid buffer overflow
            await new Promise(resolve => setTimeout(resolve, 50));
        }
        
        console.log('Data sent successfully');
        return true;
    } catch (error) {
        console.error('Error sending data to printer:', error);
        throw error;
    }
}

// Generate printer-friendly text from data
function generatePrinterText(data) {
    // This function should format the data according to your printer's requirements
    // Basic example for a simple receipt printer
    let text = '';
    
    // Add header
    text += '\x1B\x40'; // Initialize printer
    text += '\x1B\x61\x01'; // Center alignment
    text += 'JAIN TEMPLE\n\n';
    
    // Devotee details
    text += '\x1B\x61\x00'; // Left alignment
    text += `Devotee ID: ${data.devotee_id}\n`;
    if (data.devotee_name) {
        text += `Name: ${data.devotee_name}\n`;
    }
    text += `Date: ${data.date}\n\n`;
    
    // Item selection
    text += '\x1B\x61\x01'; // Center alignment
    text += '\x1B\x45\x01'; // Bold on
    text += `Selected Item: ${data.item}\n`;
    text += '\x1B\x45\x00'; // Bold off
    
    // Footer
    text += '\n\n';
    text += 'Thank you for your visit!\n';
    text += '\x1B\x61\x00'; // Left alignment
    
    // Cut paper
    text += '\x1D\x56\x00'; // Full cut
    
    return text;
}

// Initialize Bluetooth functionality when the page loads
document.addEventListener('DOMContentLoaded', function() {
    const connectButton = document.getElementById('connect-printer');
    if (connectButton) {
        connectButton.addEventListener('click', async function() {
            await connectToPrinter();
        });
    }
    
    // Initialize UI state
    updateConnectedDeviceUI();
});
