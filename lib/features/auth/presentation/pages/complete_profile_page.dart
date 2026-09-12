import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/flow_header.dart';
import '../../../../core/widgets/labeled_rows.dart';
import '../../../addresses/presentation/widgets/address_form_fields.dart';
import '../cubit/complete_profile_cubit.dart';
import '../cubit/session_cubit.dart';

/// First login only: name + first address (step 1.4).
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompleteProfileCubit>().submit(
      fullName: _name.text,
      address: _address.toNewAddress(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state.user != null) {
          context.read<SessionCubit>().userUpdated(state.user!);
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure!.localized(l10n))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: Column(
          children: [
            FlowHeader(
              title: l10n.completeProfile,
              subtitle: l10n.completeProfileSubtitle,
              // Going back means using a different number.
              onBack: context.read<SessionCubit>().logout,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(labelText: l10n.fullName),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.requiredField
                          : null,
                    ),
                    const SizedBox(height: 28),
                    SectionTitle(l10n.addressTitle),
                    AddressFormFields(data: _address),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomActions(
          children: [
            PrimaryButton(
              label: l10n.save,
              loading: state.submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
