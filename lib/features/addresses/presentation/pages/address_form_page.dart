import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';
import '../cubit/address_form_cubit.dart';
import '../widgets/address_form_fields.dart';

/// Adds an address, or edits [editing] and offers to delete it.
///
/// Pops with the saved `Address`, or with nothing after a delete.
class AddressFormPage extends StatelessWidget {
  const AddressFormPage({super.key, this.editing});

  final Address? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressFormCubit>(param1: editing),
      child: _AddressFormView(editing: editing),
    );
  }
}

class _AddressFormView extends StatefulWidget {
  const _AddressFormView({this.editing});

  final Address? editing;

  @override
  State<_AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<_AddressFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _data = AddressFormData(widget.editing?.toNewAddress());

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddressFormCubit>().save(_data.toNewAddress());
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final cubit = context.read<AddressFormCubit>();
    final confirmed = await showConfirmSheet(
      context,
      title: l10n.deleteAddressConfirm,
      message: l10n.deleteAddressConfirmBody,
      confirmLabel: l10n.deleteAddress,
      cancelLabel: l10n.cancel,
    );
    if (confirmed) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.editing != null;
    return BlocConsumer<AddressFormCubit, AddressFormState>(
      listener: (context, state) {
        switch (state.outcome) {
          case AddressSaved(:final address):
            context.pop(address);
          case AddressDeleted():
            context.pop();
          case null:
            break;
        }
        if (state.failure case final failure?) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
        }
      },
      builder: (context, state) => DetailPage(
        title: editing ? l10n.editAddress : l10n.addAddress,
        bottomBar: ActionBar(
          children: [
            ActionButton(
              label: l10n.save,
              loading: state.busy,
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
              AddressFormFields(data: _data),
              if (editing) ...[
                const SizedBox(height: DesignSpace.lg),
                ActionButton(
                  label: l10n.deleteAddress,
                  tone: ActionTone.danger,
                  onPressed: state.busy ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
