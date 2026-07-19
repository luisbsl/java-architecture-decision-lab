# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.470 s |
| JVM CPU average | 1.265 % |
| JVM CPU p95 | 2.142 % |
| Allocation sample weight | 467.181 MiB |
| Allocation pressure | 7.478 MiB/s |
| GC count | 34 |
| GC pause total | 85.395 ms |
| GC pause max | 6.792 ms |
| Active platform threads avg / max | 25.984 / 27 |
| Thread parks count / total | 12017 / 734700.894 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 64.547 |
| 2 | `java.time.Instant` | 52.502 |
| 3 | `[Ljava.lang.Object;` | 36.780 |
| 4 | `[J` | 24.446 |
| 5 | `java.util.ArrayList` | 23.749 |
| 6 | `java.lang.String` | 14.290 |
| 7 | `[I` | 13.131 |
| 8 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler$1` | 10.084 |
| 9 | `java.util.ArrayList$Itr` | 9.338 |
| 10 | `jdk.internal.vm.StackChunk` | 8.832 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 59.607 |
| 2 | `java.time.Instant.create` | 52.502 |
| 3 | `jdk.jfr.internal.JVM.getAllEventClasses` | 18.120 |
| 4 | `java.util.Arrays.copyOf` | 12.135 |
| 5 | `java.io.InputStream.transferTo` | 11.743 |
| 6 | `java.util.Arrays.copyOfRangeByte` | 11.516 |
| 7 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 11.332 |
| 8 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler.wrapInputStream` | 10.084 |
| 9 | `java.lang.StringLatin1.toLowerCase` | 9.656 |
| 10 | `java.util.ArrayList.iterator` | 9.338 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.lang.StringBuilder.<init>` | 3 |
| 2 | `jdk.internal.net.http.HttpClientImpl$$Lambda.0x00007180f461f3e0.accept` | 3 |
| 3 | `com.fasterxml.jackson.core.json.UTF8StreamJsonParser.findName` | 2 |
| 4 | `com.fasterxml.jackson.core.sym.ByteQuadsCanonicalizer.findName` | 2 |
| 5 | `java.lang.Class.cast` | 2 |
| 6 | `java.math.BigDecimal.<init>` | 2 |
| 7 | `java.util.ArrayList$Itr.next` | 2 |
| 8 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 2 |
| 9 | `java.util.concurrent.locks.ReentrantLock$Sync.lock` | 2 |
| 10 | `jdk.internal.net.http.Http1HeaderParser.canContinueParsing` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12017 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
