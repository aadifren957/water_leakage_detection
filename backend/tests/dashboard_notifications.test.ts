import request from 'supertest';
import { app } from '../src/app';

describe('Dashboard, Notifications & IoT Ingestion Tests', () => {
  let officerToken: string;
  let workerToken: string;

  beforeAll(async () => {
    const offRes = await request(app).post('/api/auth/login').send({
      email: 'officer@demo.com',
      password: 'Officer@123',
    });
    officerToken = offRes.body.data.token;

    const wrkRes = await request(app).post('/api/auth/login').send({
      email: 'worker@demo.com',
      password: 'Worker@123',
    });
    workerToken = wrkRes.body.data.token;
  });

  it('GET /api/dashboard/officer - returns accurate aggregated statistics', async () => {
    const res = await request(app)
      .get('/api/dashboard/officer')
      .set('Authorization', `Bearer ${officerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.stats.totalActive).toBeDefined();
    expect(res.body.data.recentIncidents).toBeInstanceOf(Array);
    expect(res.body.data.sensors).toBeInstanceOf(Array);
  });

  it('GET /api/dashboard/worker - returns worker specific metrics and task spotlight', async () => {
    const res = await request(app)
      .get('/api/dashboard/worker')
      .set('Authorization', `Bearer ${workerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.stats.newAssignments).toBeDefined();
    expect(res.body.data.activeTasks).toBeInstanceOf(Array);
  });

  it('GET /api/notifications - returns notifications for authenticated user', async () => {
    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${workerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeInstanceOf(Array);
  });

  it('POST /api/iot/readings - rejects ingestion with missing or invalid API key', async () => {
    const res = await request(app)
      .post('/api/iot/readings')
      .send({
        deviceId: 'WLS-TEST-01',
        flowRate: 4.5,
      });

    expect(res.status).toBe(401);
  });

  it('POST /api/iot/readings - ingests valid telemetry reading with X-API-Key', async () => {
    const res = await request(app)
      .post('/api/iot/readings')
      .set('X-API-Key', 'waterwatch_iot_esp8266_node_ingest_key_2026')
      .send({
        deviceId: 'WLS-ESP-001',
        deviceName: 'ESP8266 Node North Pipeline',
        location: 'North Pipeline Sub-Ring Gate 4',
        flowRate: 3.45,
        totalLiters: 120.5,
        normalBaselineFlowRate: 3.5,
        leakageDetected: false,
        pumpStatus: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.deviceId).toBe('WLS-ESP-001');
  });
});
