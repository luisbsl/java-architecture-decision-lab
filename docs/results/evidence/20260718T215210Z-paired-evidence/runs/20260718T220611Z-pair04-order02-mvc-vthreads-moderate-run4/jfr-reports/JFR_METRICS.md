# JFR Metrics — `recording.jfr`

> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.

| Metric | Value |
|---|---:|
| Recording duration | 61.469 s |
| JVM CPU average | 1.302 % |
| JVM CPU p95 | 2.422 % |
| Allocation sample weight | 463.296 MiB |
| Allocation pressure | 7.537 MiB/s |
| GC count | 34 |
| GC pause total | 83.036 ms |
| GC pause max | 5.336 ms |
| Active platform threads avg / max | 25.934 / 27 |
| Thread parks count / total | 12168 / 730780.052 ms |
| Monitor enters count / total | 0 / 0.000 ms |
| Virtual-thread pinned count / total | 0 / 0.000 ms |
| Virtual-thread submit failures | 0 |
| JFR data-loss events | 0 |

## Top allocation classes

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `[B` | 64.211 |
| 2 | `java.time.Instant` | 45.281 |
| 3 | `[Ljava.lang.Object;` | 37.236 |
| 4 | `[J` | 26.254 |
| 5 | `[Ljava.util.concurrent.ConcurrentHashMap$Node;` | 19.435 |
| 6 | `[I` | 15.858 |
| 7 | `org.apache.coyote.http11.Http11Processor` | 15.004 |
| 8 | `java.lang.String` | 11.302 |
| 9 | `java.util.ArrayList$Itr` | 9.282 |
| 10 | `jdk.internal.net.http.common.MinimalFuture` | 8.107 |

## Top allocation sites

| Rank | Symbol | Sample weight MiB |
|---:|---|---:|
| 1 | `java.lang.Throwable.fillInStackTrace` | 63.052 |
| 2 | `java.time.Instant.create` | 45.281 |
| 3 | `java.util.concurrent.ConcurrentHashMap.initTable` | 19.293 |
| 4 | `org.apache.coyote.http11.AbstractHttp11Protocol.createProcessor` | 15.004 |
| 5 | `java.util.Arrays.copyOf` | 12.374 |
| 6 | `java.io.InputStream.transferTo` | 12.117 |
| 7 | `jdk.internal.misc.Unsafe.allocateInstance` | 11.721 |
| 8 | `java.util.Arrays.copyOfRangeByte` | 11.340 |
| 9 | `java.util.ArrayList.iterator` | 9.282 |
| 10 | `java.lang.StringLatin1.toLowerCase` | 8.754 |

## Top sampled CPU methods

| Rank | Symbol | Samples |
|---:|---|---:|
| 1 | `java.util.concurrent.ThreadPoolExecutor.runWorker` | 5 |
| 2 | `java.lang.Class.getComponentType` | 3 |
| 3 | `org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey.equals` | 3 |
| 4 | `com.fasterxml.jackson.core.json.UTF8JsonGenerator._writeStringSegment` | 2 |
| 5 | `com.fasterxml.jackson.core.sym.ByteQuadsCanonicalizer.makeChild` | 2 |
| 6 | `com.fasterxml.jackson.databind.deser.std.NumberDeserializers$BooleanDeserializer.deserialize` | 2 |
| 7 | `java.lang.AbstractStringBuilder.ensureCapacityInternal` | 2 |
| 8 | `java.lang.String.hashCode` | 2 |
| 9 | `java.lang.StringBuilder.<init>` | 2 |
| 10 | `java.lang.invoke.DirectMethodHandle$Holder.invokeStatic` | 2 |

## Top thread-park sites

| Rank | Symbol | Events |
|---:|---|---:|
| 1 | `jdk.internal.misc.Unsafe.park` | 12168 |

## Guardrails

- JFR method profiling is sampling-based; a top method is not automatically an optimization target.
- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.
- Events below configured thresholds are intentionally absent.
- Zero pinned-thread events means none were observed above the configured threshold in this run.
