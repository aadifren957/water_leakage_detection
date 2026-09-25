import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function hash(pwd: string) {
  return bcrypt.hash(pwd, 10);
}

async function cleanData() {
  console.log('🧹 Clearing WaterWatch sample data from Supabase PostgreSQL...');
  await prisma.$connect();

  // 1. Delete all notifications, history, incidents, and telemetry readings
  const delNotifs = await prisma.notification.deleteMany({});
  console.log(`🗑️ Deleted ${delNotifs.count} notification records.`);

  const delHistories = await prisma.incidentHistory.deleteMany({});
  console.log(`🗑️ Deleted ${delHistories.count} incident history records.`);

  const delIncidents = await prisma.incident.deleteMany({});
  console.log(`🗑️ Deleted ${delIncidents.count} sample incident records.`);

  const delReadings = await prisma.sensorReading.deleteMany({});
  console.log(`🗑️ Deleted ${delReadings.count} sample sensor readings.`);

  // 2. Ensure default login accounts exist with zero active tasks
  const officerHash = await hash('Officer@123');
  await prisma.user.upsert({
    where: { email: 'officer@demo.com' },
    update: {
      fullName: 'Rajesh Varma',
      passwordHash: officerHash,
      role: Role.OFFICER,
      department: 'Municipal Water Supply & Sewerage Board',
      phoneNumber: '+91 98765 43210',
      zone: 'Central City Zone',
      isActive: true,
    },
    create: {
      fullName: 'Rajesh Varma',
      email: 'officer@demo.com',
      passwordHash: officerHash,
      role: Role.OFFICER,
      department: 'Municipal Water Supply & Sewerage Board',
      phoneNumber: '+91 98765 43210',
      zone: 'Central City Zone',
      isActive: true,
    },
  });

  const workerHash = await hash('Worker@123');
  const workers = [
    { email: 'worker@demo.com', name: 'Rahul Patil', workerId: 'WRK-001', zone: 'North & Central Distribution Grid' },
    { email: 'priya@demo.com', name: 'Priya Sharma', workerId: 'WRK-002', zone: 'South Industrial Zone' },
    { email: 'amit@demo.com', name: 'Amit Kumar', workerId: 'WRK-003', zone: 'East Commercial Ring' },
    { email: 'neha@demo.com', name: 'Neha Kulkarni', workerId: 'WRK-004', zone: 'West Residential Grid' },
  ];

  // Clean existing workers to avoid workerId collisions
  await prisma.user.deleteMany({
    where: { role: Role.WORKER },
  });

  for (const w of workers) {
    await prisma.user.create({
      data: {
        fullName: w.name,
        email: w.email,
        passwordHash: workerHash,
        role: Role.WORKER,
        workerId: w.workerId,
        department: 'Field Engineering & Maintenance',
        phoneNumber: '+91 98111 22233',
        zone: w.zone,
        isActive: true,
      },
    });
  }

  console.log('✨ All sample data wiped to ZERO! Database is now a clean slate.');
  console.log('   - Active Leaks: 0');
  console.log('   - Identified: 0');
  console.log('   - Acknowledged: 0');
  console.log('   - Assigned: 0');
  console.log('   - Resolved: 0');
  console.log('   - Sensor Readings: 0');
  console.log('   - User accounts ready for login.');
}

cleanData()
  .catch((e) => {
    console.error('❌ Clean data error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
