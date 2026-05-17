// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_aws_dynamodb_suppression.dart';

class AwsDynamoDBResult {
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

class AwsDynamoDBCallResult<T> {
  const AwsDynamoDBCallResult({required this.value, this.result});
  final T value;
  final AwsDynamoDBResult? result;
}

Future<T> tracedAwsDynamoDB<T>({
  required String operation,
  required Future<AwsDynamoDBCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (awsDynamoDBInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_aws_dynamodb');
  final span = t.startSpan('dynamodb $operation', kind: SpanKind.client);
  try {
    span.setStringAttribute('db.system.name', 'dynamodb');
    span.setStringAttribute('rpc.system', 'aws-api');
    span.setStringAttribute('rpc.service', 'DynamoDB');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.tableName != null) {
        span.setStringAttribute('db.collection.name', res.tableName!);
      }
      if (res.indexName != null) {
        span.setStringAttribute('aws.dynamodb.index_name', res.indexName!);
      }
      if (res.itemCount != null) {
        span.setIntAttribute('aws.dynamodb.item_count', res.itemCount!);
      }
      if (res.scannedCount != null) {
        span.setIntAttribute('aws.dynamodb.scanned_count', res.scannedCount!);
      }
      if (res.consumedReadCapacity != null) {
        span.setDoubleAttribute(
            'aws.dynamodb.consumed_capacity.read', res.consumedReadCapacity!);
      }
      if (res.consumedWriteCapacity != null) {
        span.setDoubleAttribute(
            'aws.dynamodb.consumed_capacity.write', res.consumedWriteCapacity!);
      }
      if (res.conditional != null) {
        span.setBoolAttribute('aws.dynamodb.conditional', res.conditional!);
      }
      if (res.region != null) {
        span.setStringAttribute('cloud.region', res.region!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('dynamodb.error.code', res.errorCode!);
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
            ErrorResource.errorType.key, res.errorCode ?? 'dynamodb.error');
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
