import crypto from 'crypto';

export class OtpUtil {
  /**
   * Generates a cryptographically secure 6-digit numeric OTP.
   */
  static generateOtp(digits: number = 6): string {
    const min = Math.pow(10, digits - 1);
    const max = Math.pow(10, digits);
    return crypto.randomInt(min, max).toString();
  }

  /**
   * Hashes an OTP using SHA-256 for secure storage.
   */
  static hashOtp(otp: string): string {
    return crypto.createHash('sha256').update(otp.trim()).digest('hex');
  }

  /**
   * Verifies an OTP against a stored SHA-256 hash using timing-safe comparison.
   */
  static verifyOtp(otp: string, tokenHash: string): boolean {
    const computedHash = this.hashOtp(otp);
    const hashBuffer = Buffer.from(computedHash, 'hex');
    const storedBuffer = Buffer.from(tokenHash, 'hex');

    if (hashBuffer.length !== storedBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(hashBuffer, storedBuffer);
  }
}
