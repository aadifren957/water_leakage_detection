import { AuthService } from '../services/auth.service';
import { connectDatabase, disconnectDatabase } from '../config/db';

async function initOfficer() {
  console.log('Initializing Municipal Officer provision script...');
  await connectDatabase();
  await AuthService.ensureInitialOfficer();
  await disconnectDatabase();
  console.log('Done.');
}

initOfficer();
