import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_format.dart';
import '../cubit/session_cubit.dart';

/// Minimal account tab shared by the customer and driver shells: name,
/// phone, language, logout.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.tealSoft,
            child: Text(
              (user?.fullName?.trim().isNotEmpty ?? false)
                  ? user!.fullName!.trim()[0]
                  : '؟',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.tealDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            formatUaePhone(user?.phone ?? ''),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => context.read<SessionCubit>().logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
