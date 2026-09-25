import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/faq_entry.dart';
import '../../domain/usecases/support_usecases.dart';

class InvoiceHelpState extends Equatable {
  const InvoiceHelpState({
    this.faqs = const [],
    this.loading = true,
    this.failure,
  });

  final List<FaqEntry> faqs;
  final bool loading;
  final Failure? failure;

  @override
  List<Object?> get props => [faqs, loading, failure];
}

/// The first rung of an invoice inquiry: answers the customer can read
/// without talking to anyone.
class InvoiceHelpCubit extends Cubit<InvoiceHelpState> {
  InvoiceHelpCubit(this._getFaqs) : super(const InvoiceHelpState()) {
    load();
  }

  final GetInvoiceFaqs _getFaqs;

  Future<void> load() async {
    emit(InvoiceHelpState(faqs: state.faqs));
    final result = await _getFaqs();
    emit(
      result.fold(
        onErr: (f) =>
            InvoiceHelpState(faqs: state.faqs, loading: false, failure: f),
        onOk: (faqs) => InvoiceHelpState(faqs: faqs, loading: false),
      ),
    );
  }
}
