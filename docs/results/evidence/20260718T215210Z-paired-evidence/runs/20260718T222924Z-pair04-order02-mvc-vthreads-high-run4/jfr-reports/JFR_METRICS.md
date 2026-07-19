# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.885 s |
| JVM CPU average | 2.951 % |
| JVM CPU p95 | 5.634 % |
| Allocation sample weight | 4285.398 MiB |
| Allocation pressure | 34.873 MiB/s |
| GC count | 227 |
| GC pause total | 1767.389 ms |
| GC pause max | 86.585 ms |
| Active platform threads avg / max | 49.721 / 52 |
| Thread parks count / total | 12456 / 3320529.028 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 1243.185 |
| 2 | `[Ljava.lang.Object;` | 319.845 |
| 3 | `[J` | 174.252 |
| 4 | `jdk.internal.vm.StackChunk` | 157.780 |
| 5 | `[C` | 149.199 |
| 6 | `java.lang.String` | 128.314 |
| 7 | `[I` | 101.176 |
| 8 | `jdk.internal.net.http.common.MinimalFuture` | 83.360 |
| 9 | `java.time.Instant` | 81.080 |
| 10 | `java.util.ArrayList` | 65.438 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.io.InputStream.transferTo` | 626.144 |
| 2 | `java.lang.Throwable.fillInStackTrace` | 459.455 |
| 3 | `jdk.internal.vm.Continuation.doYield` | 157.780 |
| 4 | `com.fasterxml.jackson.core.util.BufferRecycler.balloc` | 151.048 |
| 5 | `java.util.Arrays.copyOf` | 132.282 |
| 6 | `java.util.Arrays.copyOfRangeByte` | 126.994 |
| 7 | `com.fasterxml.jackson.core.util.BufferRecycler.calloc` | 123.563 |
| 8 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 120.950 |
| 9 | `java.time.Instant.create` | 81.080 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 79.025 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 13 |
| 2 | `org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey.equals` | 11 |
| 3 | `java.util.HashMap.putVal` | 9 |
| 4 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 8 |
| 5 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 8 |
| 6 | `java.util.concurrent.locks.AbstractQueuedSynchronizer.signalNext` | 8 |
| 7 | `org.apache.tomcat.util.net.NioEndpoint$Poller.run` | 7 |
| 8 | `com.fasterxml.jackson.core.JsonFactory._createUTF8Generator` | 6 |
| 9 | `java.util.HashMap.get` | 6 |
| 10 | `java.util.TreeMap.containsKey` | 6 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12456 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
