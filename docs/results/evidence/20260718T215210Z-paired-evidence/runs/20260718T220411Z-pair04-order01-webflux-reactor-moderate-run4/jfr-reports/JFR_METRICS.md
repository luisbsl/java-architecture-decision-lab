# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 61.462 s |
| JVM CPU average | 1.035 % |
| JVM CPU p95 | 1.916 % |
| Allocation sample weight | 281.656 MiB |
| Allocation pressure | 4.583 MiB/s |
| GC count | 15 |
| GC pause total | 42.414 ms |
| GC pause max | 3.770 ms |
| Active platform threads avg / max | 21.000 / 21 |
| Thread parks count / total | 3690 / 164341.027 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientOperations` | 55.947 |
| 2 | `[B` | 22.847 |
| 3 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 21.348 |
| 4 | `java.util.concurrent.ConcurrentHashMap$Node` | 9.959 |
| 5 | `[Ljava.lang.Object;` | 9.444 |
| 6 | `java.lang.String` | 6.868 |
| 7 | `java.util.LinkedHashMap` | 4.659 |
| 8 | `[J` | 4.535 |
| 9 | `[I` | 4.390 |
| 10 | `io.netty.handler.codec.DefaultHeaders$HeaderEntry` | 4.153 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `reactor.netty.http.client.HttpClientConfig.lambda$channelOperationsProvider$0` | 55.947 |
| 2 | `java.util.concurrent.ConcurrentHashMap.initTable` | 21.348 |
| 3 | `java.lang.Throwable.fillInStackTrace` | 12.692 |
| 4 | `java.util.concurrent.ConcurrentHashMap.putVal` | 9.948 |
| 5 | `jdk.internal.misc.Unsafe.allocateInstance` | 8.155 |
| 6 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 6.519 |
| 7 | `java.util.Arrays.copyOfRangeByte` | 5.923 |
| 8 | `java.util.Arrays.copyOf` | 5.419 |
| 9 | `io.netty.handler.codec.DefaultHeaders.<init>` | 3.671 |
| 10 | `java.util.HashMap.resize` | 3.457 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `io.netty.channel.epoll.EpollEventLoop.run` | 3 |
| 2 | `java.lang.StringBuilder.<init>` | 3 |
| 3 | `java.lang.invoke.DirectMethodHandle$Holder.invokeStatic` | 3 |
| 4 | `java.util.concurrent.atomic.AtomicReferenceFieldUpdater$AtomicReferenceFieldUpdaterImpl.accessCheck` | 3 |
| 5 | `io.netty.handler.codec.http.HttpUtil.isValidTokenChar` | 2 |
| 6 | `io.netty.util.internal.InternalThreadLocalMap.slowGet` | 2 |
| 7 | `java.lang.invoke.DirectMethodHandle$Holder.newInvokeSpecial` | 2 |
| 8 | `java.lang.invoke.DirectMethodHandle.allocateInstance` | 2 |
| 9 | `java.lang.invoke.Invokers$Holder.linkToTargetMethod` | 2 |
| 10 | `java.lang.invoke.VarHandleReferences$FieldInstanceReadWrite.setRelease` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 3690 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
