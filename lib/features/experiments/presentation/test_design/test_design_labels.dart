import 'package:intl/intl.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../../api/test_design.dart';

extension ExperimentStructureLabels on ExperimentStructure {
  String get label => switch (this) {
    ExperimentStructure.simpleABComparison =>
      AppCopy.english.testHowOneFactorTwoStatesInfluencesPrecision,
    ExperimentStructure.twoFactors =>
      AppCopy.english.testHowTwoFactorsInfluencePrecision,
    ExperimentStructure.threeFactors =>
      AppCopy.english.testHowThreeFactorsInfluencePrecision,
    ExperimentStructure.fourFactors =>
      AppCopy.english.testHowFourFactorsInfluencePrecision,
  };
}

extension SampleSizeLabels on SampleSizeOption {
  String labelFor(ExperimentStructure structure) {
    if (structure == ExperimentStructure.simpleABComparison) {
      final replicates = _formatSampleValue(groupSize);
      final rangesEach = _formatSampleValue(numSets);
      return AppCopy.english.groupSamples(
        '$totalSamples',
        replicates,
        rangesEach,
      );
    }
    return label;
  }

  String get label {
    final replicates = _formatSampleValue(rangesPerGroup);
    return AppCopy.english.replicateSamples(
      '$totalSamples',
      replicates,
      '$groupSize',
    );
  }

  String formOptionLabel(ExperimentStructure structure) {
    if (structure == ExperimentStructure.simpleABComparison) {
      final replicates = _formatSampleValue(groupSize);
      final rangesEach = _formatSampleValue(numSets);
      return AppCopy.english.shortGroupSamples(
        '$totalSamples',
        replicates,
        rangesEach,
      );
    }
    return AppCopy.english.sampleCount('$totalSamples');
  }

  String detectableDifferenceLabel(RiskLevel riskLevel) {
    return formatFraction(detectableDifferenceFor(riskLevel));
  }

  static String formatFraction(double fraction) {
    final percent = fraction * 100;
    final rendered = percent == percent.roundToDouble()
        ? percent.round().toString()
        : percent.toStringAsFixed(1);
    return AppCopy.english.percentBand(rendered);
  }

  static String _formatSampleValue(num value) {
    final asDouble = value.toDouble();
    return asDouble == asDouble.roundToDouble()
        ? asDouble.round().toString()
        : asDouble.toStringAsFixed(1);
  }
}

extension RiskLevelLabels on RiskLevel {
  String get label => NumberFormat.percentPattern(
    AppCopy.english.localeName,
  ).format(probability);
}
