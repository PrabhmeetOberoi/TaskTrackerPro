import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _dailyReportData = {'labels': [], 'values': []};
  Map<String, dynamic> _monthlyReportData = {'labels': [], 'values': []};
  Map<String, dynamic> _devoteeReportData = {'labels': [], 'values': []};
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load dashboard statistics
      final stats = await _apiService.getDashboardStats();
      
      // Load report data
      final dailyReport = await _apiService.getDailyReport();
      final monthlyReport = await _apiService.getMonthlyReport();
      final devoteesReport = await _apiService.getDevoteesReport();
      
      setState(() {
        _stats = stats;
        _dailyReportData = dailyReport;
        _monthlyReportData = monthlyReport;
        _devoteeReportData = devoteesReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildDailyChart(),
                    const SizedBox(height: 24),
                    _buildMonthlyChart(),
                    const SizedBox(height: 24),
                    _buildDevoteesChart(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        tooltip: 'Go to Devotee Check-in',
        child: const Icon(Icons.people),
      ),
    );
  }
  
  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Visits', _stats['totalVisits'] ?? 0, Icons.show_chart),
        _buildStatCard('Today\'s Visits', _stats['dailyVisits'] ?? 0, Icons.today),
        _buildStatCard('This Month', _stats['monthlyVisits'] ?? 0, Icons.calendar_month),
        _buildStatCard('Total Devotees', _stats['totalDevotees'] ?? 0, Icons.people),
      ],
    );
  }
  
  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Visits (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _dailyReportData['labels'].isEmpty
                  ? const Center(child: Text('No data available'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxValue(_dailyReportData['values']) * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.grey[800]!,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < _dailyReportData['labels'].length) {
                                  final date = DateTime.parse(_dailyReportData['labels'][value.toInt()]);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MM/dd').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), 
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _dailyReportData['values'].length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _dailyReportData['values'][index].toDouble(),
                                color: Theme.of(context).primaryColor,
                                width: 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Visits (Last 12 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _monthlyReportData['labels'].isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.grey[800]!,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < _monthlyReportData['labels'].length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _monthlyReportData['labels'][value.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), 
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              _monthlyReportData['values'].length,
                              (index) => FlSpot(
                                index.toDouble(),
                                _monthlyReportData['values'][index].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                            ),
                          ),
                        ],
                        minY: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDevoteesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Devotees',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: _devoteeReportData['labels'].isEmpty
                  ? const Center(child: Text('No data available'))
                  : ListView.builder(
                      itemCount: _devoteeReportData['labels'].length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              (index + 1).toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(_devoteeReportData['labels'][index]),
                          trailing: Container(
                            width: 80,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${_devoteeReportData['values'][index]} visits',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _getMaxValue(List<dynamic> values) {
    if (values.isEmpty) return 10.0;
    double max = 0;
    for (var value in values) {
      if (value > max) max = value.toDouble();
    }
    return max == 0 ? 10.0 : max;
  }
}