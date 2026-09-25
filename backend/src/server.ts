import { app } from './app';
import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/db';
import { AuthService } from './services/auth.service';

async function bootstrap() {
  try {
    // 1. Connect to Supabase Database
    await connectDatabase();

    // 2. Ensure default Municipal Officer account exists
    await AuthService.ensureInitialOfficer();

    // 3. Start Express HTTP Server
    const server = app.listen(env.PORT, () => {
      console.log(`
  💧 ======================================================= 💧
     WaterWatch IoT Leakage Detection Backend Server
  💧 ======================================================= 💧
     🚀 Status: Running
     🌐 Port:   ${env.PORT}
     📡 URL:    http://localhost:${env.PORT}/api
     🩺 Health: http://localhost:${env.PORT}/api/health
     🗄️ DB:     Supabase PostgreSQL (${env.DATABASE_URL.includes('pooler') ? 'IPv4 Pooler' : 'Direct'})
  💧 ======================================================= 💧
      `);
    });

    // Graceful shutdown handling
    const shutdown = async (signal: string) => {
      console.log(`\nReceived ${signal}. Shutting down gracefully...`);
      server.close(async () => {
        await disconnectDatabase();
        console.log('Database disconnected. Process terminated.');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  } catch (error) {
    console.error('Fatal bootstrapping error:', error);
    process.exit(1);
  }
}

bootstrap();
