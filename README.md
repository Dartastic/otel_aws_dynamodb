# otel_aws_dynamodb

Dartastic OpenTelemetry bridge for AWS DynamoDB (managed NoSQL).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_aws_dynamodb/otel_aws_dynamodb.dart';

await tracedAwsDynamoDB<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return AwsDynamoDBCallResult(value: r, result: AwsDynamoDBResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutAwsDynamoDBInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
