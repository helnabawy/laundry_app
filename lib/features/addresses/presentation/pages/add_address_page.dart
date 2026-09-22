import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
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
        if (state.created case final created?) context.pop(created);
        if (state.failure case final failure?) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
        }
      },
      builder: (context, state) => DetailPage(
        title: l10n.addAddress,
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
            children: [AddressFormFields(data: _data)],
          ),
        ),
      ),
    );
  }
}
