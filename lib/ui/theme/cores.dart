import 'package:flutter/material.dart';

// ── Paleta base "oceano" ─────────────────────────────────────────────
const oceanDeep = Color(0xFF031B34); // azul marinho profundo (fundo, texto sobre CTA)
const oceanBlue = Color(0xFF0A4D8C); // azul oceano
const oceanTeal = Color(0xFF0FA3B1); // azul-turquesa
const aqua = Color(0xFF4FF0E6); // água cristalina (destaque, foco, links)
const foam = Color(0xFFE6FBFF); // espuma do mar (base dos textos)
const sunsetOrange = Color(0xFFFF7A3D); // pôr do sol (CTA)
const sunsetYellow = Color(0xFFFFC94A); // sol (CTA, números, avisos)
const coral = Color(0xFFFF8A80); // erro (legível sobre o fundo escuro)

// ── Superfícies de vidro ─────────────────────────────────────────────
const glassWhite = Color(0x26FFFFFF); // 15%: botões/selos de vidro
const glassSurface = Color(0x1AFFFFFF); // 10%: cartões
const glassField = Color(0x0DFFFFFF); // 5%: campos em repouso
const glassFieldFocused = Color(0x14FFFFFF); // 8%: campos com foco
const glassBorder = Color(0x40FFFFFF); // 25%: bordas

// ── Texto (sempre sobre fundo oceano) ────────────────────────────────
const textPrimary = Colors.white; // títulos e valores
final textSecondary = foam.withValues(alpha: 0.85); // subtítulos, corpo
final textMuted = foam.withValues(alpha: 0.7); // legendas, rótulos em repouso
final textHint = foam.withValues(alpha: 0.4); // placeholders
