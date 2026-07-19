# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.876 s |
| JVM CPU average | 1.610 % |
| JVM CPU p95 | 4.409 % |
| Allocation sample weight | 2254.316 MiB |
| Allocation pressure | 18.346 MiB/s |
| GC count | 134 |
| GC pause total | 1990.631 ms |
| GC pause max | 58.835 ms |
| Active platform threads avg / max | 20.213 / 21 |
| Thread parks count / total | 7767 / 350553.860 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 250.939 |
| 2 | `[Ljava.lang.Object;` | 108.040 |
| 3 | `java.lang.String` | 99.557 |
| 4 | `reactor.netty.http.client.HttpClientOperations` | 64.187 |
| 5 | `[J` | 57.520 |
| 6 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 52.934 |
| 7 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 51.462 |
| 8 | `[I` | 50.994 |
| 9 | `java.util.LinkedHashMap` | 49.577 |
| 10 | `[Ljava.util.HashMap$Node;` | 41.489 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 146.033 |
| 2 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 106.235 |
| 3 | `java.util.Arrays.copyOfRangeByte` | 70.050 |
| 4 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 64.187 |
| 5 | `java.util.concurrent.ConcurrentHashMap.initTable` | 51.215 |
| 6 | `java.util.Arrays.copyOf` | 44.164 |
| 7 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 42.381 |
| 8 | `java.util.HashMap.resize` | 41.489 |
| 9 | `io.netty.handler.codec.DefaultHeaders.newHeaderEntry` | 39.548 |
| 10 | `io.netty.handler.codec.DefaultHeaders.<init>` | 33.704 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 14 |
| 2 | `io.netty.util.DefaultAttributeMap.searchAttributeByKey` | 10 |
| 3 | `java.util.HashMap.putVal` | 9 |
| 4 | `java.net.URI$Parser.scan` | 8 |
| 5 | `java.util.Arrays.copyOf` | 8 |
| 6 | `io.netty.buffer.ByteBufUtil.utf8MaxBytes` | 7 |
| 7 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 7 |
| 8 | `java.lang.invoke.Invokers.checkCustomized` | 7 |
| 9 | `java.util.concurrent.CopyOnWriteArrayList.elementAt` | 7 |
| 10 | `io.netty.util.internal.InternalThreadLocalMap.slowGet` | 6 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 7767 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
