// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_aws_dynamodb/otel_aws_dynamodb.dart';

/// Traces Aws Dynamodb calls with OpenTelemetry.
///
/// `otel_aws_dynamodb` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Aws Dynamodb call in
/// [tracedAwsDynamoDB]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'aws-dynamodb-example');

  // Traces a Aws Dynamodb call.
  final awsDynamoDBId = await tracedAwsDynamoDB<String>(
    operation: 'create',
    invoke: () async {
      // Make the Aws Dynamodb call here, then report what it returned.
      const id = 'aws_dynamodb_8f3a2c';
      return const AwsDynamoDBCallResult(
          value: id,
          result: AwsDynamoDBResult(
              tableName: 'orders',
              indexName: 'products',
              itemCount: 3,
              scannedCount: 3,
              consumedReadCapacity: 0.5,
              consumedWriteCapacity: 0.5,
              conditional: true,
              region: 'us-east-1',
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedAwsDynamoDB create returned $awsDynamoDBId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAwsDynamoDBInstrumentationAsync.
  await runWithoutAwsDynamoDBInstrumentationAsync(
    () => tracedAwsDynamoDB<String>(
      operation: 'create',
      invoke: () async {
        const id = 'aws_dynamodb_8f3a2c';
        return const AwsDynamoDBCallResult(
            value: id,
            result: AwsDynamoDBResult(
                tableName: 'orders',
                indexName: 'products',
                itemCount: 3,
                scannedCount: 3,
                consumedReadCapacity: 0.5,
                consumedWriteCapacity: 0.5,
                conditional: true,
                region: 'us-east-1',
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
