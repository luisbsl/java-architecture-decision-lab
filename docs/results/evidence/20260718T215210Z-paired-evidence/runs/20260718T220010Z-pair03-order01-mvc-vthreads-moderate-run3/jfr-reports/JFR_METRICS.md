# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.517 s |
| JVM CPU average | 1.259 % |
| JVM CPU p95 | 2.145 % |
| Allocation sample weight | 465.662 MiB |
| Allocation pressure | 7.449 MiB/s |
| GC count | 34 |
| GC pause total | 86.227 ms |
| GC pause max | 4.871 ms |
| Active platform threads avg / max | 26.855 / 27 |
| Thread parks count / total | 12173 / 779018.662 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 64.469 |
| 2 | `[Ljava.lang.Object;` | 38.507 |
| 3 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler$1` | 31.798 |
| 4 | `java.lang.String` | 31.164 |
| 5 | `java.time.Instant` | 29.904 |
| 6 | `[J` | 26.453 |
| 7 | `[I` | 14.639 |
| 8 | `java.util.ArrayList$Itr` | 9.879 |
| 9 | `[S` | 9.027 |
| 10 | `jdk.internal.vm.StackChunk` | 8.389 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 65.761 |
| 2 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler.wrapInputStream` | 31.798 |
| 3 | `java.time.Instant.create` | 29.904 |
| 4 | `java.lang.StringLatin1.newString` | 20.658 |
| 5 | `java.util.Arrays.copyOf` | 13.594 |
| 6 | `java.util.Arrays.copyOfRangeByte` | 11.858 |
| 7 | `java.io.InputStream.transferTo` | 11.840 |
| 8 | `jdk.internal.misc.Unsafe.allocateInstance` | 9.964 |
| 9 | `java.util.ArrayList.iterator` | 9.879 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 8.644 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 4 |
| 2 | `com.fasterxml.jackson.core.json.ByteSourceJsonBootstrapper.detectEncoding` | 3 |
| 3 | `java.util.HashMap.putVal` | 3 |
| 4 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 3 |
| 5 | `jdk.internal.net.http.common.Logger.log` | 3 |
| 6 | `org.springframework.web.filter.ServerHttpObservationFilter.doFilterInternal` | 3 |
| 7 | `java.lang.Class.cast` | 2 |
| 8 | `java.lang.String.equals` | 2 |
| 9 | `java.util.TreeMap.fixAfterInsertion` | 2 |
| 10 | `java.util.TreeMap.put` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12173 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
