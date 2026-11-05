import '../../../../../shared/l10n/app_copy.dart';
import '../../../api/effect_status.dart';
export '../../../api/effect_status.dart' show EffectStatus;

extension EffectStatusLabel on EffectStatus {
  String get label => switch (this) {
    EffectStatus.significant => AppCopy.english.detectableDifference,
    EffectStatus.notDetected => AppCopy.english.noDetectableDifference,
    EffectStatus.marginal => AppCopy.english.marginal,
    EffectStatus.insufficient => AppCopy.english.insufficientData,
  };
}
