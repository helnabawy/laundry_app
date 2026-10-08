import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../cubit/laundry_cubit.dart';

/// "Ordering from Marina Laundry · Change" on Home. Says nothing when there
/// is only one laundry — there is no choice to report.
class CurrentLaundryRow extends StatelessWidget {
  const CurrentLaundryRow({super.key, this.onChanged});

  /// Called after the customer came back from the picker.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return BlocBuilder<LaundryCubit, LaundryState>(
      bloc: sl<LaundryCubit>(),
      builder: (context, state) {
        final laundry = state.selected;
        if (laundry == null || !state.hasChoice) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpace.gutter),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.laundryOrderingFrom} '),
                      TextSpan(
                        text: laundry.name,
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  style: text.bodyMedium?.copyWith(color: colors.inkSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignSpace.md),
              TintAction(
                label: l10n.change,
                dense: true,
                onPressed: () async {
                  await context.push(Routes.chooseLaundry);
                  onChanged?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
