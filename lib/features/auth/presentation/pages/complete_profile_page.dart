import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../addresses/presentation/widgets/address_form_fields.dart';
import '../cubit/complete_profile_cubit.dart';
import '../cubit/session_cubit.dart';

/// First login only: the first pickup address (step 1.4). The name was typed
/// on the login screen; it is asked here only if that didn't save.
class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompleteProfileCubit>(),
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = AddressFormData();

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  // Read once: the field shouldn't vanish mid-edit when the session updates.
  late final _askName = switch (context.read<SessionCubit>().state) {
    SessionAuthenticated(:final user) => user.fullName?.trim().isEmpty ?? true,
    _ => true,
  };

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileCubit>().submit(
      fullName: _askName ? _name.text : null,
      address: _address.toNewAddress(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state.user case final user?) {
          context.read<SessionCubit>().userUpdated(user);
        }
        if (state.failure case final failure?) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
        }
      },
      builder: (context, state) => FlowPage(
        title: l10n.completeProfile,
        subtitle: _askName
            ? l10n.completeProfileSubtitle
            : l10n.completeProfileAddressSubtitle,
        // Going back means using a different number.
        onBack: context.read<SessionCubit>().logout,
        bottomBar: ActionBar(
          children: [
            ActionButton(
              label: l10n.save,
              loading: state.submitting,
              onPressed: _submit,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignSpace.gutter,
              DesignSpace.xxl,
              DesignSpace.gutter,
              DesignSpace.huge,
            ),
            children: [
              if (_askName) ...[
                LabelField(
                  controller: _name,
                  label: l10n.fullName,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                StampHeading(l10n.addressTitle),
                const SizedBox(height: DesignSpace.sm),
              ],
              AddressFormFields(data: _address),
            ],
          ),
        ),
      ),
    );
  }
}
