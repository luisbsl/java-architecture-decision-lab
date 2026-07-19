# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 62.440 s |
| JVM CPU average | 1.258 % |
| JVM CPU p95 | 2.124 % |
| Allocation sample weight | 470.027 MiB |
| Allocation pressure | 7.528 MiB/s |
| GC count | 34 |
| GC pause total | 81.434 ms |
| GC pause max | 4.447 ms |
| Active platform threads avg / max | 26.065 / 27 |
| Thread parks count / total | 12053 / 725324.095 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 65.753 |
| 2 | `[Ljava.lang.Object;` | 36.689 |
| 3 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler$1` | 35.322 |
| 4 | `[J` | 28.709 |
| 5 | `java.util.ArrayList$Itr` | 27.243 |
| 6 | `java.time.Instant` | 26.439 |
| 7 | `[I` | 16.032 |
| 8 | `java.lang.String` | 13.227 |
| 9 | `jdk.internal.vm.StackChunk` | 8.818 |
| 10 | `jdk.internal.net.http.common.MinimalFuture` | 7.766 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 66.855 |
| 2 | `org.springframework.http.client.JdkClientHttpRequest$TimeoutHandler.wrapInputStream` | 35.322 |
| 3 | `java.util.ArrayList.iterator` | 27.243 |
| 4 | `java.time.Instant.create` | 26.439 |
| 5 | `java.io.InputStream.transferTo` | 15.512 |
| 6 | `jdk.internal.misc.Unsafe.allocateInstance` | 14.642 |
| 7 | `java.util.Arrays.copyOf` | 12.923 |
| 8 | `java.util.Arrays.copyOfRangeByte` | 11.455 |
| 9 | `jdk.internal.vm.Continuation.doYield` | 8.818 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 8.210 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.HashMap.getNode` | 3 |
| 2 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 3 |
| 3 | `io.micrometer.common.KeyValue.of` | 2 |
| 4 | `io.micrometer.core.instrument.Meter$Id.<init>` | 2 |
| 5 | `io.micrometer.observation.ObservationHandler$FirstMatchingCompositeObservationHandler.onStart` | 2 |
| 6 | `java.io.InputStream.transferTo` | 2 |
| 7 | `java.lang.Class.cast` | 2 |
| 8 | `java.lang.invoke.LambdaForm$MH.0x000071f3e8109c00.invokeExact_MT` | 2 |
| 9 | `java.util.HashMap$HashMapSpliterator.getFence` | 2 |
| 10 | `java.util.concurrent.CompletableFuture.completeOnTimeout` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12053 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
