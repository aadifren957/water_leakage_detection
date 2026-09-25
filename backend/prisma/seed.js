"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const prisma = new client_1.PrismaClient();
async function hash(pwd) {
    return bcryptjs_1.default.hash(pwd, 10);
}
async function main() {
    console.log('🌱 Seeding WaterWatch Supabase Database...');
    await prisma.$connect();
    // 1. Create or update Municipal Officer
    const officerHash = await hash('Officer@123');
    const officer = await prisma.user.upsert({
        where: { email: 'officer@demo.com' },
        update: {
            fullName: 'Rajesh Varma',
            passwordHash: officerHash,
            role: client_1.Role.OFFICER,
            department: 'Municipal Water Supply & Sewerage Board',
            phoneNumber: '+91 98765 43210',
            zone: 'Central City Zone',
            isActive: true,
        },
        create: {
            fullName: 'Rajesh Varma',
            email: 'officer@demo.com',
            passwordHash: officerHash,
            role: client_1.Role.OFFICER,
            department: 'Municipal Water Supply & Sewerage Board',
            phoneNumber: '+91 98765 43210',
            zone: 'Central City Zone',
            isActive: true,
        },
    });
    console.log(`👤 Officer created/verified: ${officer.email} (${officer.id})`);
    // 2. Create or update Field Workers
    const workerHash = await hash('Worker@123');
    const workerRahul = await prisma.user.upsert({
        where: { email: 'worker@demo.com' },
        update: {
            fullName: 'Rahul Patil',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-001',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98111 22233',
            zone: 'North & Central Distribution Grid',
            isActive: true,
        },
        create: {
            fullName: 'Rahul Patil',
            email: 'worker@demo.com',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-001',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98111 22233',
            zone: 'North & Central Distribution Grid',
            isActive: true,
        },
    });
    const workerPriya = await prisma.user.upsert({
        where: { email: 'priya.sharma@waterwatch.gov.in' },
        update: {
            fullName: 'Priya Sharma',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-002',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98222 33344',
            zone: 'South Industrial Zone',
            isActive: true,
        },
        create: {
            fullName: 'Priya Sharma',
            email: 'priya.sharma@waterwatch.gov.in',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-002',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98222 33344',
            zone: 'South Industrial Zone',
            isActive: true,
        },
    });
    const workerAmit = await prisma.user.upsert({
        where: { email: 'amit.kumar@waterwatch.gov.in' },
        update: {
            fullName: 'Amit Kumar',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-003',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98333 44455',
            zone: 'East Commercial Ring',
            isActive: true,
        },
        create: {
            fullName: 'Amit Kumar',
            email: 'amit.kumar@waterwatch.gov.in',
            passwordHash: workerHash,
            role: client_1.Role.WORKER,
            workerId: 'WRK-003',
            department: 'Field Engineering & Maintenance',
            phoneNumber: '+91 98333 44455',
            zone: 'East Commercial Ring',
            isActive: true,
        },
    });
    console.log(`👷 Field Workers seeded: Rahul (${workerRahul.workerId}), Priya (${workerPriya.workerId}), Amit (${workerAmit.workerId})`);
    // 3. Seed Sensors & Baseline Readings via createMany
    const sensorsData = [
        {
            deviceId: 'WLS-001',
            deviceName: 'Sector 4 Main Supply Line Flow Node',
            location: 'Sector 4, Main Pipeline Junction',
            flowRate: 8.45,
            totalLiters: 142.8,
            leakageDetected: true,
            pumpStatus: false,
        },
        {
            deviceId: 'WLS-002',
            deviceName: 'Sector 9 Industrial Booster Feed',
            location: 'Sector 9, Ring Road Junction',
            flowRate: 3.52,
            totalLiters: 48.2,
            leakageDetected: false,
            pumpStatus: true,
        },
        {
            deviceId: 'WLS-003',
            deviceName: 'Sector 2 Commercial Gateway Node',
            location: 'Sector 2, Commercial Boulevard',
            flowRate: 3.48,
            totalLiters: 220.5,
            leakageDetected: false,
            pumpStatus: true,
        },
    ];
    const readingRows = [];
    const now = Date.now();
    for (const s of sensorsData) {
        for (let i = 11; i >= 0; i--) {
            const timeOffset = new Date(now - i * 3600 * 1000);
            const isLatest = i === 0;
            readingRows.push({
                deviceId: s.deviceId,
                deviceName: s.deviceName,
                location: s.location,
                flowRate: isLatest ? s.flowRate : 3.4 + Math.sin(i) * 0.3,
                totalLiters: s.totalLiters + (11 - i) * 12.5,
                normalBaselineFlowRate: 3.5,
                leakageDetected: isLatest ? s.leakageDetected : false,
                pumpStatus: isLatest ? s.pumpStatus : true,
                isOnline: true,
                recordedAt: timeOffset,
            });
        }
    }
    // Clear existing sensor readings and batch insert
    await prisma.sensorReading.deleteMany({});
    await prisma.sensorReading.createMany({ data: readingRows });
    console.log('📡 Sensor telemetry nodes & history batch inserted.');
    // 4. Seed Baseline Incidents across all 4 stages
    const existingIncidents = await prisma.incident.count();
    if (existingIncidents === 0) {
        // Incident 1: IDENTIFIED
        const inc1 = await prisma.incident.create({
            data: {
                incidentCode: 'INC-2026-001',
                title: 'Sector 4 Main Supply Line Rupture',
                description: 'ESP8266 IoT Node WLS-001 recorded abnormal flow rate of 8.45 L/min. Automatic safety shutoff active.',
                location: 'Sector 4, Main Pipeline Junction',
                zone: 'Central City Zone',
                deviceId: 'WLS-001',
                flowRate: 8.45,
                totalLiters: 142.8,
                leakageDetected: true,
                pumpStatus: false,
                severity: client_1.Severity.CRITICAL,
                status: client_1.IncidentStatus.IDENTIFIED,
            },
        });
        await prisma.incidentHistory.create({
            data: {
                incidentId: inc1.id,
                actorName: 'ESP8266 Telemetry Engine',
                actorRole: 'IoT Sensor Node',
                action: 'DETECTED',
                newStatus: client_1.IncidentStatus.IDENTIFIED,
                note: 'Leakage Detected',
                metadata: { description: 'Abnormal flow rate of 8.45 L/min detected. Pump shutoff activated.' },
            },
        });
        await prisma.notification.create({
            data: {
                recipientId: officer.id,
                recipientRole: client_1.Role.OFFICER,
                title: 'New Leakage Alert: INC-2026-001',
                message: 'Critical flow anomaly 8.45 L/min detected at Sector 4, Main Pipeline Junction.',
                type: client_1.NotificationType.LEAK_DETECTED,
                incidentId: inc1.id,
            },
        });
        // Incident 2: ACKNOWLEDGED
        const inc2 = await prisma.incident.create({
            data: {
                incidentCode: 'INC-2026-002',
                title: 'Sector 7 Secondary Distribution Flange Leak',
                description: 'Pressure drop and persistent 6.20 L/min flow rate anomaly.',
                location: 'Sector 7, Market Road Sub-Line',
                zone: 'North & Central Distribution Grid',
                deviceId: 'WLS-004',
                flowRate: 6.20,
                totalLiters: 88.4,
                leakageDetected: true,
                pumpStatus: false,
                severity: client_1.Severity.HIGH,
                status: client_1.IncidentStatus.ACKNOWLEDGED,
                acknowledgedAt: new Date(Date.now() - 45 * 60 * 1000),
                acknowledgedBy: officer.fullName,
            },
        });
        await prisma.incidentHistory.createMany({
            data: [
                {
                    incidentId: inc2.id,
                    actorName: 'ESP8266 Telemetry Engine',
                    actorRole: 'IoT Sensor Node',
                    action: 'DETECTED',
                    newStatus: client_1.IncidentStatus.IDENTIFIED,
                    note: 'Leakage Detected',
                    createdAt: new Date(Date.now() - 60 * 60 * 1000),
                },
                {
                    incidentId: inc2.id,
                    actorId: officer.id,
                    actorName: officer.fullName,
                    actorRole: 'Municipal Officer',
                    action: 'ACKNOWLEDGED',
                    previousStatus: client_1.IncidentStatus.IDENTIFIED,
                    newStatus: client_1.IncidentStatus.ACKNOWLEDGED,
                    note: 'Acknowledged by Municipal Officer',
                    createdAt: new Date(Date.now() - 45 * 60 * 1000),
                },
            ],
        });
        // Incident 3: ASSIGNED to Rahul Patil
        const inc3 = await prisma.incident.create({
            data: {
                incidentCode: 'INC-2026-003',
                title: 'Sector 3 Commercial Boulevard Gate Valve Seep',
                description: 'Gradual joint seep detected on 6-inch commercial trunk.',
                location: 'Sector 3, Commercial Boulevard Block C',
                zone: 'North & Central Distribution Grid',
                deviceId: 'WLS-003',
                flowRate: 5.15,
                totalLiters: 65.0,
                leakageDetected: true,
                pumpStatus: false,
                severity: client_1.Severity.MEDIUM,
                status: client_1.IncidentStatus.ASSIGNED,
                acknowledgedAt: new Date(Date.now() - 90 * 60 * 1000),
                acknowledgedBy: officer.fullName,
                assignedWorkerId: workerRahul.id,
                assignedAt: new Date(Date.now() - 30 * 60 * 1000),
            },
        });
        await prisma.incidentHistory.createMany({
            data: [
                {
                    incidentId: inc3.id,
                    actorName: 'ESP8266 Telemetry Engine',
                    actorRole: 'IoT Sensor Node',
                    action: 'DETECTED',
                    newStatus: client_1.IncidentStatus.IDENTIFIED,
                    note: 'Leakage Detected',
                    createdAt: new Date(Date.now() - 100 * 60 * 1000),
                },
                {
                    incidentId: inc3.id,
                    actorId: officer.id,
                    actorName: officer.fullName,
                    actorRole: 'Municipal Officer',
                    action: 'ACKNOWLEDGED',
                    previousStatus: client_1.IncidentStatus.IDENTIFIED,
                    newStatus: client_1.IncidentStatus.ACKNOWLEDGED,
                    note: 'Acknowledged by Municipal Officer',
                    createdAt: new Date(Date.now() - 90 * 60 * 1000),
                },
                {
                    incidentId: inc3.id,
                    actorId: officer.id,
                    actorName: officer.fullName,
                    actorRole: 'Municipal Officer',
                    action: 'ASSIGNED',
                    previousStatus: client_1.IncidentStatus.ACKNOWLEDGED,
                    newStatus: client_1.IncidentStatus.ASSIGNED,
                    note: `Assigned to ${workerRahul.fullName}`,
                    createdAt: new Date(Date.now() - 30 * 60 * 1000),
                },
            ],
        });
        await prisma.notification.create({
            data: {
                recipientId: workerRahul.id,
                recipientRole: client_1.Role.WORKER,
                title: 'New Task Assigned: INC-2026-003',
                message: `Officer ${officer.fullName} assigned you to MEDIUM priority leak at Sector 3, Commercial Boulevard.`,
                type: client_1.NotificationType.WORKER_ASSIGNED,
                incidentId: inc3.id,
            },
        });
        // Incident 4: RESOLVED by Rahul Patil
        const inc4 = await prisma.incident.create({
            data: {
                incidentCode: 'INC-2026-004',
                title: 'Sector 1 Ring Feeder Joint Replacement',
                description: 'Corroded flange gasket replaced with heavy-duty EPDM seal.',
                location: 'Sector 1, North Ring Feeder Post 12',
                zone: 'North & Central Distribution Grid',
                deviceId: 'WLS-005',
                flowRate: 3.50,
                totalLiters: 195.4,
                leakageDetected: false,
                pumpStatus: true,
                severity: client_1.Severity.MEDIUM,
                status: client_1.IncidentStatus.RESOLVED,
                acknowledgedAt: new Date(Date.now() - 4 * 3600 * 1000),
                acknowledgedBy: officer.fullName,
                assignedWorkerId: workerRahul.id,
                assignedAt: new Date(Date.now() - 3 * 3600 * 1000),
                resolvedAt: new Date(Date.now() - 1 * 3600 * 1000),
                resolvedBy: workerRahul.fullName,
                resolutionNote: 'Replaced corroded flange gasket with heavy-duty EPDM seal. Pressure tested to 4.5 bar with 0 leakage.',
            },
        });
        await prisma.incidentHistory.createMany({
            data: [
                {
                    incidentId: inc4.id,
                    actorName: 'ESP8266 Telemetry Engine',
                    actorRole: 'IoT Sensor Node',
                    action: 'DETECTED',
                    newStatus: client_1.IncidentStatus.IDENTIFIED,
                    note: 'Leakage Detected',
                    createdAt: new Date(Date.now() - 5 * 3600 * 1000),
                },
                {
                    incidentId: inc4.id,
                    actorId: officer.id,
                    actorName: officer.fullName,
                    actorRole: 'Municipal Officer',
                    action: 'ACKNOWLEDGED',
                    previousStatus: client_1.IncidentStatus.IDENTIFIED,
                    newStatus: client_1.IncidentStatus.ACKNOWLEDGED,
                    note: 'Acknowledged by Municipal Officer',
                    createdAt: new Date(Date.now() - 4 * 3600 * 1000),
                },
                {
                    incidentId: inc4.id,
                    actorId: officer.id,
                    actorName: officer.fullName,
                    actorRole: 'Municipal Officer',
                    action: 'ASSIGNED',
                    previousStatus: client_1.IncidentStatus.ACKNOWLEDGED,
                    newStatus: client_1.IncidentStatus.ASSIGNED,
                    note: `Assigned to ${workerRahul.fullName}`,
                    createdAt: new Date(Date.now() - 3 * 3600 * 1000),
                },
                {
                    incidentId: inc4.id,
                    actorId: workerRahul.id,
                    actorName: workerRahul.fullName,
                    actorRole: 'Field Worker',
                    action: 'RESOLVED',
                    previousStatus: client_1.IncidentStatus.ASSIGNED,
                    newStatus: client_1.IncidentStatus.RESOLVED,
                    note: `Marked Resolved by ${workerRahul.fullName}`,
                    metadata: { description: 'Replaced corroded flange gasket with heavy-duty EPDM seal. Pressure tested to 4.5 bar with 0 leakage.' },
                    createdAt: new Date(Date.now() - 1 * 3600 * 1000),
                },
            ],
        });
        console.log('📋 Baseline incidents and history created in Supabase.');
    }
    console.log('✅ Supabase database seeding complete!');
}
main()
    .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map