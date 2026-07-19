# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.433 s |
| JVM CPU average | 0.977 % |
| JVM CPU p95 | 2.009 % |
| Allocation sample weight | 281.022 MiB |
| Allocation pressure | 4.501 MiB/s |
| GC count | 15 |
| GC pause total | 44.067 ms |
| GC pause max | 4.163 ms |
| Active platform threads avg / max | 21.000 / 21 |
| Thread parks count / total | 3693 / 156808.109 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientOperations` | 55.850 |
| 2 | `[B` | 22.900 |
| 3 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 21.324 |
| 4 | `java.util.concurrent.ConcurrentHashMap$Node` | 9.836 |
| 5 | `java.lang.String` | 8.264 |
| 6 | `[Ljava.lang.Object;` | 7.552 |
| 7 | `[J` | 4.795 |
| 8 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 4.456 |
| 9 | `[I` | 4.247 |
| 10 | `java.util.LinkedHashMap` | 4.007 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 55.850 |
| 2 | `java.util.concurrent.ConcurrentHashMap.initTable` | 21.324 |
| 3 | `java.lang.Throwable.fillInStackTrace` | 11.224 |
| 4 | `java.util.concurrent.ConcurrentHashMap.putVal` | 9.807 |
| 5 | `jdk.internal.misc.Unsafe.allocateInstance` | 9.427 |
| 6 | `java.util.Arrays.copyOf` | 5.887 |
| 7 | `java.util.Arrays.copyOfRangeByte` | 5.155 |
| 8 | `io.netty.handler.codec.DefaultHeaders.<init>` | 4.046 |
| 9 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 3.838 |
| 10 | `java.util.HashMap.resize` | 3.744 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.Objects.requireNonNull` | 3 |
| 2 | `com.fasterxml.jackson.core.json.UTF8JsonGenerator._writeStringSegment` | 2 |
| 3 | `io.netty.channel.epoll.EpollEventLoop.run` | 2 |
| 4 | `java.lang.StringBuilder.<init>` | 2 |
| 5 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 2 |
| 6 | `java.lang.invoke.Invokers.checkCustomized` | 2 |
| 7 | `java.time.format.DateTimeFormatterBuilder$InstantPrinterParser.format` | 2 |
| 8 | `java.util.HashMap.getNode` | 2 |
| 9 | `java.util.concurrent.ConcurrentHashMap.get` | 2 |
| 10 | `java.util.concurrent.atomic.AtomicLongFieldUpdater$CASUpdater.accessCheck` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 3693 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
