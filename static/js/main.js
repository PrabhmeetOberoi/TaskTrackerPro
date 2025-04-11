document.addEventListener('DOMContentLoaded', function() {
    // Initialize components
    initSidebar();
    initModals();
    initPrintButton();
    
    // Check if we're on the dashboard page
    if (document.querySelector('#dashboard-charts')) {
        initDashboardCharts();
    }
    
    // Check if we're on the devotee detail page
    if (document.querySelector('#devotee-calendar')) {
        initDevoteeCalendar();
    }
});

// Initialize sidebar/hamburger menu
function initSidebar() {
    const menuToggle = document.querySelector('.hamburger-menu');
    const sidebar = document.querySelector('.sidebar');
    
    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', function() {
            sidebar.classList.toggle('open');
        });
        
        // Close sidebar when clicking outside
        document.addEventListener('click', function(event) {
            if (!sidebar.contains(event.target) && !menuToggle.contains(event.target)) {
                sidebar.classList.remove('open');
            }
        });
    }
}

// Initialize modals
function initModals() {
    const modalTriggers = document.querySelectorAll('[data-toggle="modal"]');
    
    modalTriggers.forEach(trigger => {
        const targetModal = document.querySelector(trigger.dataset.target);
        
        if (targetModal) {
            trigger.addEventListener('click', function() {
                targetModal.style.display = 'flex';
            });
            
            const closeButtons = targetModal.querySelectorAll('.close-modal');
            closeButtons.forEach(button => {
                button.addEventListener('click', function() {
                    targetModal.style.display = 'none';
                });
            });
            
            // Close modal when clicking outside the content
            targetModal.addEventListener('click', function(event) {
                if (event.target === targetModal) {
                    targetModal.style.display = 'none';
                }
            });
        }
    });
}

// Initialize print button functionality
function initPrintButton() {
    const printButton = document.querySelector('#print-label');
    
    if (printButton) {
        printButton.addEventListener('click', async function() {
            // Check if a Bluetooth device is connected
            if (!isBluetoothConnected()) {
                showNotification('No printer connected. Please connect a printer first.', 'error');
                return;
            }
            
            const printData = this.dataset.printData;
            if (!printData) {
                showNotification('No data to print', 'error');
                return;
            }
            
            try {
                const data = JSON.parse(printData);
                await sendToPrinter(data);
                showNotification('Label sent to printer successfully!', 'success');
            } catch (error) {
                console.error('Error printing label:', error);
                showNotification('Failed to print label. Check connection and try again.', 'error');
            }
        });
    }
}

// Initialize dashboard charts
function initDashboardCharts() {
    fetchReportData('daily')
        .then(data => {
            createDailyVisitsChart(data);
        })
        .catch(error => {
            console.error('Error fetching daily report data:', error);
            showNotification('Failed to load daily report data', 'error');
        });
        
    fetchReportData('monthly')
        .then(data => {
            createMonthlyVisitsChart(data);
        })
        .catch(error => {
            console.error('Error fetching monthly report data:', error);
            showNotification('Failed to load monthly report data', 'error');
        });
        
    fetchReportData('yearly')
        .then(data => {
            createYearlyVisitsChart(data);
        })
        .catch(error => {
            console.error('Error fetching yearly report data:', error);
            showNotification('Failed to load yearly report data', 'error');
        });
        
    fetchReportData('devotees')
        .then(data => {
            createDevoteesChart(data);
        })
        .catch(error => {
            console.error('Error fetching devotees report data:', error);
            showNotification('Failed to load devotees report data', 'error');
        });
}

// Fetch report data from the server
async function fetchReportData(reportType) {
    const response = await fetch(`/api/reports/${reportType}`);
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
}

// Create a chart for daily visits
function createDailyVisitsChart(data) {
    const ctx = document.getElementById('daily-visits-chart').getContext('2d');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Daily Visits',
                data: data.values,
                backgroundColor: 'rgba(75, 192, 192, 0.6)',
                borderColor: 'rgba(75, 192, 192, 1)',
                borderWidth: 1
            }]
        },
        options: chartOptions.dailyVisits
    });
}

// Create a chart for monthly visits
function createMonthlyVisitsChart(data) {
    const ctx = document.getElementById('monthly-visits-chart').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Monthly Visits',
                data: data.values,
                backgroundColor: 'rgba(54, 162, 235, 0.6)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderWidth: 2,
                fill: false
            }]
        },
        options: chartOptions.monthlyVisits
    });
}

// Create a chart for yearly visits
function createYearlyVisitsChart(data) {
    const ctx = document.getElementById('yearly-visits-chart').getContext('2d');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Yearly Visits',
                data: data.values,
                backgroundColor: 'rgba(255, 159, 64, 0.6)',
                borderColor: 'rgba(255, 159, 64, 1)',
                borderWidth: 1
            }]
        },
        options: chartOptions.yearlyVisits
    });
}

// Create a chart for devotees
function createDevoteesChart(data) {
    const ctx = document.getElementById('devotees-chart').getContext('2d');
    new Chart(ctx, {
        type: 'pie',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Devotee Visits',
                data: data.values,
                backgroundColor: [
                    'rgba(255, 99, 132, 0.6)',
                    'rgba(54, 162, 235, 0.6)',
                    'rgba(255, 206, 86, 0.6)',
                    'rgba(75, 192, 192, 0.6)',
                    'rgba(153, 102, 255, 0.6)',
                    'rgba(255, 159, 64, 0.6)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)',
                    'rgba(54, 162, 235, 1)',
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)',
                    'rgba(153, 102, 255, 1)',
                    'rgba(255, 159, 64, 1)'
                ],
                borderWidth: 1
            }]
        },
        options: chartOptions.devotees
    });
}

// Initialize devotee calendar
function initDevoteeCalendar() {
    const devoteeId = document.querySelector('#devotee-calendar').dataset.devoteeId;
    if (!devoteeId) return;
    
    fetch(`/api/devotee/${devoteeId}/visits`)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            createDevoteeCalendar(data.visits);
        })
        .catch(error => {
            console.error('Error fetching devotee visits:', error);
            showNotification('Failed to load devotee visit history', 'error');
        });
}

// Create a calendar view for devotee visits
function createDevoteeCalendar(visits) {
    const calendarEl = document.getElementById('devotee-calendar');
    
    // Process visit dates
    const events = visits.map(visit => {
        return {
            title: visit.item,
            start: visit.date,
            backgroundColor: '#28a745',
            borderColor: '#28a745'
        };
    });
    
    // Create calendar (using a placeholder approach since we don't have access to FullCalendar)
    // In a real implementation, we would initialize a proper calendar library here
    const calendar = document.createElement('div');
    calendar.className = 'simple-calendar';
    
    // Group visits by month
    const visitsByMonth = {};
    visits.forEach(visit => {
        const date = new Date(visit.date);
        const monthYear = `${date.getMonth() + 1}-${date.getFullYear()}`;
        if (!visitsByMonth[monthYear]) {
            visitsByMonth[monthYear] = [];
        }
        visitsByMonth[monthYear].push(visit);
    });
    
    // Create a simple calendar representation
    const today = new Date();
    const currentMonth = today.getMonth();
    const currentYear = today.getFullYear();
    
    // Create 12 months (1 year) of calendar
    for (let m = 0; m < 12; m++) {
        const monthIndex = (currentMonth - m + 12) % 12;
        const year = currentMonth - m < 0 ? currentYear - 1 : currentYear;
        const monthName = new Date(year, monthIndex, 1).toLocaleString('default', { month: 'long' });
        
        const monthDiv = document.createElement('div');
        monthDiv.className = 'calendar-month';
        monthDiv.innerHTML = `<h3>${monthName} ${year}</h3>`;
        
        const daysDiv = document.createElement('div');
        daysDiv.className = 'calendar-days';
        
        // Add day headers
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        dayNames.forEach(day => {
            const dayHeader = document.createElement('div');
            dayHeader.className = 'day-header';
            dayHeader.textContent = day;
            daysDiv.appendChild(dayHeader);
        });
        
        // Calculate first day of month and number of days
        const firstDay = new Date(year, monthIndex, 1).getDay();
        const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
        
        // Add empty cells for days before the 1st
        for (let i = 0; i < firstDay; i++) {
            const emptyDay = document.createElement('div');
            emptyDay.className = 'day empty';
            daysDiv.appendChild(emptyDay);
        }
        
        // Add day cells
        const monthYearKey = `${monthIndex + 1}-${year}`;
        const monthVisits = visitsByMonth[monthYearKey] || [];
        
        for (let i = 1; i <= daysInMonth; i++) {
            const dayCell = document.createElement('div');
            dayCell.className = 'day';
            dayCell.textContent = i;
            
            // Check if there's a visit on this day
            const dateString = `${year}-${String(monthIndex + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`;
            const dayVisits = monthVisits.filter(v => v.date === dateString);
            
            if (dayVisits.length > 0) {
                dayCell.classList.add('visited');
                dayCell.title = dayVisits.map(v => v.item).join(', ');
            }
            
            daysDiv.appendChild(dayCell);
        }
        
        monthDiv.appendChild(daysDiv);
        calendar.appendChild(monthDiv);
    }
    
    calendarEl.appendChild(calendar);
}

// Show notification message
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Animation
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
        }, 500);
    }, 5000);
}
