import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/service_model.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import 'seller_scanner_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final ApiService _apiService = ApiService();
  List<Service> _services = [];
  List<Transaction> _allTransactions = [];
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('az', null);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadServices(),
      _loadAllTransactions(),
    ]);
  }

  Future<void> _loadServices() async {
    try {
      final services = await _apiService.getSellerServices();
      if (mounted) {
        setState(() => _services = services);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _services = []);
      }
    }
  }

  Future<void> _loadAllTransactions() async {
    try {
      final transactions = await _apiService.getSellerTransactions();
      if (mounted) {
        setState(() => _allTransactions = transactions);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _allTransactions = []);
      }
    }
  }

  double get totalAmount {
    return _allTransactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalCashbackGiven {
    return _allTransactions.fold(0.0, (sum, t) => sum + t.cashbackEarned);
  }

  Future<void> _showAddServiceDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Xidmət Əlavə Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Xidmət Adı',
                hintText: 'Məs: Saç kəsimi',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Qiymət (₼)',
                hintText: 'Məs: 50',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv Et'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                return;
              }
              Navigator.pop(context);
              await _addService(
                nameController.text,
                double.parse(priceController.text),
              );
            },
            child: const Text('Əlavə Et'),
          ),
        ],
      ),
    );
  }

  Future<void> _addService(String name, double price) async {
    setState(() {
      _error = null;
      _success = null;
    });

    try {
      const serviceType = 'seller';

      await _apiService.createService(
        name: name,
        price: price,
        cashbackPercentage: 10.0,
        serviceType: serviceType,
      );
      if (mounted) {
        setState(() {
          _success = '✅ Xidmət əlavə edildi!';
        });
      }
      await _loadServices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '❌ Xidmət əlavə edilmədi: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _deleteService(int serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xidməti Sil'),
        content: const Text('Bu xidməti silmək istədiyinizdən əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Xeyr'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bəli, Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteService(serviceId);
        if (mounted) {
          setState(() => _success = '✅ Xidmət silindi!');
        }
        await _loadServices();
      } catch (e) {
        if (mounted) {
          setState(() => _error = '❌ Xidmət silinmədi: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }
    }
  }

  Widget _buildHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser!;
    final firstName = user.fullName.split(' ')[0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Poni Land',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'Xoş gəlmisiniz, $firstName! 👋',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
              onPressed: _loadData,
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Çıxış'),
                    content: const Text('Çıxış etmək istədiyinizdən əminsiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Xeyr'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Bəli'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await authService.logout();
                }
              },
              child: const Text(
                'Çıxış',
                style: TextStyle(color: AppColors.secondaryOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Cəmi',
                            '₼${totalAmount.toStringAsFixed(2)}',
                            AppColors.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Verilən Cashback',
                            '₼${totalCashbackGiven.toStringAsFixed(2)}',
                            AppColors.primaryGradient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error/Success Messages
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFCC3333))),
                      ),
                    if (_success != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEFEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_success!, style: const TextStyle(color: Color(0xFF33CC33))),
                      ),

                    // QR Scanner Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryOrange.withAlpha(77),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SellerScannerScreen()),
                          );
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 28, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'QR Kodu Oxut',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Services Section
                    _buildSectionHeader('Xidmətlərim', onAdd: _showAddServiceDialog),
                    const SizedBox(height: 12),
                    if (_services.isEmpty)
                      _buildEmptyState('Hələ xidmət əlavə edilməyib')
                    else
                      ..._services.map((service) => _buildServiceCard(service)),
                    const SizedBox(height: 24),

                    // All Transactions
                    _buildSectionHeader('Əməliyyatlar'),
                    const SizedBox(height: 12),
                    if (_allTransactions.isEmpty)
                      _buildEmptyState('Hələ əməliyyat edilməyib')
                    else
                      ..._allTransactions.map((transaction) => _buildTransactionCard(transaction)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        if (onAdd != null)
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Əlavə Et'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₼${service.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteService(service.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final timeFormat = DateFormat('HH:mm', 'az');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Xidmət',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Müştəri',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLightGray,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₼${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+₼${transaction.cashbackEarned.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
