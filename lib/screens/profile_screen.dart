import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/body_stats_model.dart';
import '../screens/body_stats_screen.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthUser? _user;
  BodyStats? _stats;
  bool _loading = true;
  bool _notificationsEnabled = true;
  String? _customPhotoPath;

  static const _keyCustomPhoto = 'custom_profile_photo';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    var user = await AuthService.getCurrentUser();
    final stats = await BodyStats.load();
    final prefs = await SharedPreferences.getInstance();
    final notif = prefs.getBool('notifications_enabled') ?? true;
    final customPhoto = prefs.getString(_keyCustomPhoto);

    // Load display name from Firestore (global, syncs across devices)
    try {
      final profile = await FirestoreService.loadProfile();
      if (profile != null && profile['displayName'] != null && user != null) {
        final globalName = profile['displayName'] as String;
        user = AuthUser(
          name: globalName,
          email: user.email,
          photoUrl: user.photoUrl,
          provider: user.provider,
        );
        await prefs.setString('user_name', globalName);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _user = user;
        _stats = stats;
        _notificationsEnabled = notif;
        _customPhotoPath = customPhoto;
        _loading = false;
      });
    }
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color ?? AppColors.navy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openBodyStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BodyStatsScreen()),
    ).then((_) => _loadData());
  }

  Future<void> _showPhoneDialog() async {
    final controller = TextEditingController(text: _stats?.phoneNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Phone Number',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+1 234 567 8900',
            prefixIcon: Icon(Icons.phone, color: AppColors.blue),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final base = _stats ?? BodyStats.defaults();
      final updated = base.copyWith(phoneNumber: result);
      await updated.save();
      setState(() => _stats = updated);
      _showSnack('Phone number updated');
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.navy),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.navy),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_customPhotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Remove Custom Photo', style: TextStyle(color: AppColors.red)),
                onTap: () => Navigator.pop(ctx, null),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null && _customPhotoPath != null) {
      // Remove photo
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCustomPhoto);
      setState(() => _customPhotoPath = null);
      _showSnack('Profile photo removed');
      return;
    }
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 512);
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomPhoto, picked.path);
    setState(() => _customPhotoPath = picked.path);
    _showSnack('Profile photo updated');
  }

  Future<void> _showDisplayNameDialog() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Display Name', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.blue),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      // Sync to Firestore so name shows on all devices
      await FirestoreService.saveProfile({'displayName': result});
      if (!mounted) return;
      setState(() => _user = AuthUser(
        name: result,
        email: _user?.email ?? '',
        photoUrl: _user?.photoUrl,
        provider: _user?.provider ?? AuthProvider.google,
      ));
      _showSnack('Display name updated');
    }
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  // ── Computed helpers ────────────────────────────────────────────────────────

  String _providerLabel() {
    switch (_user?.provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.facebook:
        return 'Facebook';
      default:
        return 'Guest';
    }
  }

  Color _providerColor() {
    switch (_user?.provider) {
      case AuthProvider.google:
        return AppColors.blue;
      case AuthProvider.facebook:
        return AppColors.blue;
      default:
        return AppColors.muted;
    }
  }

  bool get _isSocialLogin =>
      _user?.provider == AuthProvider.google ||
      _user?.provider == AuthProvider.facebook;

  String _initials() {
    final name = _user?.name ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _goalLabel(String goal) {
    switch (goal.toLowerCase()) {
      case 'fat_loss':
        return 'Fat Loss';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'recomp':
        return 'Recomp';
      case 'maintain':
        return 'Maintain';
      default:
        return goal;
    }
  }

  int _daysUntilWeighIn() {
    if (_stats == null || _stats!.weightHistory.isEmpty) return 0;
    final sorted = List<WeightEntry>.from(_stats!.weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    final last = sorted.first;
    final diff = 7 - DateTime.now().difference(last.date).inDays;
    return diff < 0 ? 0 : diff;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.navy,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 16),
                  _buildBodyStatsCard(),
                  const SizedBox(height: 16),
                  _buildAccountSettings(),
                  const SizedBox(height: 16),
                  _buildWeighInCard(),
                  const SizedBox(height: 16),
                  _buildAppInfoCard(),
                  const SizedBox(height: 24),
                  _buildSignOutButton(),
                  const SizedBox(height: 16),
                  _buildSeedDataButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── User Card ────────────────────────────────────────────────────────────────

  Widget _buildUserCard() {
    final photoUrl = _user?.photoUrl;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar with edit button
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _customPhotoPath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_customPhotoPath!),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                            ),
                          )
                        : photoUrl != null && photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                                ),
                              )
                            : _buildInitialsAvatar(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Name with edit
            GestureDetector(
              onTap: _showDisplayNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Email
            if ((_user?.email ?? '').isNotEmpty)
              Text(
                _user!.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            // Provider badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _providerColor().withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _providerColor().withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _user?.provider == AuthProvider.google
                        ? Icons.g_mobiledata
                        : _user?.provider == AuthProvider.facebook
                            ? Icons.facebook
                            : Icons.person_outline,
                    size: 16,
                    color: _providerColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _providerLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _providerColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Body Stats Card ──────────────────────────────────────────────────────────

  Widget _buildBodyStatsCard() {
    final stats = _stats;
    return GestureDetector(
      onTap: _openBodyStats,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.monitor_weight_outlined,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Body Stats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 16),
              if (stats == null)
                const Text(
                  'No body stats set up yet. Tap to add.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                )
              else
                Row(
                  children: [
                    _buildStatChip(
                      label: 'Weight',
                      value: '${stats.weightKg.toStringAsFixed(1)} kg',
                      color: AppColors.blue,
                    ),
                    _buildStatChip(
                      label: 'Height',
                      value: '${stats.heightCm.toStringAsFixed(0)} cm',
                      color: AppColors.purple,
                    ),
                    _buildStatChip(
                      label: 'BMI',
                      value: stats.bmi.toStringAsFixed(1),
                      color: AppColors.orange,
                    ),
                    _buildStatChip(
                      label: 'Goal',
                      value: _goalLabel(stats.goal),
                      color: AppColors.green,
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openBodyStats,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Update Body Stats  →',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Account Settings ─────────────────────────────────────────────────────────

  Widget _buildAccountSettings() {
    final isSocial = _isSocialLogin;
    final providerName = _providerLabel();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Phone Number
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone, color: AppColors.blue, size: 20),
            ),
            title: const Text(
              'Phone Number',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              (_stats?.phoneNumber ?? '').isNotEmpty
                  ? _stats!.phoneNumber
                  : 'Not set',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            trailing: const Icon(Icons.edit_outlined,
                color: AppColors.muted, size: 18),
            onTap: _showPhoneDialog,
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          // Email
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.email_outlined,
                  color: AppColors.navy, size: 20),
            ),
            title: const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_user?.email ?? '').isNotEmpty ? _user!.email : 'No email',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSocial ? AppColors.muted : AppColors.textDark,
                  ),
                ),
                if (isSocial)
                  Text(
                    '(managed by $providerName)',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
              ],
            ),
            enabled: !isSocial,
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          // Display Name / Password
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.orange, size: 20),
            ),
            title: const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              _user?.name ?? 'Not set',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            trailing: const Icon(Icons.edit_outlined, color: AppColors.muted, size: 18),
            onTap: _showDisplayNameDialog,
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          // Notifications
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.green, size: 20),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              _notificationsEnabled ? 'Enabled' : 'Disabled',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            value: _notificationsEnabled,
            activeColor: AppColors.green,
            onChanged: _setNotifications,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Weekly Weigh-in Reminder ──────────────────────────────────────────────────

  Widget _buildWeighInCard() {
    final daysLeft = _daysUntilWeighIn();
    final isDue = daysLeft == 0;
    final bgColor =
        isDue ? AppColors.orange.withOpacity(0.12) : AppColors.blue.withOpacity(0.07);
    final iconColor = isDue ? AppColors.orange : AppColors.blue;
    final borderColor =
        isDue ? AppColors.orange.withOpacity(0.4) : AppColors.blue.withOpacity(0.2);

    return GestureDetector(
      onTap: _openBodyStats,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isDue ? '⏰' : '📅',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDue
                        ? 'Weigh-in Due!'
                        : 'Next Weigh-in: in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDue ? AppColors.orange : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDue
                        ? 'Tap to log your weight now'
                        : 'Weekly weigh-in keeps you on track',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ── App Info ─────────────────────────────────────────────────────────────────

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'App Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline,
                  color: AppColors.navy, size: 20),
            ),
            title: const Text(
              'App Version',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Text(
              '1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business, color: AppColors.purple, size: 20),
            ),
            title: const Text(
              'Developer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Text(
              'Viral Systems',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_outline,
                  color: AppColors.orange, size: 20),
            ),
            title: const Text(
              'Rate This App',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppColors.muted, size: 14),
            onTap: () => _showSnack('Opening Play Store...'),
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.blue, size: 20),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppColors.muted, size: 14),
            onTap: () => _showSnack('Opening privacy policy...'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Sample Data ──────────────────────────────────────────────────────────────

  Widget _buildSeedDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.science_outlined, color: AppColors.muted),
        label: const Text(
          'Load Sample Data (Testing)',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        onPressed: _seedSampleData,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.muted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _seedSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Sample Data'),
        content: const Text('This will add sample tasks, habits, workouts, diet entries, and goals for today so you can test all features. Existing data is kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

    try {
      // Tasks
      final tasks = [
        {'id': 'sample_task_1', 'text': 'Review weekly workout plan', 'priority': 'high', 'done': true, 'date': dateStr},
        {'id': 'sample_task_2', 'text': 'Prepare meal prep for the week', 'priority': 'medium', 'done': false, 'date': dateStr},
        {'id': 'sample_task_3', 'text': 'Read 20 pages of fitness book', 'priority': 'low', 'done': false, 'date': dateStr},
        {'id': 'sample_task_4', 'text': 'Buy protein powder', 'priority': 'medium', 'done': true, 'date': dateStr},
      ];
      for (final t in tasks) {
        await FirestoreService.saveTask(t);
      }

      // Habits
      final yesterday = today.subtract(const Duration(days: 1));
      final yStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}';
      final habits = [
        {'id': 'sample_habit_1', 'name': 'Drink 2L Water', 'icon': '💧', 'streak': 5, 'lastDoneDate': dateStr},
        {'id': 'sample_habit_2', 'name': 'Morning Run', 'icon': '🏃', 'streak': 3, 'lastDoneDate': yStr},
        {'id': 'sample_habit_3', 'name': 'Read Books', 'icon': '📚', 'streak': 7, 'lastDoneDate': dateStr},
        {'id': 'sample_habit_4', 'name': 'Meditate', 'icon': '🧘', 'streak': 2, 'lastDoneDate': ''},
      ];
      for (final h in habits) {
        await FirestoreService.saveHabit(h);
      }

      // Workouts
      final workouts = [
        {'id': 'sample_workout_1', 'type': 'strength', 'label': 'Strength', 'durationMins': 45, 'notes': 'Bench press, squats, deadlifts. Felt strong today!', 'date': dateStr},
        {'id': 'sample_workout_2', 'type': 'cardio', 'label': 'Cardio', 'durationMins': 30, 'notes': '5k run at moderate pace', 'date': dateStr},
      ];
      for (final w in workouts) {
        await FirestoreService.saveWorkout(w);
      }

      // Diet entries
      final meals = [
        {'id': 'sample_meal_1', 'name': 'Oatmeal with Berries', 'mealType': 'breakfast', 'calories': 380.0, 'protein': 12.0, 'carbs': 65.0, 'fat': 7.0, 'date': dateStr},
        {'id': 'sample_meal_2', 'name': 'Chicken Rice Bowl', 'mealType': 'lunch', 'calories': 620.0, 'protein': 45.0, 'carbs': 70.0, 'fat': 12.0, 'date': dateStr},
        {'id': 'sample_meal_3', 'name': 'Whey Protein Shake', 'mealType': 'snack', 'calories': 150.0, 'protein': 25.0, 'carbs': 8.0, 'fat': 2.0, 'date': dateStr},
        {'id': 'sample_meal_4', 'name': 'Salmon with Vegetables', 'mealType': 'dinner', 'calories': 550.0, 'protein': 40.0, 'carbs': 30.0, 'fat': 22.0, 'date': dateStr},
      ];
      for (final m in meals) {
        await FirestoreService.saveMeal(m);
      }

      // Goals
      final goals = [
        {'id': 'sample_goal_1', 'title': 'Lose 5kg body weight', 'category': 'fitness', 'targetValue': 5.0, 'currentValue': 2.5},
        {'id': 'sample_goal_2', 'title': 'Run 100km this month', 'category': 'fitness', 'targetValue': 100.0, 'currentValue': 38.0},
        {'id': 'sample_goal_3', 'title': 'Read 10 books this year', 'category': 'personal', 'targetValue': 10.0, 'currentValue': 4.0},
        {'id': 'sample_goal_4', 'title': 'Save £500 for gym gear', 'category': 'finance', 'targetValue': 500.0, 'currentValue': 150.0},
      ];
      for (final g in goals) {
        await FirestoreService.saveGoal(g);
      }

      // Body stats
      await FirestoreService.saveBodyStats({
        'heightCm': 178.0,
        'weightKg': 80.0,
        'age': 28,
        'gender': 'male',
        'activityLevel': 'moderate',
        'goal': 'fat_loss',
        'bodyFatPercent': 18.0,
        'phoneNumber': '',
        'programStartDate': today.toIso8601String(),
        'weightHistory': [
          {'date': today.subtract(const Duration(days: 28)).toIso8601String(), 'weightKg': 83.5},
          {'date': today.subtract(const Duration(days: 21)).toIso8601String(), 'weightKg': 82.8},
          {'date': today.subtract(const Duration(days: 14)).toIso8601String(), 'weightKg': 81.5},
          {'date': today.subtract(const Duration(days: 7)).toIso8601String(), 'weightKg': 80.9},
          {'date': today.toIso8601String(), 'weightKg': 80.0},
        ],
      });

      if (!mounted) return;
      _showSnack('Sample data loaded! All tabs are now populated.', color: AppColors.green);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to load sample data: $e', color: AppColors.red);
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: AppColors.red),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.red,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: _showSignOutDialog,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.red, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
