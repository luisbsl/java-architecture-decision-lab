# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 122.895 s |
| JVM CPU average | 2.539 % |
| JVM CPU p95 | 4.838 % |
| Allocation sample weight | 4294.931 MiB |
| Allocation pressure | 34.948 MiB/s |
| GC count | 231 |
| GC pause total | 1838.751 ms |
| GC pause max | 104.641 ms |
| Active platform threads avg / max | 49.090 / 52 |
| Thread parks count / total | 12482 / 3643554.439 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 1271.881 |
| 2 | `[Ljava.lang.Object;` | 303.373 |
| 3 | `[J` | 201.315 |
| 4 | `[C` | 160.014 |
| 5 | `jdk.internal.vm.StackChunk` | 136.222 |
| 6 | `java.lang.String` | 117.703 |
| 7 | `[I` | 98.390 |
| 8 | `jdk.internal.net.http.common.MinimalFuture` | 85.150 |
| 9 | `java.time.Instant` | 82.246 |
| 10 | `[S` | 64.298 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.io.InputStream.transferTo` | 599.962 |
| 2 | `java.lang.Throwable.fillInStackTrace` | 475.661 |
| 3 | `com.fasterxml.jackson.core.util.BufferRecycler.balloc` | 184.287 |
| 4 | `java.util.Arrays.copyOf` | 148.386 |
| 5 | `com.fasterxml.jackson.core.util.BufferRecycler.calloc` | 138.133 |
| 6 | `jdk.internal.vm.Continuation.doYield` | 136.222 |
| 7 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 123.872 |
| 8 | `java.util.Arrays.copyOfRangeByte` | 109.144 |
| 9 | `java.time.Instant.create` | 82.246 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 78.954 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 16 |
| 2 | `org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey.equals` | 12 |
| 3 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 11 |
| 4 | `java.util.HashMap.putVal` | 11 |
| 5 | `java.lang.System$2.unparkVirtualThread` | 10 |
| 6 | `org.apache.tomcat.util.net.NioEndpoint$Poller.run` | 7 |
| 7 | `java.io.FilterInputStream.read` | 6 |
| 8 | `java.lang.Class.cast` | 6 |
| 9 | `jdk.internal.net.http.Http1HeaderParser.get` | 6 |
| 10 | `java.net.URI$Parser.scan` | 5 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12482 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
