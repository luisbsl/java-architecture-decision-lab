# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.466 s |
| JVM CPU average | 1.000 % |
| JVM CPU p95 | 1.729 % |
| Allocation sample weight | 282.629 MiB |
| Allocation pressure | 4.525 MiB/s |
| GC count | 15 |
| GC pause total | 42.220 ms |
| GC pause max | 4.334 ms |
| Active platform threads avg / max | 21.000 / 21 |
| Thread parks count / total | 3692 / 176330.643 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientOperations` | 56.096 |
| 2 | `[B` | 26.414 |
| 3 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 21.104 |
| 4 | `java.util.concurrent.ConcurrentHashMap$Node` | 9.773 |
| 5 | `[Ljava.lang.Object;` | 8.739 |
| 6 | `java.lang.String` | 6.596 |
| 7 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 5.507 |
| 8 | `[J` | 5.483 |
| 9 | `java.util.LinkedHashMap` | 5.135 |
| 10 | `[I` | 3.959 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 56.096 |
| 2 | `java.util.concurrent.ConcurrentHashMap.initTable` | 21.104 |
| 3 | `java.lang.Throwable.fillInStackTrace` | 11.833 |
| 4 | `java.util.concurrent.ConcurrentHashMap.putVal` | 9.749 |
| 5 | `java.util.Arrays.copyOf` | 7.234 |
| 6 | `jdk.internal.misc.Unsafe.allocateInstance` | 7.103 |
| 7 | `java.util.Arrays.copyOfRangeByte` | 7.030 |
| 8 | `io.netty.handler.codec.DefaultHeaders.newHeaderEntry` | 3.799 |
| 9 | `reactor.core.publisher.Mono.onErrorResume` | 3.684 |
| 10 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 3.540 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `io.netty.channel.DefaultMaxMessagesRecvByteBufAllocator.maxMessagesPerRead` | 3 |
| 2 | `io.netty.util.AsciiString$1.equals` | 3 |
| 3 | `io.netty.channel.AdaptiveRecvByteBufAllocator.<init>` | 2 |
| 4 | `io.netty.channel.epoll.EpollEventLoop.run` | 2 |
| 5 | `io.netty.handler.codec.ByteToMessageDecoder.callDecode` | 2 |
| 6 | `io.netty.util.AsciiString.toString` | 2 |
| 7 | `io.netty.util.DefaultAttributeMap.searchAttributeByKey` | 2 |
| 8 | `io.netty.util.ReferenceCountUtil.touch` | 2 |
| 9 | `io.netty.util.internal.InternalThreadLocalMap.slowGet` | 2 |
| 10 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 3692 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
