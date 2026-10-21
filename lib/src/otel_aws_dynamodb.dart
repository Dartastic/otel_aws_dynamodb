// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_aws_dynamodb_suppression.dart';

class AwsDynamoDBResult {
  /// Creates a result.
  const AwsDynamoDBResult({
    this.tableName,
    this.indexName,
    this.itemCount,
    this.scannedCount,
    this.consumedReadCapacity,
    this.consumedWriteCapacity,
    this.conditional,
    this.region,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? tableName;
  final String? indexName;
  final int? itemCount;
  final int? scannedCount;
  final double? consumedReadCapacity;
  final double? consumedWriteCapacity;
  final bool? conditional;
  final String? region;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class AwsDynamoDBCallResult<T> {
  /// Creates a call result.
  const AwsDynamoDBCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final AwsDynamoDBResult? result;
}

Future<T> tracedAwsDynamoDB<T>({
  required String operation,
  required Future<AwsDynamoDBCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (awsDynamoDBInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_aws_dynamodb');
  final span = t.startSpan('dynamodb $operation', kind: SpanKind.client);
  try {
    span.addAttributes(OTelAPI.attributes(
        [OTelAPI.attributeString('db.system.name', 'dynamodb')]));
    span.addAttributes(
        OTelAPI.attributes([OTelAPI.attributeString('rpc.system', 'aws-api')]));
    span.addAttributes(OTelAPI.attributes(
        [OTelAPI.attributeString('rpc.service', 'DynamoDB')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.tableName != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('db.collection.name', res.tableName!)]));
      }
      if (res.indexName != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString('aws.dynamodb.index_name', res.indexName!)
        ]));
      }
      if (res.itemCount != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('aws.dynamodb.item_count', res.itemCount!)]));
      }
      if (res.scannedCount != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('aws.dynamodb.scanned_count', res.scannedCount!)
        ]));
      }
      if (res.consumedReadCapacity != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeDouble(
              'aws.dynamodb.consumed_capacity.read', res.consumedReadCapacity!)
        ]));
      }
      if (res.consumedWriteCapacity != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeDouble('aws.dynamodb.consumed_capacity.write',
              res.consumedWriteCapacity!)
        ]));
      }
      if (res.conditional != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeBool('aws.dynamodb.conditional', res.conditional!)
        ]));
      }
      if (res.region != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('cloud.region', res.region!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('dynamodb.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
              ErrorAttributes.errorType.key, res.errorCode ?? 'dynamodb.error')
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
