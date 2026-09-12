import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/flow_header.dart';
import '../cubit/add_address_cubit.dart';
import '../widgets/address_form_fields.dart';

/// Pops with the created `Address`.
class AddAddressPage extends StatelessWidget {
  const AddAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddAddressCubit>(),
      child: const _AddAddressView(),
    );
  }
}

class _AddAddressView extends StatefulWidget {
  const _AddAddressView();

  @override
  State<_AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<_AddAddressView> {
  final _formKey = GlobalKey<FormState>();
  final _data = AddressFormData();

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddAddressCubit>().submit(_data.toNewAddress());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AddAddressCubit, AddAddressState>(
      listener: (context, state) {
        if (state.created != null) context.pop(state.created);
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure!.localized(l10n))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: Column(
          children: [
            FlowHeader(title: l10n.addAddress),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [AddressFormFields(data: _data)],
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
