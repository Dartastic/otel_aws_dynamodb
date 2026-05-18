// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_aws_dynamodb/otel_aws_dynamodb.dart';
import 'package:test/test.dart';

void main() {
  group('otel_aws_dynamodb', () {
    test('suppression toggles in zone', () async {
      expect(awsDynamoDBInstrumentationSuppressed(), isFalse);
      await runWithoutAwsDynamoDBInstrumentationAsync(() async {
        expect(awsDynamoDBInstrumentationSuppressed(), isTrue);
      });
      expect(awsDynamoDBInstrumentationSuppressed(), isFalse);
    });

    test('AwsDynamoDBResult fields default null', () {
      const r = AwsDynamoDBResult();
      expect(r.statusCode, isNull);
    });
  });
}
