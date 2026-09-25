import request from 'supertest';
import { app } from '../src/app';

describe('Incident Lifecycle & State Machine API Tests', () => {
  let officerToken: string;
  let workerToken: string;
  let createdIncidentId: string;

  beforeAll(async () => {
    // Log in officer
    const offRes = await request(app).post('/api/auth/login').send({
      email: 'officer@demo.com',
      password: 'Officer@123',
    });
    officerToken = offRes.body.data.token;

    // Log in worker
    const wrkRes = await request(app).post('/api/auth/login').send({
      email: 'worker@demo.com',
      password: 'Worker@123',
    });
    workerToken = wrkRes.body.data.token;
  });

  it('1. Create Incident - Officer should create a new IDENTIFIED incident', async () => {
    const res = await request(app)
      .post('/api/incidents')
      .set('Authorization', `Bearer ${officerToken}`)
      .send({
        title: 'Sector 5 Underground Feeder Leak',
        description: 'Sensor node WLS-008 recorded abnormal continuous flow of 9.20 L/min.',
        location: 'Sector 5 Main Crossing Gate 2',
        zone: 'Central City Zone',
        deviceId: 'WLS-008',
        flowRate: 9.20,
        totalLiters: 110.0,
        leakageDetected: true,
        pumpStatus: false,
        severity: 'HIGH',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('identified');
    expect(res.body.data.id).toMatch(/^INC-\d{4}-\d{3}$/);
    createdIncidentId = res.body.data.id;
  });

  it('2. Invalid Transition - Cannot assign worker before acknowledging incident', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/assign`)
      .set('Authorization', `Bearer ${officerToken}`)
      .send({ workerId: 'WRK-001' });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('INVALID_TRANSITION');
  });

  it('3. Worker Forbidden - Worker cannot acknowledge an incident', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/acknowledge`)
      .set('Authorization', `Bearer ${workerToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('4. Acknowledge Incident - Officer acknowledges IDENTIFIED -> ACKNOWLEDGED', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/acknowledge`)
      .set('Authorization', `Bearer ${officerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('acknowledged');
    expect(res.body.data.acknowledgedAt).toBeDefined();
    expect(res.body.data.acknowledgedBy).toBe('Rajesh Varma');
  });

  it('5. Invalid Transition - Cannot acknowledge already acknowledged incident', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/acknowledge`)
      .set('Authorization', `Bearer ${officerToken}`);

    expect(res.status).toBe(409);
    expect(res.body.code).toBe('INVALID_TRANSITION');
  });

  it('6. Assign Worker - Officer assigns worker ACKNOWLEDGED -> ASSIGNED', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/assign`)
      .set('Authorization', `Bearer ${officerToken}`)
      .send({ workerId: 'WRK-001' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('assigned');
    expect(res.body.data.assignedWorkerId).toBe('WRK-001');
    expect(res.body.data.assignedWorkerName).toBe('Rahul Patil');
    expect(res.body.data.assignedAt).toBeDefined();
  });

  it('7. Officer Forbidden - Officer cannot directly resolve without technician repair note', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/resolve`)
      .set('Authorization', `Bearer ${officerToken}`)
      .send({ repairNotes: 'Resolved by officer override' });

    expect(res.status).toBe(403);
  });

  it('8. Resolve Incident - Assigned Worker resolves ASSIGNED -> RESOLVED', async () => {
    const res = await request(app)
      .patch(`/api/incidents/${createdIncidentId}/resolve`)
      .set('Authorization', `Bearer ${workerToken}`)
      .send({
        repairNotes: 'Replaced 4-inch ductile iron pipe segment and pressure tested to 4.8 bar.',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('resolved');
    expect(res.body.data.resolvedBy).toBe('Rahul Patil');
    expect(res.body.data.repairNotes).toContain('Replaced 4-inch ductile iron pipe segment');
    expect(res.body.data.isPumpOn).toBe(true);
  });

  it('9. Incident History - History should contain all chronological audit events', async () => {
    const res = await request(app)
      .get(`/api/incidents/${createdIncidentId}/history`)
      .set('Authorization', `Bearer ${officerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(4); // Detected, Acknowledged, Assigned, Resolved
  });
});
