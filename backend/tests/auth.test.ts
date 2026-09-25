import request from 'supertest';
import { app } from '../src/app';

describe('Authentication & Authorization API Tests', () => {
  let officerToken: string;
  let workerToken: string;

  it('POST /api/auth/login - should authenticate Municipal Officer with valid credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'officer@demo.com',
        password: 'Officer@123',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.role).toBe('municipalOfficer');
    expect(res.body.data.user.email).toBe('officer@demo.com');
    officerToken = res.body.data.token;
  });

  it('POST /api/auth/login - should authenticate Field Worker with valid credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'worker@demo.com',
        password: 'Worker@123',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.role).toBe('fieldWorker');
    expect(res.body.data.user.workerId).toBe('WRK-001');
    workerToken = res.body.data.token;
  });

  it('POST /api/auth/login - should reject invalid password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'officer@demo.com',
        password: 'WrongPassword999!',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('INVALID_CREDENTIALS');
  });

  it('GET /api/auth/me - should return authenticated user profile', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${officerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.email).toBe('officer@demo.com');
  });

  it('GET /api/auth/me - should reject request without token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/auth/register - should register a new field technician', async () => {
    const uniqueEmail = `technician_${Date.now()}@waterwatch.gov.in`;
    const uniqueWorkerId = `WRK-${Math.floor(100 + Math.random() * 900)}`;

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        fullName: 'Test Technician',
        email: uniqueEmail,
        password: 'Worker@123',
        workerId: uniqueWorkerId,
        zone: 'East Industrial Sector',
        department: 'Field Engineering & Maintenance',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe('fieldWorker');
    expect(res.body.data.user.workerId).toBe(uniqueWorkerId);
  });
});
