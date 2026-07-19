import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import jdk.jfr.consumer.RecordedClass;
import jdk.jfr.consumer.RecordedEvent;
import jdk.jfr.consumer.RecordedFrame;
import jdk.jfr.consumer.RecordedMethod;
import jdk.jfr.consumer.RecordedStackTrace;
import jdk.jfr.consumer.RecordingFile;

/**
 * Dependency-free JFR aggregator for the evidence pipeline.
 *
 * Usage:
 *   java ExtractJfrMetrics.java <recording.jfr> <output-directory>
 */
public final class ExtractJfrMetrics {
    private static final int TOP_LIMIT = 10;
    private static final double BYTES_PER_MIB = 1024d * 1024d;

    private ExtractJfrMetrics() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: java ExtractJfrMetrics.java <recording.jfr> <output-directory>");
            System.exit(2);
        }

        Path recording = Path.of(args[0]).toAbsolutePath().normalize();
        Path output = Path.of(args[1]).toAbsolutePath().normalize();
        if (!Files.isRegularFile(recording) || Files.size(recording) == 0) {
            throw new IllegalArgumentException("JFR recording is missing or empty: " + recording);
        }
        Files.createDirectories(output);

        Metrics metrics = read(recording);
        Path jsonPath = output.resolve("jfr-metrics.json");
        Path markdownPath = output.resolve("JFR_METRICS.md");
        Files.writeString(jsonPath, metrics.toJson(), StandardCharsets.UTF_8);
        Files.writeString(markdownPath, metrics.toMarkdown(recording.getFileName().toString()), StandardCharsets.UTF_8);

        System.out.println("[OK] " + jsonPath);
        System.out.println("[OK] " + markdownPath);
    }

    static Metrics read(Path recording) throws IOException {
        Metrics m = new Metrics();
        try (RecordingFile file = new RecordingFile(recording)) {
            while (file.hasMoreEvents()) {
                RecordedEvent event = file.readEvent();
                m.accept(event);
            }
        }
        m.finish();
        return m;
    }

    private static String topFrame(RecordedEvent event) {
        RecordedStackTrace trace = event.getStackTrace();
        if (trace == null || trace.getFrames().isEmpty()) {
            return "<no-stack>";
        }
        for (RecordedFrame frame : trace.getFrames()) {
            RecordedMethod method = frame.getMethod();
            if (method == null || method.getType() == null) {
                continue;
            }
            String className = method.getType().getName();
            if (className.startsWith("jdk.internal.event.") || className.startsWith("java.lang.Thread")) {
                continue;
            }
            return className + "." + method.getName();
        }
        RecordedMethod method = trace.getFrames().getFirst().getMethod();
        return method == null || method.getType() == null
                ? "<unknown>"
                : method.getType().getName() + "." + method.getName();
    }

    private static String allocatedClass(RecordedEvent event) {
        if (!event.hasField("objectClass")) {
            return "<unknown>";
        }
        RecordedClass type = event.getClass("objectClass");
        return type == null ? "<unknown>" : type.getName();
    }

    private static long durationNanos(RecordedEvent event) {
        Duration duration = event.getDuration();
        return duration == null ? 0L : Math.max(0L, duration.toNanos());
    }

    private static long durationFieldNanos(RecordedEvent event, String field) {
        if (!event.hasField(field)) {
            return 0L;
        }
        Duration duration = event.getDuration(field);
        return duration == null ? 0L : Math.max(0L, duration.toNanos());
    }

    private static double percentile(List<Double> values, double percentile) {
        if (values.isEmpty()) {
            return Double.NaN;
        }
        List<Double> sorted = new ArrayList<>(values);
        sorted.sort(Double::compareTo);
        int index = (int) Math.ceil(percentile * sorted.size()) - 1;
        return sorted.get(Math.max(0, Math.min(index, sorted.size() - 1)));
    }

    private static double average(List<Double> values) {
        if (values.isEmpty()) {
            return Double.NaN;
        }
        double sum = 0d;
        for (double value : values) {
            sum += value;
        }
        return sum / values.size();
    }

    private static List<Map.Entry<String, Long>> top(Map<String, Long> source) {
        return source.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue(Comparator.reverseOrder())
                        .thenComparing(Map.Entry.comparingByKey()))
                .limit(TOP_LIMIT)
                .toList();
    }

    static final class Metrics {
        private Instant start;
        private Instant end;
        private long events;
        private long dataLossEvents;
        private long threadDumpCount;
        private long executionSampleCount;
        private long nativeMethodSampleCount;
        private long allocationSampleCount;
        private long allocationSampleWeightBytes;
        private long gcCount;
        private long gcPauseNanos;
        private long gcLongestPauseNanos;
        private long parkCount;
        private long parkNanos;
        private long parkMaxNanos;
        private long monitorEnterCount;
        private long monitorEnterNanos;
        private long monitorEnterMaxNanos;
        private long virtualThreadPinnedCount;
        private long virtualThreadPinnedNanos;
        private long virtualThreadPinnedMaxNanos;
        private long virtualThreadSubmitFailedCount;
        private long socketReadCount;
        private long socketReadBytes;
        private long socketReadNanos;
        private long socketWriteCount;
        private long socketWriteBytes;
        private long socketWriteNanos;
        private long threadStartCount;
        private long threadEndCount;
        private long activeThreadsMax;
        private long peakThreadsMax;
        private final List<Double> activeThreadSamples = new ArrayList<>();
        private final List<Double> processCpuSamples = new ArrayList<>();
        private final List<Double> machineCpuSamples = new ArrayList<>();
        private final Map<String, Long> allocationByClass = new LinkedHashMap<>();
        private final Map<String, Long> allocationBySite = new LinkedHashMap<>();
        private final Map<String, Long> cpuSamplesByMethod = new LinkedHashMap<>();
        private final Map<String, Long> parksBySite = new LinkedHashMap<>();

        void accept(RecordedEvent event) {
            events++;
            Instant eventStart = event.getStartTime();
            Instant eventEnd = event.getEndTime();
            if (start == null || eventStart.isBefore(start)) {
                start = eventStart;
            }
            if (end == null || eventEnd.isAfter(end)) {
                end = eventEnd;
            }

            String type = event.getEventType().getName();
            switch (type) {
                case "jdk.DataLoss" -> dataLossEvents++;
                case "jdk.ThreadDump" -> threadDumpCount++;
                case "jdk.ExecutionSample" -> {
                    executionSampleCount++;
                    cpuSamplesByMethod.merge(topFrame(event), 1L, Long::sum);
                }
                case "jdk.NativeMethodSample" -> nativeMethodSampleCount++;
                case "jdk.ObjectAllocationSample" -> {
                    allocationSampleCount++;
                    long weight = event.hasField("weight") ? Math.max(0L, event.getLong("weight")) : 0L;
                    allocationSampleWeightBytes += weight;
                    allocationByClass.merge(allocatedClass(event), weight, Long::sum);
                    allocationBySite.merge(topFrame(event), weight, Long::sum);
                }
                case "jdk.GarbageCollection" -> {
                    gcCount++;
                    long sumPauses = durationFieldNanos(event, "sumOfPauses");
                    long longestPause = durationFieldNanos(event, "longestPause");
                    gcPauseNanos += sumPauses;
                    gcLongestPauseNanos = Math.max(gcLongestPauseNanos, longestPause);
                }
                case "jdk.ThreadPark" -> {
                    long duration = durationNanos(event);
                    parkCount++;
                    parkNanos += duration;
                    parkMaxNanos = Math.max(parkMaxNanos, duration);
                    parksBySite.merge(topFrame(event), 1L, Long::sum);
                }
                case "jdk.JavaMonitorEnter" -> {
                    long duration = durationNanos(event);
                    monitorEnterCount++;
                    monitorEnterNanos += duration;
                    monitorEnterMaxNanos = Math.max(monitorEnterMaxNanos, duration);
                }
                case "jdk.VirtualThreadPinned" -> {
                    long duration = durationNanos(event);
                    virtualThreadPinnedCount++;
                    virtualThreadPinnedNanos += duration;
                    virtualThreadPinnedMaxNanos = Math.max(virtualThreadPinnedMaxNanos, duration);
                }
                case "jdk.VirtualThreadSubmitFailed" -> virtualThreadSubmitFailedCount++;
                case "jdk.SocketRead" -> {
                    socketReadCount++;
                    socketReadNanos += durationNanos(event);
                    if (event.hasField("bytesRead")) {
                        socketReadBytes += Math.max(0L, event.getLong("bytesRead"));
                    }
                }
                case "jdk.SocketWrite" -> {
                    socketWriteCount++;
                    socketWriteNanos += durationNanos(event);
                    if (event.hasField("bytesWritten")) {
                        socketWriteBytes += Math.max(0L, event.getLong("bytesWritten"));
                    }
                }
                case "jdk.ThreadStart" -> threadStartCount++;
                case "jdk.ThreadEnd" -> threadEndCount++;
                case "jdk.JavaThreadStatistics" -> {
                    long active = event.getLong("activeCount");
                    long peak = event.getLong("peakCount");
                    activeThreadSamples.add((double) active);
                    activeThreadsMax = Math.max(activeThreadsMax, active);
                    peakThreadsMax = Math.max(peakThreadsMax, peak);
                }
                case "jdk.CPULoad" -> {
                    double process = event.getFloat("jvmUser") + event.getFloat("jvmSystem");
                    processCpuSamples.add(process * 100d);
                    machineCpuSamples.add(event.getFloat("machineTotal") * 100d);
                }
                default -> {
                    // Intentionally ignored. The binary recording remains the source of truth.
                }
            }
        }

        void finish() {
            if (start == null) {
                start = Instant.EPOCH;
            }
            if (end == null || end.isBefore(start)) {
                end = start;
            }
        }

        double recordingSeconds() {
            return Math.max(0d, Duration.between(start, end).toNanos() / 1_000_000_000d);
        }

        double allocationPressureMiBPerSecond() {
            double duration = recordingSeconds();
            return duration <= 0d ? Double.NaN : allocationSampleWeightBytes / BYTES_PER_MIB / duration;
        }

        String toJson() {
            StringBuilder out = new StringBuilder(8192);
            out.append("{\n");
            jsonString(out, "schema_version", "1.0", true);
            jsonString(out, "recording_start_utc", DateTimeFormatter.ISO_INSTANT.format(start), true);
            jsonString(out, "recording_end_utc", DateTimeFormatter.ISO_INSTANT.format(end), true);
            jsonNumber(out, "recording_duration_seconds", recordingSeconds(), true);
            jsonLong(out, "event_count", events, true);
            jsonLong(out, "data_loss_event_count", dataLossEvents, true);
            jsonLong(out, "thread_dump_count", threadDumpCount, true);
            jsonLong(out, "execution_sample_count", executionSampleCount, true);
            jsonLong(out, "native_method_sample_count", nativeMethodSampleCount, true);
            jsonLong(out, "allocation_sample_count", allocationSampleCount, true);
            jsonLong(out, "allocation_sample_weight_bytes", allocationSampleWeightBytes, true);
            jsonNumber(out, "allocation_sample_weight_mib", allocationSampleWeightBytes / BYTES_PER_MIB, true);
            jsonNumber(out, "allocation_pressure_mib_per_second", allocationPressureMiBPerSecond(), true);
            jsonLong(out, "gc_count", gcCount, true);
            jsonNumber(out, "gc_pause_total_ms", gcPauseNanos / 1_000_000d, true);
            jsonNumber(out, "gc_pause_max_ms", gcLongestPauseNanos / 1_000_000d, true);
            jsonLong(out, "thread_park_count", parkCount, true);
            jsonNumber(out, "thread_park_total_ms", parkNanos / 1_000_000d, true);
            jsonNumber(out, "thread_park_max_ms", parkMaxNanos / 1_000_000d, true);
            jsonLong(out, "monitor_enter_count", monitorEnterCount, true);
            jsonNumber(out, "monitor_enter_total_ms", monitorEnterNanos / 1_000_000d, true);
            jsonNumber(out, "monitor_enter_max_ms", monitorEnterMaxNanos / 1_000_000d, true);
            jsonLong(out, "virtual_thread_pinned_count", virtualThreadPinnedCount, true);
            jsonNumber(out, "virtual_thread_pinned_total_ms", virtualThreadPinnedNanos / 1_000_000d, true);
            jsonNumber(out, "virtual_thread_pinned_max_ms", virtualThreadPinnedMaxNanos / 1_000_000d, true);
            jsonLong(out, "virtual_thread_submit_failed_count", virtualThreadSubmitFailedCount, true);
            jsonLong(out, "socket_read_count", socketReadCount, true);
            jsonLong(out, "socket_read_bytes", socketReadBytes, true);
            jsonNumber(out, "socket_read_total_ms", socketReadNanos / 1_000_000d, true);
            jsonLong(out, "socket_write_count", socketWriteCount, true);
            jsonLong(out, "socket_write_bytes", socketWriteBytes, true);
            jsonNumber(out, "socket_write_total_ms", socketWriteNanos / 1_000_000d, true);
            jsonLong(out, "thread_start_count", threadStartCount, true);
            jsonLong(out, "thread_end_count", threadEndCount, true);
            jsonNumber(out, "active_threads_average", average(activeThreadSamples), true);
            jsonLong(out, "active_threads_max", activeThreadsMax, true);
            jsonLong(out, "peak_threads_max", peakThreadsMax, true);
            jsonNumber(out, "process_cpu_average_percent", average(processCpuSamples), true);
            jsonNumber(out, "process_cpu_p95_percent", percentile(processCpuSamples, 0.95d), true);
            jsonNumber(out, "machine_cpu_average_percent", average(machineCpuSamples), true);
            jsonTop(out, "top_allocation_classes", top(allocationByClass), "weight_bytes", true);
            jsonTop(out, "top_allocation_sites", top(allocationBySite), "weight_bytes", true);
            jsonTop(out, "top_cpu_sampled_methods", top(cpuSamplesByMethod), "samples", true);
            jsonTop(out, "top_thread_park_sites", top(parksBySite), "events", false);
            out.append("}\n");
            return out.toString();
        }

        String toMarkdown(String recordingName) {
            StringBuilder md = new StringBuilder(8192);
            md.append("# JFR Metrics — `").append(recordingName).append("`\n\n");
            md.append("> Values are automated observations from the bounded JFR window. Allocation values are sample weights (estimated pressure), not exact retained heap.\n\n");
            md.append("| Metric | Value |\n|---|---:|\n");
            row(md, "Recording duration", format(recordingSeconds()) + " s");
            row(md, "JVM CPU average", format(average(processCpuSamples)) + " %");
            row(md, "JVM CPU p95", format(percentile(processCpuSamples, 0.95d)) + " %");
            row(md, "Allocation sample weight", format(allocationSampleWeightBytes / BYTES_PER_MIB) + " MiB");
            row(md, "Allocation pressure", format(allocationPressureMiBPerSecond()) + " MiB/s");
            row(md, "GC count", Long.toString(gcCount));
            row(md, "GC pause total", format(gcPauseNanos / 1_000_000d) + " ms");
            row(md, "GC pause max", format(gcLongestPauseNanos / 1_000_000d) + " ms");
            row(md, "Active platform threads avg / max", format(average(activeThreadSamples)) + " / " + activeThreadsMax);
            row(md, "Thread parks count / total", parkCount + " / " + format(parkNanos / 1_000_000d) + " ms");
            row(md, "Monitor enters count / total", monitorEnterCount + " / " + format(monitorEnterNanos / 1_000_000d) + " ms");
            row(md, "Virtual-thread pinned count / total", virtualThreadPinnedCount + " / " + format(virtualThreadPinnedNanos / 1_000_000d) + " ms");
            row(md, "Virtual-thread submit failures", Long.toString(virtualThreadSubmitFailedCount));
            row(md, "JFR data-loss events", Long.toString(dataLossEvents));

            appendTop(md, "Top allocation classes", top(allocationByClass), "Sample weight MiB", true);
            appendTop(md, "Top allocation sites", top(allocationBySite), "Sample weight MiB", true);
            appendTop(md, "Top sampled CPU methods", top(cpuSamplesByMethod), "Samples", false);
            appendTop(md, "Top thread-park sites", top(parksBySite), "Events", false);

            md.append("\n## Guardrails\n\n");
            md.append("- JFR method profiling is sampling-based; a top method is not automatically an optimization target.\n");
            md.append("- `ObjectAllocationSample.weight` estimates allocation pressure; it is not retained heap.\n");
            md.append("- Events below configured thresholds are intentionally absent.\n");
            md.append("- Zero pinned-thread events means none were observed above the configured threshold in this run.\n");
            return md.toString();
        }

        private static void appendTop(StringBuilder md, String title, List<Map.Entry<String, Long>> rows, String valueTitle, boolean bytes) {
            md.append("\n## ").append(title).append("\n\n");
            if (rows.isEmpty()) {
                md.append("No events observed.\n");
                return;
            }
            md.append("| Rank | Symbol | ").append(valueTitle).append(" |\n|---:|---|---:|\n");
            int rank = 1;
            for (Map.Entry<String, Long> row : rows) {
                String value = bytes ? format(row.getValue() / BYTES_PER_MIB) : Long.toString(row.getValue());
                md.append("| ").append(rank++).append(" | `").append(escapeMarkdown(row.getKey())).append("` | ").append(value).append(" |\n");
            }
        }

        private static void row(StringBuilder md, String key, String value) {
            md.append("| ").append(key).append(" | ").append(value).append(" |\n");
        }

        private static String format(double value) {
            return Double.isFinite(value) ? String.format(Locale.ROOT, "%.3f", value) : "n/a";
        }

        private static String escapeMarkdown(String value) {
            return value.replace("|", "\\|").replace("`", "'");
        }

        private static void jsonString(StringBuilder out, String key, String value, boolean comma) {
            out.append("  \"").append(jsonEscape(key)).append("\": \"").append(jsonEscape(value)).append("\"");
            out.append(comma ? ",\n" : "\n");
        }

        private static void jsonLong(StringBuilder out, String key, long value, boolean comma) {
            out.append("  \"").append(jsonEscape(key)).append("\": ").append(value);
            out.append(comma ? ",\n" : "\n");
        }

        private static void jsonNumber(StringBuilder out, String key, double value, boolean comma) {
            out.append("  \"").append(jsonEscape(key)).append("\": ");
            if (Double.isFinite(value)) {
                out.append(String.format(Locale.ROOT, "%.9f", value));
            } else {
                out.append("null");
            }
            out.append(comma ? ",\n" : "\n");
        }

        private static void jsonTop(StringBuilder out, String key, List<Map.Entry<String, Long>> rows, String valueKey, boolean comma) {
            out.append("  \"").append(jsonEscape(key)).append("\": [");
            if (!rows.isEmpty()) {
                out.append("\n");
                for (int i = 0; i < rows.size(); i++) {
                    Map.Entry<String, Long> row = rows.get(i);
                    out.append("    {\"name\": \"").append(jsonEscape(row.getKey())).append("\", \"")
                            .append(jsonEscape(valueKey)).append("\": ").append(row.getValue()).append("}");
                    out.append(i + 1 < rows.size() ? ",\n" : "\n");
                }
                out.append("  ");
            }
            out.append("]");
            out.append(comma ? ",\n" : "\n");
        }

        private static String jsonEscape(String value) {
            StringBuilder escaped = new StringBuilder(value.length() + 16);
            for (int i = 0; i < value.length(); i++) {
                char c = value.charAt(i);
                switch (c) {
                    case '\\' -> escaped.append("\\\\");
                    case '"' -> escaped.append("\\\"");
                    case '\n' -> escaped.append("\\n");
                    case '\r' -> escaped.append("\\r");
                    case '\t' -> escaped.append("\\t");
                    default -> {
                        if (c < 0x20) {
                            escaped.append(String.format(Locale.ROOT, "\\u%04x", (int) c));
                        } else {
                            escaped.append(c);
                        }
                    }
                }
            }
            return escaped.toString();
        }
    }
}
