# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.880 s |
| JVM CPU average | 1.605 % |
| JVM CPU p95 | 4.075 % |
| Allocation sample weight | 2260.890 MiB |
| Allocation pressure | 18.399 MiB/s |
| GC count | 134 |
| GC pause total | 1993.173 ms |
| GC pause max | 53.267 ms |
| Active platform threads avg / max | 20.238 / 21 |
| Thread parks count / total | 7677 / 351834.023 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 245.897 |
| 2 | `[Ljava.lang.Object;` | 102.110 |
| 3 | `java.lang.String` | 88.672 |
| 4 | `reactor.netty.http.client.HttpClientOperations` | 63.404 |
| 5 | `[J` | 60.119 |
| 6 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 50.211 |
| 7 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 50.034 |
| 8 | `java.util.LinkedHashMap` | 49.480 |
| 9 | `[I` | 46.615 |
| 10 | `[Ljava.util.HashMap$Node;` | 37.743 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 144.312 |
| 2 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 104.111 |
| 3 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 63.404 |
| 4 | `java.util.Arrays.copyOfRangeByte` | 61.446 |
| 5 | `java.util.concurrent.ConcurrentHashMap.initTable` | 49.977 |
| 6 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 43.048 |
| 7 | `java.util.Arrays.copyOf` | 42.735 |
| 8 | `io.netty.handler.codec.DefaultHeaders.newHeaderEntry` | 41.819 |
| 9 | `java.util.HashMap.resize` | 37.743 |
| 10 | `io.netty.handler.codec.DefaultHeaders.<init>` | 34.129 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 18 |
| 2 | `java.util.concurrent.atomic.LongAdder.add` | 18 |
| 3 | `ch.qos.logback.classic.spi.TurboFilterList.getTurboFilterChainDecision` | 14 |
| 4 | `java.util.HashMap.putVal` | 14 |
| 5 | `java.lang.invoke.Invokers.checkCustomized` | 10 |
| 6 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 10 |
| 7 | `reactor.util.context.Context2.put` | 10 |
| 8 | `io.netty.util.DefaultAttributeMap.searchAttributeByKey` | 9 |
| 9 | `java.lang.reflect.AccessibleObject.verifyAccess` | 7 |
| 10 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 6 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 7677 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
