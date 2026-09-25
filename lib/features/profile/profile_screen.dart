import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_config.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Profile & Backend Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      user?.role.displayName ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Info items
                  _buildProfileRow('Account ID', user?.id ?? 'N/A', Icons.badge_outlined),
                  if (user?.workerId != null)
                    _buildProfileRow('Worker ID', user!.workerId!, Icons.handyman_outlined),
                  _buildProfileRow('Department', user?.department ?? 'N/A', Icons.domain_rounded),
                  _buildProfileRow('Zone / Jurisdiction', user?.zone ?? 'Citywide', Icons.map_outlined),
                  _buildProfileRow('Phone', user?.phoneNumber ?? 'N/A', Icons.phone_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Backend Connectivity Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.dns_rounded, size: 18, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Backend & Database Infrastructure',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow('API Endpoint', ApiConfig.baseUrl, Icons.link_rounded),
                  _buildProfileRow('Database', 'Supabase PostgreSQL', Icons.storage_rounded),
                  _buildProfileRow('Auth Protocol', 'JWT Bearer Access Tokens', Icons.security_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Role Switch Card (Authenticates against real backend)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Switch Demo Account (Real API Auth)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seamlessly switch accounts and verify cross-dashboard synchronization backed by PostgreSQL.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: user?.role.isOfficer == true
                              ? null
                              : () async {
                                  await ref.read(authStateProvider.notifier).switchDemoAccount(UserRole.municipalOfficer);
                                  if (context.mounted) {
                                    context.go('/officer');
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user?.role.isOfficer == true ? AppColors.primaryNavy.withValues(alpha: 0.08) : null,
                          ),
                          child: const Text('Officer View', style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: user?.role.isWorker == true
                              ? null
                              : () async {
                                  await ref.read(authStateProvider.notifier).switchDemoAccount(UserRole.fieldWorker);
                                  if (context.mounted) {
                                    context.go('/worker');
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user?.role.isWorker == true ? AppColors.primaryNavy.withValues(alpha: 0.08) : null,
                          ),
                          child: const Text('Worker View', style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            OutlinedButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.priorityCritical, width: 1.5),
                foregroundColor: AppColors.priorityCritical,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Sign Out of WaterWatch', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metadata footer
            const Text(
              'WaterWatch IoT Smart City Platform v1.0.0 • Supabase Connected',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
