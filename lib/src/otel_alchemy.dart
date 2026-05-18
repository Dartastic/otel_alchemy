// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_alchemy_suppression.dart';

const _tracerName = 'dartastic_otel_libs_alchemy';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AlchemyResult {
  const AlchemyResult({
    this.network,
    this.chainId,
    this.rpcMethod,
    this.batchSize,
    this.computeUnits,
    this.responseBytes,
    this.blockNumber,
    this.fromBlock,
    this.toBlock,
    this.contractAddress,
    this.ownerAddress,
    this.tokenStandard,
    this.tokenCount,
    this.webhookId,
    this.webhookKind,
    this.gasEstimate,
    this.rateLimitRemaining,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `eth-mainnet`, `eth-sepolia`, `polygon-mainnet`, `arb-mainnet`,
  /// `opt-mainnet`, `base-mainnet`, `solana-mainnet`, `starknet-mainnet`.
  final String? network;

  /// CAIP-2 chain id (`eip155:1`, `eip155:137`, ...).
  final String? chainId;

  /// JSON-RPC method (`eth_call`, `eth_getLogs`, `eth_blockNumber`,
  /// `alchemy_getAssetTransfers`, `alchemy_getTokenBalances`,
  /// `alchemy_getNFTs`, `alchemy_getNFTMetadata`, `alchemy_simulateExecution`,
  /// `alchemy_pendingTransactions`, ...).
  final String? rpcMethod;

  /// JSON-RPC batch size (1 for single calls).
  final int? batchSize;

  /// Compute Units consumed (Alchemy's primary billing dimension).
  final int? computeUnits;

  /// Response body size in bytes.
  final int? responseBytes;

  /// Tip block at query time.
  final int? blockNumber;

  final int? fromBlock;
  final int? toBlock;

  final String? contractAddress;
  final String? ownerAddress;

  /// `ERC20`, `ERC721`, `ERC1155`, `NoStandard`.
  final String? tokenStandard;

  /// Item count returned by NFT / token endpoints.
  final int? tokenCount;

  final String? webhookId;

  /// `MINED_TRANSACTION`, `DROPPED_TRANSACTION`, `ADDRESS_ACTIVITY`,
  /// `NFT_ACTIVITY`, `GRAPHQL`, `CUSTOM`.
  final String? webhookKind;

  /// Gas estimate from `eth_estimateGas` / `alchemy_simulateExecution`.
  final int? gasEstimate;

  final int? rateLimitRemaining;

  /// JSON-RPC error code (`-32600` invalid request, `-32601` method not found,
  /// `-32602` invalid params, `-32603` internal error,
  /// `-32700` parse error, custom 3xxxx codes for Alchemy).
  final String? errorCode;
  final String? errorMessage;

  final int? statusCode;
}

class AlchemyCallResult<T> {
  const AlchemyCallResult({required this.value, this.result});
  final T value;
  final AlchemyResult? result;
}

/// Wraps an Alchemy API call in a CLIENT span. [operation] is one of
/// `core.send`, `core.sendBatch`, `core.getBalance`, `core.getBlock`,
/// `core.getLogs`, `core.estimateGas`, `core.getFeeData`,
/// `core.getTransaction`, `core.getTransactionReceipt`,
/// `nft.getNftsForOwner`, `nft.getNftMetadata`, `nft.getOwnersForNft`,
/// `nft.getContractsForOwner`, `nft.searchContractMetadata`,
/// `nft.computeRarity`, `nft.refreshNftMetadata`,
/// `transact.simulateAssetChanges`, `transact.simulateExecution`,
/// `transact.sendPrivateTransaction`, `transact.cancelPrivateTransaction`,
/// `notify.createWebhook`, `notify.updateWebhook`, `notify.deleteWebhook`,
/// `notify.listWebhooks`, `subscriptions.subscribe`,
/// `subscriptions.unsubscribe`, `prices.getTokenPriceBySymbol`,
/// `prices.getTokenPriceByAddress`.
Future<T> tracedAlchemy<T>({
  required String operation,
  required Future<AlchemyCallResult<T>> Function() invoke,
}) async {
  if (alchemyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'alchemy',
    'rpc.method': operation,
    'alchemy.operation': operation,
  };

  final span = _tracer().startSpan(
    'alchemy $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.network != null) {
        extras.add(OTel.attributeString('alchemy.network', res.network!));
      }
      if (res.chainId != null) {
        extras.add(OTel.attributeString('alchemy.chain.id', res.chainId!));
      }
      if (res.rpcMethod != null) {
        extras.add(OTel.attributeString(
          'alchemy.rpc.method',
          res.rpcMethod!,
        ));
      }
      if (res.batchSize != null) {
        extras.add(OTel.attributeInt('alchemy.batch.size', res.batchSize!));
      }
      if (res.computeUnits != null) {
        extras.add(OTel.attributeInt(
          'alchemy.compute_units',
          res.computeUnits!,
        ));
      }
      if (res.responseBytes != null) {
        extras.add(OTel.attributeInt(
          'alchemy.response.bytes',
          res.responseBytes!,
        ));
      }
      if (res.blockNumber != null) {
        extras.add(OTel.attributeInt(
          'alchemy.block.number',
          res.blockNumber!,
        ));
      }
      if (res.fromBlock != null) {
        extras.add(OTel.attributeInt('alchemy.from_block', res.fromBlock!));
      }
      if (res.toBlock != null) {
        extras.add(OTel.attributeInt('alchemy.to_block', res.toBlock!));
      }
      if (res.contractAddress != null) {
        extras.add(OTel.attributeString(
          'alchemy.contract.address',
          res.contractAddress!,
        ));
      }
      if (res.ownerAddress != null) {
        extras.add(OTel.attributeString(
          'alchemy.owner.address',
          res.ownerAddress!,
        ));
      }
      if (res.tokenStandard != null) {
        extras.add(OTel.attributeString(
          'alchemy.token.standard',
          res.tokenStandard!,
        ));
      }
      if (res.tokenCount != null) {
        extras.add(OTel.attributeInt(
          'alchemy.token.count',
          res.tokenCount!,
        ));
      }
      if (res.webhookId != null) {
        extras.add(OTel.attributeString(
          'alchemy.webhook.id',
          res.webhookId!,
        ));
      }
      if (res.webhookKind != null) {
        extras.add(OTel.attributeString(
          'alchemy.webhook.kind',
          res.webhookKind!,
        ));
      }
      if (res.gasEstimate != null) {
        extras.add(OTel.attributeInt(
          'alchemy.gas.estimate',
          res.gasEstimate!,
        ));
      }
      if (res.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'alchemy.rate_limit.remaining',
          res.rateLimitRemaining!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'alchemy.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Alchemy ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'alchemy.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Alchemy HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
