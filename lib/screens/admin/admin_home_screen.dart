import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<Transaction> _allTransactions = [];
  bool _loading = true;
  bool _loadingTransactions = true;
  String? _error;
  late TabController _tabController;
  String _cashbackPercentage = '10';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('az', null);
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadAllTransactions();
    _loadCashbackPercentage();
  }

  Future<void> _loadCashbackPercentage() async {
    try {
      final percentage = await _apiService.getCashbackPercentage();
      setState(() {
        _cashbackPercentage = percentage;
      });
    } catch (e) {
      // Use default 10% if fails
      setState(() {
        _cashbackPercentage = '10';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _apiService.getAllUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAllTransactions() async {
    setState(() {
      _loadingTransactions = true;
    });

    try {
      final transactions = await _apiService.getAllTransactions();
      setState(() {
        _allTransactions = transactions;
        _loadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _allTransactions = [];
        _loadingTransactions = false;
      });
    }
  }

  double get totalRevenue {
    return _allTransactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalCashback {
    return _allTransactions.fold(0.0, (sum, t) => sum + t.cashbackEarned);
  }

  Future<void> _resetCashback(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cashback Sıfırla'),
        content: Text('${user.fullName} adlı istifadəçinin ₼${user.balance.toStringAsFixed(2)} cashback balansı sıfırlanacaq. Əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İmtina'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sıfırla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.resetUserCashback(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user.fullName} cashback balansı sıfırlandı'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Xəta: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(User user, String newRole) async {
    try {
      await _apiService.updateUserRole(user.id, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${user.fullName} rolü ${_getRoleDisplayName(newRole)} olaraq dəyişdirildi'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Rol dəyişdirilərkən xəta: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'user':
        return 'İstifadəçi';
      case 'seller_barber':
        return 'Satıcı - Bərbər';
      case 'seller_zoopark':
        return 'Satıcı - Zoopark';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'seller_barber':
        return AppColors.primaryBlue;
      case 'seller_zoopark':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'seller_barber':
        return Icons.cut;
      case 'seller_zoopark':
        return Icons.pets;
      default:
        return Icons.person;
    }
  }

  void _showRoleChangeDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.fullName} rolunu dəyiş'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.grey),
              title: const Text('İstifadəçi'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, 'user');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cut, color: AppColors.primaryBlue),
              title: const Text('Satıcı - Bərbər'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, 'seller_barber');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.green),
              title: const Text('Satıcı - Zoopark'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, 'seller_zoopark');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, 'admin');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İmtina'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);

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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Poni Land',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'Admin Paneli 👨‍💼',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
              onPressed: _loadUsers,
            ),
            TextButton(
              onPressed: () => authService.logout(),
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
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textGray,
              indicatorColor: AppColors.primaryBlue,
              tabs: const [
                Tab(text: 'İstifadəçilər'),
                Tab(text: 'Tarixçə'),
                Tab(text: 'Tənzimləmələr'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildHistoryTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Xəta: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Yenidən cəhd et'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.role),
                child: Icon(_getRoleIcon(user.role), color: Colors.white),
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(user.email),
                  Text(user.phoneNumber ?? 'Telefon yoxdur'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRoleDisplayName(user.role),
                          style: TextStyle(
                            color: _getRoleColor(user.role),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₼${user.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    tooltip: 'Cashback sıfırla',
                    onPressed: () => _resetCashback(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                    onPressed: () => _showRoleChangeDialog(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllTransactions,
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
                    'Ümumi Gəlir',
                    '₼${totalRevenue.toStringAsFixed(2)}',
                    AppColors.primaryGradient,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Verilən Cashback',
                    '₼${totalCashback.toStringAsFixed(2)}',
                    AppColors.orangeGradient,
                    Icons.card_giftcard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Əməliyyat Sayı',
                    '${_allTransactions.length}',
                    AppColors.primaryGradient,
                    Icons.receipt_long,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transactions List
            const Text(
              'Bütün Əməliyyatlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            if (_allTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const Text(
                  'Hələ əməliyyat edilməyib',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._allTransactions.map((transaction) => _buildTransactionCard(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Gradient gradient, IconData icon) {
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
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 8),
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

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'az');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transaction.description ?? 'Xidmət',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              Text(
                '₼${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(transaction.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
              Text(
                'Cashback: ₼${transaction.cashbackEarned.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
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

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cashback Faizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Müştərilərə verilən cashback faizini buradan tənzimləyə bilərsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _cashbackPercentage),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cashback Faizi (%)',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _cashbackPercentage = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _updateCashbackPercentage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      child: const Text('Yadda Saxla'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cari dəyər: $_cashbackPercentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCashbackPercentage() async {
    // Validate percentage
    final percentage = double.tryParse(_cashbackPercentage);
    if (percentage == null || percentage < 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Xəta: Faiz 0 ilə 100 arasında olmalıdır'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    try {
      await _apiService.updateCashbackPercentage(_cashbackPercentage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cashback faizi $_cashbackPercentage% olaraq yeniləndi'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Xəta: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
