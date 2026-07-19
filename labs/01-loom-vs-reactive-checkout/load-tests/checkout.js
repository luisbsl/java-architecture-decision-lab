import http from 'k6/http';
import { check } from 'k6';
import exec from 'k6/execution';
import { Counter, Rate, Trend } from 'k6/metrics';

const scenarioName = __ENV.SCENARIO || 'functional';
const baseUrl = __ENV.BASE_URL || 'http://localhost:8081';
const implementation = __ENV.IMPLEMENTATION || 'mvc-vthreads';
const runId = (__ENV.RUN_ID || 'adhoc').replace(/[^a-zA-Z0-9_-]/g, '-');
const pair = (__ENV.PAIR || '0').replace(/[^a-zA-Z0-9_-]/g, '-');
const workloadSeed = (__ENV.WORKLOAD_SEED || '20260718').replace(/[^a-zA-Z0-9_-]/g, '-');

const businessFailures = new Counter('checkout_business_failures');
const confirmedRate = new Rate('checkout_confirmed_rate');
const checkoutLatency = new Trend('checkout_end_to_end_duration', true);

const scenarioProfiles = {
  functional: {
    executor: 'shared-iterations',
    vus: 1,
    iterations: 1,
    maxDuration: '30s',
  },
  moderate: {
    executor: 'constant-arrival-rate',
    rate: Number(__ENV.RATE || 25),
    timeUnit: '1s',
    duration: __ENV.DURATION || '60s',
    preAllocatedVUs: Number(__ENV.PRE_ALLOCATED_VUS || 25),
    maxVUs: Number(__ENV.MAX_VUS || 100),
  },
  high: {
    executor: 'constant-arrival-rate',
    rate: Number(__ENV.RATE || 150),
    timeUnit: '1s',
    duration: __ENV.DURATION || '120s',
    preAllocatedVUs: Number(__ENV.PRE_ALLOCATED_VUS || 180),
    maxVUs: Number(__ENV.MAX_VUS || 240),
  },
  capacity: {
    executor: 'constant-vus',
    vus: Number(__ENV.VUS || 200),
    duration: __ENV.DURATION || '120s',
    gracefulStop: __ENV.GRACEFUL_STOP || '10s',
  },
  'slow-payment': {
    executor: 'constant-arrival-rate',
    rate: Number(__ENV.RATE || 10),
    timeUnit: '1s',
    duration: __ENV.DURATION || '60s',
    preAllocatedVUs: Number(__ENV.PRE_ALLOCATED_VUS || 20),
    maxVUs: Number(__ENV.MAX_VUS || 100),
  },
  'intermittent-failures': {
    executor: 'constant-arrival-rate',
    rate: Number(__ENV.RATE || 10),
    timeUnit: '1s',
    duration: __ENV.DURATION || '60s',
    preAllocatedVUs: Number(__ENV.PRE_ALLOCATED_VUS || 20),
    maxVUs: Number(__ENV.MAX_VUS || 100),
  },
};

if (!(scenarioName in scenarioProfiles)) {
  throw new Error(`Unsupported SCENARIO: ${scenarioName}`);
}

const allowedFailureRate = scenarioName === 'intermittent-failures' ? 0.20 : 0.01;

export const options = {
  scenarios: {
    checkout: scenarioProfiles[scenarioName],
  },
  thresholds: {
    http_req_failed: [`rate<${allowedFailureRate}`],
    checks: ['rate>0.99'],
    checkout_confirmed_rate: [
      scenarioName === 'intermittent-failures' ? 'rate>0.75' : 'rate>0.99',
    ],
    checkout_end_to_end_duration: [
      `p(95)<${Number(__ENV.P95_THRESHOLD_MS || 2500)}`,
      `p(99)<${Number(__ENV.P99_THRESHOLD_MS || 4000)}`,
    ],
    dropped_iterations: ['count==0'],
  },
  tags: {
    implementation,
    scenario: scenarioName,
  },
  discardResponseBodies: false,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

export default function () {
  const iteration = exec.scenario.iterationInTest;
  const workloadId = `${workloadSeed}-${scenarioName}-pair${pair}-iteration${iteration}`;
  const orderId = `order-${workloadId}`;
  const payload = JSON.stringify({
    orderId,
    customerId: 'customer-001',
    items: [{ sku: 'SKU-001', quantity: 2, unitPrice: 149.90 }],
    currency: 'BRL',
  });

  const response = http.post(`${baseUrl}/orders/checkout`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'X-Correlation-Id': `k6-${workloadId}`,
      'X-Workload-Id': workloadId,
    },
    tags: {
      operation: 'checkout',
      implementation,
      scenario: scenarioName,
    },
    timeout: __ENV.REQUEST_TIMEOUT || '5s',
  });

  checkoutLatency.add(response.timings.duration, {
    implementation,
    scenario: scenarioName,
  });

  let body = null;
  try {
    body = response.json();
  } catch (_) {
    body = null;
  }

  const confirmed = response.status === 201 && body?.status === 'CONFIRMED';
  confirmedRate.add(confirmed, { implementation, scenario: scenarioName });
  if (!confirmed && response.status >= 400) {
    businessFailures.add(1, {
      implementation,
      scenario: scenarioName,
      status: String(response.status),
    });
  }

  check(response, {
    'status is expected': (res) => scenarioName === 'intermittent-failures'
      ? [201, 503].includes(res.status)
      : res.status === 201,
    'confirmed response has order id': () => !confirmed || body?.orderId === orderId,
    'correlation id is returned': (res) => Boolean(res.headers['X-Correlation-Id']),
  });
}

export function handleSummary(data) {
  const summaryPath = __ENV.SUMMARY_PATH
    || `load-tests/results/${implementation}-${scenarioName}-summary.json`;
  const compact = {
    implementation,
    scenario: scenarioName,
    generatedAt: new Date().toISOString(),
    runId,
    pair,
    workloadSeed,
    loadModel: scenarioProfiles[scenarioName].executor,
    configuredRate: scenarioProfiles[scenarioName].rate || null,
    configuredVUs: scenarioProfiles[scenarioName].vus || null,
    metrics: data.metrics,
    rootGroup: data.root_group,
    state: data.state,
  };

  return {
    stdout: `${JSON.stringify(compact, null, 2)}\n`,
    [summaryPath]: JSON.stringify(data, null, 2),
  };
}
