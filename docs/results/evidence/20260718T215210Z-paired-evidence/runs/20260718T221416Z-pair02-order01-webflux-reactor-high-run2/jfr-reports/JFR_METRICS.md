# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.869 s |
| JVM CPU average | 1.620 % |
| JVM CPU p95 | 4.241 % |
| Allocation sample weight | 2265.613 MiB |
| Allocation pressure | 18.439 MiB/s |
| GC count | 134 |
| GC pause total | 1928.899 ms |
| GC pause max | 60.458 ms |
| Active platform threads avg / max | 20.189 / 21 |
| Thread parks count / total | 7648 / 350373.453 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 252.024 |
| 2 | `[Ljava.lang.Object;` | 110.308 |
| 3 | `java.lang.String` | 85.919 |
| 4 | `reactor.netty.http.client.HttpClientOperations` | 63.283 |
| 5 | `[J` | 58.044 |
| 6 | `[I` | 53.343 |
| 7 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 50.151 |
| 8 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 47.302 |
| 9 | `java.util.LinkedHashMap` | 46.584 |
| 10 | `[Ljava.util.HashMap$Node;` | 39.307 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 137.717 |
| 2 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 118.331 |
| 3 | `java.util.Arrays.copyOfRangeByte` | 65.419 |
| 4 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 63.283 |
| 5 | `java.util.concurrent.ConcurrentHashMap.initTable` | 49.877 |
| 6 | `java.util.Arrays.copyOf` | 44.422 |
| 7 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 42.444 |
| 8 | `java.util.HashMap.resize` | 39.307 |
| 9 | `io.netty.handler.codec.DefaultHeaders.newHeaderEntry` | 35.764 |
| 10 | `io.netty.handler.codec.DefaultHeaders.<init>` | 32.603 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 17 |
| 2 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 10 |
| 3 | `java.util.HashMap.putVal` | 9 |
| 4 | `org.springframework.util.ObjectUtils.nullSafeEquals` | 9 |
| 5 | `ch.qos.logback.classic.LoggerContext.getTurboFilterChainDecision_0_3OrMore` | 8 |
| 6 | `java.util.HashMap.getOrDefault` | 8 |
| 7 | `com.fasterxml.jackson.core.json.UTF8JsonGenerator._writeStringSegment` | 7 |
| 8 | `java.lang.StringLatin1.toLowerCase` | 7 |
| 9 | `java.util.Arrays.copyOf` | 7 |
| 10 | `io.netty.channel.epoll.EpollEventLoop.run` | 6 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 7648 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
