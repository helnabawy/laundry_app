import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../error/failures.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureMessage on Failure {
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.networkError,
    UnauthorizedFailure() => l10n.sessionExpired,
    InputFailure(error: InputError.invalidPhone) => l10n.invalidPhone,
    InputFailure(error: InputError.invalidOtp) => l10n.invalidCode,
    InputFailure(error: InputError.requiredField) => l10n.requiredField,
    UnsupportedRoleFailure() => l10n.staffMustUsePortal,
    ServerFailure(:final message?) => message,
    _ => l10n.genericError,
  };
}
