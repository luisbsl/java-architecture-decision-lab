# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.471 s |
| JVM CPU average | 1.017 % |
| JVM CPU p95 | 1.916 % |
| Allocation sample weight | 282.223 MiB |
| Allocation pressure | 4.518 MiB/s |
| GC count | 15 |
| GC pause total | 44.145 ms |
| GC pause max | 5.379 ms |
| Active platform threads avg / max | 21.000 / 21 |
| Thread parks count / total | 3696 / 172049.754 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientOperations` | 56.140 |
| 2 | `[B` | 27.482 |
| 3 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 21.339 |
| 4 | `[Ljava.lang.Object;` | 11.660 |
| 5 | `java.util.concurrent.ConcurrentHashMap$Node` | 9.672 |
| 6 | `java.lang.String` | 6.581 |
| 7 | `java.util.LinkedHashMap` | 4.732 |
| 8 | `[J` | 4.620 |
| 9 | `[Ljava.util.HashMap$Node;` | 4.385 |
| 10 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 3.887 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 56.140 |
| 2 | `java.util.concurrent.ConcurrentHashMap.initTable` | 21.339 |
| 3 | `java.lang.Throwable.fillInStackTrace` | 10.541 |
| 4 | `java.util.concurrent.ConcurrentHashMap.putVal` | 9.650 |
| 5 | `java.util.Arrays.copyOfRangeByte` | 8.288 |
| 6 | `java.util.Arrays.copyOf` | 8.226 |
| 7 | `jdk.internal.misc.Unsafe.allocateInstance` | 8.028 |
| 8 | `java.util.HashMap.resize` | 4.385 |
| 9 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 4.255 |
| 10 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 3.910 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.lang.Class.getComponentType` | 3 |
| 2 | `java.util.concurrent.atomic.AtomicReferenceFieldUpdater$AtomicReferenceFieldUpdaterImpl.accessCheck` | 3 |
| 3 | `ch.qos.logback.classic.Logger.isDebugEnabled` | 2 |
| 4 | `com.fasterxml.jackson.core.sym.ByteQuadsCanonicalizer.makeChild` | 2 |
| 5 | `com.fasterxml.jackson.databind.deser.std.NumberDeserializers$IntegerDeserializer.deserialize` | 2 |
| 6 | `io.micrometer.observation.SimpleObservation.stop` | 2 |
| 7 | `io.netty.handler.codec.http.HttpObjectDecoder.isContentAlwaysEmpty` | 2 |
| 8 | `io.netty.handler.codec.http.HttpRequestEncoder.encodeInitialLine` | 2 |
| 9 | `java.lang.StringBuilder.<init>` | 2 |
| 10 | `java.lang.StringBuilder.append` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 3696 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
