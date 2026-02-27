#!/bin/bash
# vercel_build.sh
# Script ini dijalankan oleh Vercel saat build.
# Membaca env var SUPABASE_URL dan SUPABASE_ANON_KEY,
# lalu generate file supabase_config.dart sebelum flutter build.

set -e  # stop jika ada error

echo "==> Generating supabase_config.dart from environment variables..."

cat > lib/utils/supabase_config.dart << EOF
// File ini di-generate otomatis saat build. JANGAN diedit manual.
// Lihat vercel_build.sh untuk cara kerjanya.
class SupabaseConfig {
  static const String supabaseUrl     = '${SUPABASE_URL}';
  static const String supabaseAnonKey = '${SUPABASE_ANON_KEY}';
}
EOF

echo "==> supabase_config.dart generated."
echo "    URL: ${SUPABASE_URL}"

echo "==> Adding Flutter to PATH..."
export PATH="$PATH:/opt/flutter/bin"

echo "==> Running flutter pub get..."
flutter pub get

echo "==> Building Flutter Web..."
flutter build web --release

echo "==> Build complete."