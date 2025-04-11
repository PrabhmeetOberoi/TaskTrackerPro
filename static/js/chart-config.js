// Chart.js configuration options
const chartOptions = {
    // Options for daily visits chart
    dailyVisits: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Number of Visits'
                },
                ticks: {
                    precision: 0
                }
            },
            x: {
                title: {
                    display: true,
                    text: 'Day'
                }
            }
        },
        plugins: {
            title: {
                display: true,
                text: 'Daily Visits'
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return `Visits: ${context.raw}`;
                    }
                }
            }
        }
    },
    
    // Options for monthly visits chart
    monthlyVisits: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Number of Visits'
                },
                ticks: {
                    precision: 0
                }
            },
            x: {
                title: {
                    display: true,
                    text: 'Month'
                }
            }
        },
        plugins: {
            title: {
                display: true,
                text: 'Monthly Visits'
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return `Visits: ${context.raw}`;
                    }
                }
            }
        }
    },
    
    // Options for yearly visits chart
    yearlyVisits: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Number of Visits'
                },
                ticks: {
                    precision: 0
                }
            },
            x: {
                title: {
                    display: true,
                    text: 'Year'
                }
            }
        },
        plugins: {
            title: {
                display: true,
                text: 'Yearly Visits'
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return `Visits: ${context.raw}`;
                    }
                }
            }
        }
    },
    
    // Options for devotees chart
    devotees: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: {
                display: true,
                text: 'Top Devotees by Visits'
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return `${context.label}: ${context.raw} visits`;
                    }
                }
            },
            legend: {
                position: 'right'
            }
        }
    },
    
    // Options for item distribution chart
    items: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            title: {
                display: true,
                text: 'Item Distribution'
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        return `${context.label}: ${context.raw} times`;
                    }
                }
            },
            legend: {
                position: 'right'
            }
        }
    }
};
