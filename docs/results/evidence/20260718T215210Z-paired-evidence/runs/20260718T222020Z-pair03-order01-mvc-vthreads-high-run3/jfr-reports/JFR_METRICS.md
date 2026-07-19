# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 121.890 s |
| JVM CPU average | 2.489 % |
| JVM CPU p95 | 5.507 % |
| Allocation sample weight | 4272.226 MiB |
| Allocation pressure | 35.050 MiB/s |
| GC count | 231 |
| GC pause total | 1853.204 ms |
| GC pause max | 65.955 ms |
| Active platform threads avg / max | 49.364 / 51 |
| Thread parks count / total | 12254 / 3496328.845 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 1254.026 |
| 2 | `[Ljava.lang.Object;` | 269.027 |
| 3 | `[J` | 192.282 |
| 4 | `[C` | 143.484 |
| 5 | `jdk.internal.vm.StackChunk` | 139.999 |
| 6 | `java.lang.String` | 125.696 |
| 7 | `[I` | 109.358 |
| 8 | `jdk.internal.net.http.common.MinimalFuture` | 84.991 |
| 9 | `java.util.ArrayList` | 76.382 |
| 10 | `java.util.LinkedHashMap` | 73.448 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.io.InputStream.transferTo` | 585.886 |
| 2 | `java.lang.Throwable.fillInStackTrace` | 460.483 |
| 3 | `com.fasterxml.jackson.core.util.BufferRecycler.balloc` | 186.060 |
| 4 | `java.util.Arrays.copyOf` | 154.438 |
| 5 | `jdk.internal.vm.Continuation.doYield` | 139.999 |
| 6 | `com.fasterxml.jackson.core.util.BufferRecycler.calloc` | 119.871 |
| 7 | `java.util.Arrays.copyOfRangeByte` | 119.203 |
| 8 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 107.890 |
| 9 | `java.lang.StringLatin1.toLowerCase` | 85.359 |
| 10 | `java.util.HashMap.resize` | 62.501 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ConcurrentHashMap.get` | 15 |
| 2 | `java.lang.StringLatin1.toLowerCase` | 10 |
| 3 | `java.util.Arrays.copyOf` | 10 |
| 4 | `java.util.HashMap.getNode` | 9 |
| 5 | `jdk.internal.net.http.common.Utils.isValidValue` | 9 |
| 6 | `java.net.URI$Parser.scanIPv4Address` | 8 |
| 7 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 7 |
| 8 | `java.net.URI$Parser.scan` | 7 |
| 9 | `java.util.HashMap.putVal` | 7 |
| 10 | `java.util.TreeMap.getEntry` | 7 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12254 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
