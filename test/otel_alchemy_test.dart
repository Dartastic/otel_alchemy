// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_alchemy/otel_alchemy.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_alchemy-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('core.send records network + CU + block', () async {
    await tracedAlchemy<String>(
      operation: 'core.send',
      invoke: () async => const AlchemyCallResult(
        value: 'ok',
        result: AlchemyResult(
          network: 'eth-mainnet',
          chainId: 'eip155:1',
          rpcMethod: 'eth_call',
          batchSize: 1,
          computeUnits: 26,
          blockNumber: 19000000,
          rateLimitRemaining: 990,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('alchemy core.send')!);
    expect(a['alchemy.network'], 'eth-mainnet');
    expect(a['alchemy.compute_units'], 26);
    expect(a['alchemy.block.number'], 19000000);
  });

  test('nft.getNftsForOwner records token count + standard', () async {
    await tracedAlchemy<String>(
      operation: 'nft.getNftsForOwner',
      invoke: () async => const AlchemyCallResult(
        value: 'ok',
        result: AlchemyResult(
          network: 'eth-mainnet',
          ownerAddress: '0xabc',
          tokenStandard: 'ERC721',
          tokenCount: 47,
          computeUnits: 150,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('alchemy nft.getNftsForOwner')!);
    expect(a['alchemy.token.standard'], 'ERC721');
    expect(a['alchemy.token.count'], 47);
  });

  test('JSON-RPC error sets span error', () async {
    await tracedAlchemy<String>(
      operation: 'core.send',
      invoke: () async => const AlchemyCallResult(
        value: 'ok',
        result: AlchemyResult(
          rpcMethod: 'eth_call',
          errorCode: '-32602',
          errorMessage: 'invalid params',
        ),
      ),
    );
    expect(
      spans.findSpanByName('alchemy core.send')!.status,
      SpanStatusCode.Error,
    );
  });

  test('HTTP 429 sets span error', () async {
    await tracedAlchemy<String>(
      operation: 'core.send',
      invoke: () async => const AlchemyCallResult(
        value: 'ok',
        result: AlchemyResult(statusCode: 429, rateLimitRemaining: 0),
      ),
    );
    expect(
      spans.findSpanByName('alchemy core.send')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutAlchemyInstrumentationAsync(() async {
      await tracedAlchemy<String>(
        operation: 'notify.listWebhooks',
        invoke: () async => const AlchemyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('alchemy '), isEmpty);
  });
}
