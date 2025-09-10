import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';

// ==== Externalized Configuration ====
const authUrl = __ENV.AUTH_URL || 'https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token';
const apiBase = __ENV.API_BASE || 'http://localhost:5237/checkin/v1/journeys/retrieve';
const tokenPoolSize = parseInt(__ENV.TOKEN_POOL_SIZE || '11');
const vus = parseInt(__ENV.VUS || '11');
const duration = __ENV.DURATION || '20s';

// ==== Step 1. Load payloads once ====
const payloads = new SharedArray('payloads', function () {
  const arr = [];
  let i = 1;
  
  // Keep trying until no more files found
  while (true) {
    try {
      const data = open(`./payloads/payload${i}.json`);
      arr.push(data.replace(/\n/g, ''));
      i++;
    } catch (e) {
      // No more files found
      break;
    }
  }
  
  console.log(`[INFO] Loaded ${arr.length} payload files`);
  return arr;
});


// ==== Step 2. Setup (runs once before test) ====
export function setup() {
  const authPayload = JSON.stringify({ applicationName: 'mobile' });
  const authHeaders = { 'Content-Type': 'application/json', accept: 'application/json' };

  // Generate token pool instead of single token
  const tokens = [];
  
  for (let i = 0; i < tokenPoolSize; i++) {
    const res = http.post(authUrl, authPayload, { headers: authHeaders });
    
    if (res.status !== 200 && res.status !== 201) {
      throw new Error(`Failed to fetch token ${i}: ${res.status} ${res.body}`);
    }
    
    const body = JSON.parse(res.body);
    const token = body && body.data && body.data.token;
    if (!token) {
      throw new Error(`No token found in response ${i}: ${res.body}`);
    }
    
    tokens.push(token);
  }

  console.log(`[INFO] Generated ${tokens.length} tokens for pool.`);
  return { tokens };
}


// ==== Step 3. Load test options ====
export const options = {
  vus: vus,
  duration: duration,
  summaryTrendStats: ['min', 'med', 'avg', 'p(90)', 'p(95)', 'p(99)', 'max'],
  summaryTimeUnit: 'ms',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(99)<1000'],
  },
};

// ==== Step 4. Default function (each VU executes this) ====
export default function (data) {
  // Each VU gets assigned token from pool (round-robin)
  const token = data.tokens[(__VU - 1) % data.tokens.length];
  const payload = payloads[Math.floor(Math.random() * payloads.length)];

  const res = http.post(apiBase, payload, {
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  check(res, { 'status is 200': (r) => r.status === 200 });

  sleep(0.1);
}


