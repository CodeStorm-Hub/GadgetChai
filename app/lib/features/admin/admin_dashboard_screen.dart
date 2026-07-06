import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/admin_repository.dart';
import '../../core/supabase/rental_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _adminRepository = AdminRepository();
  final _rentalRepository = RentalRepository();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // DB States
  List<Map<String, dynamic>> _devicesLedger = [];
  List<Map<String, dynamic>> _kycQueue = [];
  List<Map<String, dynamic>> _fulfillmentOrders = [];

  // Metrics
  double _mrr = 285000;
  double _utilization = 84.5;
  int _activeDefaults = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devicesLedger = await _adminRepository.fetchDeviceLedger();
      final kycQueue = await _adminRepository.fetchPendingKycReviews();
      final fulfillmentOrders = await _rentalRepository.fetchAllRentals();
      final mrr = await _rentalRepository.calculateMrr();

      final rentedCount = devicesLedger.where((d) => d['status'] == 'rented').length;
      final totalCount = devicesLedger.isEmpty ? 1 : devicesLedger.length;
      final utilization = (rentedCount / totalCount) * 100;

      setState(() {
        _devicesLedger = devicesLedger;
        _kycQueue = kycQueue;
        _fulfillmentOrders = fulfillmentOrders;
        _mrr = mrr;
        _utilization = utilization;
        _activeDefaults = fulfillmentOrders
            .where((r) => r['status'] == 'active' && (r['security_deposit'] as num? ?? 0) > 0)
            .length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admin data: $e';
        _isLoading = false;
      });
    }
  }

  // Action methods
  Future<void> _updateKycStatus(String reviewId, String status) async {
    try {
      await _adminRepository.updateKycStatus(reviewId, status);
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KYC status updated: $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update KYC: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _updateCondition(String itemId, String grade) async {
    try {
      await _adminRepository.updateDeviceCondition(itemId, grade);
      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update condition: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _verifyOtpHandover(String rentalId, String enteredOtp, String correctOtp) async {
    if (enteredOtp.trim() != correctOtp.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: OTP mismatch.'), backgroundColor: context.colors.error),
      );
      return;
    }

    try {
      await _adminRepository.activateRental(rentalId);
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Handover completed. Rental activated!'), backgroundColor: context.colors.secondary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to activate rental: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: GcEmptyState(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin data unavailable',
          message: _errorMessage,
          actionLabel: 'Retry',
          onAction: _loadAdminData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt, color: context.colors.primary, size: 28),
            const SizedBox(width: 8),
            Text('GadgetChai Admin', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.colors.onSurfaceVariant),
            onPressed: _loadAdminData,
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) => ButtonGroupM3E(
                selection: true,
                selectedIndex: _tabController.index,
                expanded: true,
                type: ButtonGroupM3EType.connected,
                style: ButtonM3EStyle.tonal,
                size: ButtonGroupM3ESize.sm,
                overflow: ButtonGroupM3EOverflow.scroll,
                actions: [
                  ButtonGroupM3EAction(
                    icon: const Icon(Icons.bar_chart, size: 18),
                    label: const Text('Analytics'),
                    onPressed: () => _tabController.animateTo(0),
                  ),
                  ButtonGroupM3EAction(
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Ledger'),
                    onPressed: () => _tabController.animateTo(1),
                  ),
                  ButtonGroupM3EAction(
                    icon: const Icon(Icons.assignment_ind, size: 18),
                    label: const Text('KYC'),
                    onPressed: () => _tabController.animateTo(2),
                  ),
                  ButtonGroupM3EAction(
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Fulfillment'),
                    onPressed: () => _tabController.animateTo(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(textTheme),
          _buildLedgerTab(textTheme),
          _buildKycQueueTab(textTheme),
          _buildFulfillmentTab(textTheme),
        ],
      ),
    );
  }

  // TAB 1: Analytics & charts
  Widget _buildAnalyticsTab(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat HUD cards
          Row(
            children: [
              _buildStatCard('Monthly Recurring Revenue (MRR)', '৳${_mrr.toInt()}', Icons.trending_up, context.colors.primary),
              const SizedBox(width: 16),
              _buildStatCard('Inventory Utilization Rate', '${_utilization.toStringAsFixed(1)}%', Icons.widgets, context.colors.secondary),
              const SizedBox(width: 16),
              _buildStatCard('Active Payment Defaults', '$_activeDefaults Accounts', Icons.warning_amber, context.colors.error),
            ],
          ),
          const SizedBox(height: 36),

          // MRR Line Chart
          Text('MRR Collection Growth (6-Month)', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GcCard(
            padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
            child: SizedBox(
              height: 276,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) =>
                        FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (val.toInt() >= 0 && val.toInt() < months.length) {
                            return Text(months[val.toInt()], style: context.text.labelSmall);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 150000),
                        FlSpot(1, 180000),
                        FlSpot(2, 210000),
                        FlSpot(3, 230000),
                        FlSpot(4, 260000),
                        FlSpot(5, 285000),
                      ],
                      isCurved: true,
                      color: context.colors.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Default warnings alerts list
          Text('Alert center: bKash Balance Defaults', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: context.colors.error)),
          const SizedBox(height: 12),
          GcCard(
            color: context.colors.errorContainer.withValues(alpha: 0.35),
            child: Column(
              children: [
                _buildDefaultAlertRow('+8801711223344 (MacBook Pro) - Insufficient balance. Sent SMS Warning.', '1 day ago'),
                Divider(color: context.colors.outlineVariant),
                _buildDefaultAlertRow('+8801911990088 (Sony Alpha) - Billing collection failed. Attempt 2 scheduled.', '3 hours ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Device inventory ledger
  Widget _buildLedgerTab(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Master Hardware Asset Ledger', style: textTheme.displayMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Device Model')),
              DataColumn(label: Text('Serial/IMEI')),
              DataColumn(label: Text('Grade')),
              DataColumn(label: Text('Cost')),
              DataColumn(label: Text('Total Revenue')),
              DataColumn(label: Text('Profitability')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _devicesLedger.map((item) {
              final deviceName = item['devices']?['name'] ?? 'Unknown';
              final cost = (item['purchase_cost'] as num).toDouble();
              final rev = (item['cumulative_revenue'] as num?)?.toDouble() ?? 0.0;
              final net = rev - cost;
              final netColor = net >= 0 ? context.colors.secondary : context.colors.error;

              return DataRow(cells: [
                DataCell(Text(deviceName)),
                DataCell(Text(item['serial_number'])),
                DataCell(
                  DropdownButton<String>(
                    value: item['condition_grade'],
                    dropdownColor: context.colors.surfaceContainerLow,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Grade A', child: Text('Grade A')),
                      DropdownMenuItem(value: 'Grade B', child: Text('Grade B')),
                      DropdownMenuItem(value: 'Grade C', child: Text('Grade C')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateCondition(item['id'], val);
                      }
                    },
                  ),
                ),
                DataCell(Text('৳${cost.toInt()}')),
                DataCell(Text('৳${rev.toInt()}')),
                DataCell(Text(
                  '${net >= 0 ? "+" : ""}৳${net.toInt()}',
                  style: TextStyle(color: netColor, fontWeight: FontWeight.bold),
                )),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.history, size: 20),
                    onPressed: () {},
                    tooltip: 'Lifecycle History',
                  ),
                ),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // TAB 3: KYC Manual Review Queue
  Widget _buildKycQueueTab(TextTheme textTheme) {
    if (_kycQueue.isEmpty) {
      return const GcEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'KYC queue clear',
        message: 'No profiles are waiting for manual review.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _kycQueue.length,
      itemBuilder: (context, index) {
        final review = _kycQueue[index];
        final profile = review['profiles'];
        final score = ((review['similarity_score'] as num?)?.toDouble() ?? 0.0) * 100;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShapes.md)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?['full_name'] ?? 'Sheikh Kamaluddin', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Phone: ${profile?['phone'] ?? "N/A"} • NID: ${review['nid_number']}', style: textTheme.bodyMedium),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: score > 70
                            ? context.colors.secondaryContainer.withValues(alpha: 0.5)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Match: ${score.toInt()}%',
                        style: TextStyle(
                          color: score > 70 ? context.colors.secondary : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                
                // Photo review viewports
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NID Card Document (Front)',
                            style: textTheme.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              review['nid_front_url'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 180,
                                color: context.colors.outlineVariant,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selfie Check (Liveness Portrait)',
                            style: textTheme.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              review['selfie_url'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 180,
                                color: context.colors.outlineVariant,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Approval actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateKycStatus(review['id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                      ),
                      child: const Text('Reject Profile'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _updateKycStatus(review['id'], 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.secondary,
                        foregroundColor: context.colors.onSecondary,
                      ),
                      child: const Text('Approve Identity'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 4: Logistics Fulfillment Board
  Widget _buildFulfillmentTab(TextTheme textTheme) {
    final awaitingDispatch = _fulfillmentOrders.where((o) => o['status'] == 'awaiting_dispatch').toList();
    final inTransit = _fulfillmentOrders.where((o) => o['status'] == 'in_transit').toList();
    final active = _fulfillmentOrders.where((o) => o['status'] == 'active').toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: Awaiting Dispatch
          Expanded(
            child: _buildKanbanColumn('Awaiting Dispatch', awaitingDispatch, textTheme, (order) {
              return ElevatedButton(
                onPressed: () async {
                  try {
                    await _adminRepository.dispatchRental(
                      order['id'] as String,
                      '${1000 + DateTime.now().millisecond}',
                    );
                    await _loadAdminData();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dispatch failed: $e'), backgroundColor: context.colors.error),
                    );
                  }
                },
                child: const Text('Dispatch Order'),
              );
            }),
          ),
          const SizedBox(width: 16),

          // Column 2: In Transit
          Expanded(
            child: _buildKanbanColumn('In Transit', inTransit, textTheme, (order) {
              final otpController = TextEditingController();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'Rider OTP Check', counterText: ""),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _verifyOtpHandover(order['id'], otpController.text, order['delivery_otp']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.secondary,
                      foregroundColor: context.colors.onSecondary,
                    ),
                    child: const Text('Complete Handover'),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 16),

          // Column 3: Active Rentals
          Expanded(
            child: _buildKanbanColumn('Active Rentals', active, textTheme, (order) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Collection cycle active',
                  style: TextStyle(
                    color: context.colors.onSecondaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<Map<String, dynamic>> items, TextTheme textTheme, Widget Function(Map<String, dynamic>) actionBuilder) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              CircleAvatar(
                radius: 12,
                backgroundColor: scheme.outlineVariant,
                child: Text(
                  '${items.length}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final order = items[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['devices']?['name'] ?? 'Device', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${order['profiles']?['full_name'] ?? "Guest"}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        'Phone: ${order['profiles']?['phone'] ?? "N/A"}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      actionBuilder(order),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GcCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.labelMedium),
                  const SizedBox(height: 6),
                  Text(value, style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAlertRow(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: context.colors.onSurface)),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
