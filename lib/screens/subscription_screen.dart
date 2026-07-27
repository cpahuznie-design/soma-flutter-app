import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';
import '../services/auth_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentPlan = 'Free';
  String _selectedPlan = 'Premium';

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    final plan = await AuthService.getUserPlan();
    setState(() {
      _currentPlan = plan;
    });
  }

  Future<void> _subscribe(String plan) async {
    await AuthService.setUserPlan(plan);
    setState(() {
      _currentPlan = plan;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil upgrade ke plan $plan!'),
          backgroundColor: SomaTheme.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: Text('Upgrade', style: TextStyle(color: SomaTheme.white, fontWeight: FontWeight.w700)),
        backgroundColor: SomaTheme.bgDeep,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Text('Pilih Plan', style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _buildPlanCard(
            'Free',
            'Rp 0',
            '/bln',
            null,
            [
              'Dashboard + brain score',
              'Sleep tracker',
              '1 breathing technique (4-7-8)',
              '1 memory game',
              'Basic analytics',
            ],
            SomaTheme.textMuted,
            false,
          ),
          const SizedBox(height: 14),
          _buildPlanCard(
            'Premium',
            'Rp 49.000',
            '/bln',
            'Popular',
            [
              'Semua breathing techniques (4 teknik)',
              'Sleep stories (10+ cerita)',
              'Soundscape generator',
              'All memory games (4 game)',
              'AI Brain Coach basic',
              'No ads',
              'Trial 7 hari gratis',
            ],
            SomaTheme.tealBright,
            true,
          ),
          const SizedBox(height: 14),
          _buildPlanCard(
            'Pro',
            'Rp 99.000',
            '/bln',
            'Best Value',
            [
              'Semua fitur Premium',
              'N-Back training',
              'Chess puzzles (100+)',
              'Family brain health (5 anggota)',
              'AI Brain Coach advanced',
              'Smart schedule',
              'Priority support',
            ],
            SomaTheme.purple,
            false,
          ),
          const SizedBox(height: 24),
          _buildTrialButtons(),
          const SizedBox(height: 20),
          _buildFeatureLock(),
          const SizedBox(height: 20),
          _buildPaymentInfo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SomaTheme.teal.withOpacity(0.15), SomaTheme.purple.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [SomaTheme.teal, SomaTheme.purple]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: SomaTheme.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text('SOMA', style: TextStyle(color: SomaTheme.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4)),
          const SizedBox(height: 8),
          Text('Upgrade untuk Buka Semua Fitur',
              style: TextStyle(color: SomaTheme.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Rawat otak Anda dengan fitur premium',
              style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String name,
    String price,
    String period,
    String? badge,
    List<String> features,
    Color accentColor,
    bool isHighlight,
  ) {
    final isCurrent = _currentPlan == name;
    final isSelected = _selectedPlan == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SomaTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isHighlight && isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: isSelected
                          ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(name, style: TextStyle(color: SomaTheme.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge, style: TextStyle(color: SomaTheme.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                if (isCurrent && badge == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SomaTheme.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Aktif', style: TextStyle(color: SomaTheme.tealBright, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: TextStyle(color: accentColor, fontSize: 28, fontWeight: FontWeight.w800)),
                Text(period, style: TextStyle(color: SomaTheme.textMuted, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: accentColor.withOpacity(0.15), height: 1),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: accentColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: TextStyle(color: SomaTheme.text, fontSize: 14))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _currentPlan == 'Premium' || _currentPlan == 'Pro'
                ? null
                : () => _subscribe('Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SomaTheme.teal,
              foregroundColor: SomaTheme.white,
              disabledBackgroundColor: SomaTheme.teal.withOpacity(0.3),
              disabledForegroundColor: SomaTheme.textMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Mulai Trial Gratis 7 Hari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _currentPlan == 'Pro' ? null : () => _subscribe('Pro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SomaTheme.purple,
              foregroundColor: SomaTheme.white,
              disabledBackgroundColor: SomaTheme.purple.withOpacity(0.3),
              disabledForegroundColor: SomaTheme.textMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Langganan Pro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => _subscribe('Lifetime'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SomaTheme.lavender,
              side: BorderSide(color: SomaTheme.lavender.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Bayar Sekali Rp 299.000 (Lifetime)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureLock() {
    final lockedFeatures = [
      {'name': 'N-Back Training', 'icon': Icons.memory},
      {'name': 'Chess Puzzles (100+)', 'icon': Icons.extension},
      {'name': 'Family Brain Health', 'icon': Icons.family_restroom},
      {'name': 'AI Brain Coach Advanced', 'icon': Icons.auto_awesome},
      {'name': 'Smart Schedule', 'icon': Icons.schedule},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: SomaTheme.purple, size: 20),
              const SizedBox(width: 8),
              Text('Fitur Terkunci', style: TextStyle(color: SomaTheme.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Upgrade untuk membuka fitur ini', style: TextStyle(color: SomaTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 14),
          ...lockedFeatures.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(f['icon'] as IconData, color: SomaTheme.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f['name'] as String, style: TextStyle(color: SomaTheme.textMuted, fontSize: 14))),
                    Icon(Icons.lock_outline, color: SomaTheme.purple.withOpacity(0.6), size: 18),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SomaTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SomaTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: SomaTheme.tealBright, size: 20),
              const SizedBox(width: 8),
              Text('Info Pembayaran', style: TextStyle(color: SomaTheme.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.account_balance_wallet, 'Pembayaran via Midtrans (QRIS, e-wallet, credit card)'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.cancel_outlined, 'Bisa cancel kapan saja'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.verified, 'Tanpa biaya tersembunyi'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SomaTheme.tealBright, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: SomaTheme.textMuted, fontSize: 13))),
      ],
    );
  }
}