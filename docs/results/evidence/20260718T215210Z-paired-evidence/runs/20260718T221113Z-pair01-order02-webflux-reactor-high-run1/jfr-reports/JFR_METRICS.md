# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.929 s |
| JVM CPU average | 1.611 % |
| JVM CPU p95 | 4.587 % |
| Allocation sample weight | 2254.068 MiB |
| Allocation pressure | 18.336 MiB/s |
| GC count | 134 |
| GC pause total | 1941.223 ms |
| GC pause max | 57.049 ms |
| Active platform threads avg / max | 20.189 / 21 |
| Thread parks count / total | 7731 / 353942.704 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 247.843 |
| 2 | `[Ljava.lang.Object;` | 127.342 |
| 3 | `java.lang.String` | 95.082 |
| 4 | `reactor.netty.http.client.HttpClientOperations` | 63.219 |
| 5 | `[J` | 52.969 |
| 6 | `[I` | 52.447 |
| 7 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 49.753 |
| 8 | `java.util.LinkedHashMap` | 47.900 |
| 9 | `[Ljava.util.HashMap$Node;` | 40.757 |
| 10 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 34.583 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 139.730 |
| 2 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 108.337 |
| 3 | `java.util.Arrays.copyOfRangeByte` | 68.294 |
| 4 | `java.util.Arrays.copyOf` | 63.309 |
| 5 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 63.219 |
| 6 | `java.util.HashMap.resize` | 40.757 |
| 7 | `jdk.internal.misc.Unsafe.allocateUninitializedArray` | 40.576 |
| 8 | `io.netty.handler.codec.DefaultHeaders.newHeaderEntry` | 39.181 |
| 9 | `java.util.concurrent.ConcurrentHashMap.initTable` | 34.348 |
| 10 | `io.netty.handler.codec.DefaultHeaders.<init>` | 31.064 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 16 |
| 2 | `java.util.HashMap.putVal` | 14 |
| 3 | `io.netty.util.internal.InternalThreadLocalMap.slowGet` | 12 |
| 4 | `java.util.concurrent.CopyOnWriteArrayList.elementAt` | 11 |
| 5 | `org.springframework.util.ObjectUtils.nullSafeEquals` | 11 |
| 6 | `io.netty.util.internal.PlatformDependent.hashCodeAscii` | 9 |
| 7 | `io.netty.channel.AbstractChannelHandlerContext.findContextOutbound` | 7 |
| 8 | `io.netty.buffer.PoolArena.tcacheAllocateSmall` | 6 |
| 9 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 6 |
| 10 | `org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey.equals` | 6 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 7731 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
