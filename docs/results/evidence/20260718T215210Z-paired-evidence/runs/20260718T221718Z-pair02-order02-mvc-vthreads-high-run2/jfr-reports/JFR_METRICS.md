# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.912 s |
| JVM CPU average | 2.538 % |
| JVM CPU p95 | 5.629 % |
| Allocation sample weight | 4277.371 MiB |
| Allocation pressure | 34.800 MiB/s |
| GC count | 231 |
| GC pause total | 1891.442 ms |
| GC pause max | 85.552 ms |
| Active platform threads avg / max | 51.164 / 54 |
| Thread parks count / total | 12251 / 3473711.803 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 1213.974 |
| 2 | `[Ljava.lang.Object;` | 296.896 |
| 3 | `[J` | 200.516 |
| 4 | `[C` | 158.934 |
| 5 | `jdk.internal.vm.StackChunk` | 146.113 |
| 6 | `java.lang.String` | 124.328 |
| 7 | `[I` | 108.660 |
| 8 | `java.time.Instant` | 91.113 |
| 9 | `jdk.internal.net.http.common.MinimalFuture` | 80.545 |
| 10 | `java.util.ArrayList` | 78.866 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.io.InputStream.transferTo` | 538.639 |
| 2 | `java.lang.Throwable.fillInStackTrace` | 477.053 |
| 3 | `com.fasterxml.jackson.core.util.BufferRecycler.balloc` | 180.809 |
| 4 | `jdk.internal.vm.Continuation.doYield` | 146.113 |
| 5 | `java.util.Arrays.copyOf` | 139.382 |
| 6 | `com.fasterxml.jackson.core.util.BufferRecycler.calloc` | 130.189 |
| 7 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 109.503 |
| 8 | `java.util.Arrays.copyOfRangeByte` | 105.891 |
| 9 | `java.time.Instant.create` | 91.113 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 73.048 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 14 |
| 2 | `org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey.equals` | 9 |
| 3 | `java.io.FilterInputStream.read` | 8 |
| 4 | `java.util.ImmutableCollections$List12.get` | 7 |
| 5 | `java.util.concurrent.ConcurrentHashMap.putVal` | 7 |
| 6 | `org.apache.tomcat.util.net.NioEndpoint$Poller.run` | 7 |
| 7 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 6 |
| 8 | `java.net.URI$Parser.scan` | 6 |
| 9 | `java.util.HashMap.putVal` | 6 |
| 10 | `java.lang.System$2.unparkVirtualThread` | 5 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12251 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
