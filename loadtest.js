import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';

// ==== Step 1. Load payloads once ====
const payloads = new SharedArray('payloads', function () {
  const arr = [];
  for (let i = 1; i <= 100; i++) {
    try {
      const data = open(`./payloads/payload${i}.json`);
      arr.push(data.replace(/\n/g, ''));
    } catch (e) {
      break;
    }
  }
  return arr;
});

const authUrl = 'https://dotrezapi.test.6e.navitaire.com/api/nsk/v2/token';
const apiBase = 'http://host.containers.internal:5237/checkin/v1/journeys/retrieve';

// ==== Step 2. Setup (runs once before test) ====
export function setup() {
  const authPayload = JSON.stringify({ applicationName: 'mobile' });
  const authHeaders = { 'Content-Type': 'application/json', accept: 'application/json' };

  const res = http.post(authUrl, authPayload, { headers: authHeaders });

  if (res.status !== 200 && res.status !== 201) {
    throw new Error(`Failed to fetch token: ${res.status} ${res.body}`);
  }

  let body;
  try {
    body = JSON.parse(res.body);
  } catch (e) {
    throw new Error(`Auth response is not JSON: ${res.body}`);
  }

  const token = body && body.data && body.data.token;
  if (!token) {
    throw new Error(`No token found in response: ${res.body}`);
  }

  console.log(`[INFO] Token retrieved successfully (status ${res.status}).`);
  return { token };
}

// ==== Step 3. Load test options (like siege) ====
export const options = {
  vus: 11,
  duration: '60s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(99)<1000'],
  },
};

// ==== Step 4. Default function (each VU executes this) ====
export default function (data) {
  const token = data.token;
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


