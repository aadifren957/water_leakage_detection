import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Deep Municipal Navy & Professional Blues
  static const Color primaryNavy = Color(0xFF0F243E);
  static const Color primaryBlue = Color(0xFF1E56A0);
  static const Color primaryLightBlue = Color(0xFF3B82F6);
  static const Color secondaryCyan = Color(0xFF06B6D4);
  static const Color accentTeal = Color(0xFF0D9488);

  // Background & Surfaces
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);
  static const Color divider = Color(0xFFCBD5E1);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFCBD5E1);

  // Lifecycle Status Colors
  // Identified: Orange
  static const Color statusIdentified = Color(0xFFEA580C);
  static const Color statusIdentifiedBg = Color(0xFFFFF7ED);
  static const Color statusIdentifiedBorder = Color(0xFFFDBA74);

  // Acknowledged: Blue
  static const Color statusAcknowledged = Color(0xFF2563EB);
  static const Color statusAcknowledgedBg = Color(0xFFEFF6FF);
  static const Color statusAcknowledgedBorder = Color(0xFF93C5FD);

  // Assigned: Purple
  static const Color statusAssigned = Color(0xFF7C3AED);
  static const Color statusAssignedBg = Color(0xFFF5F3FF);
  static const Color statusAssignedBorder = Color(0xFFC4B5FD);

  // Resolved: Green
  static const Color statusResolved = Color(0xFF059669);
  static const Color statusResolvedBg = Color(0xFFECFDF5);
  static const Color statusResolvedBorder = Color(0xFF6EE7B7);

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityCritical = Color(0xFFDC2626);

  // Telemetry & Sensor States
  static const Color sensorOnline = Color(0xFF10B981);
  static const Color sensorOffline = Color(0xFF94A3B8);
  static const Color leakDetected = Color(0xFFDC2626);
  static const Color leakNormal = Color(0xFF10B981);
  static const Color pumpOn = Color(0xFF2563EB);
  static const Color pumpOff = Color(0xFF64748B);
}
