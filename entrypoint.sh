#!/bin/sh

echo "=== EverShop Railway Entrypoint ==="

# ตั้งค่า NODE_TLS_REJECT_UNAUTHORIZED=0 เพื่อปิดการตรวจสอบ SSL สำหรับ Node.js
export NODE_TLS_REJECT_UNAUTHORIZED=0

# หาก DATABASE_URL ไม่ได้ถูกตั้งค่า ให้สร้างจากตัวแปร PostgreSQL ของ Railway
if [ -z "$DATABASE_URL" ]; then
  export DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE"
fi

# รอฐานข้อมูลพร้อมใช้งาน
DB_HOST=$(echo $DATABASE_URL | sed -e 's|.*@||' -e 's|/.*||' -e 's|:.*||')
DB_PORT=$(echo $DATABASE_URL | sed -e 's|.*:||' -e 's|/.*||')
[ -z "$DB_PORT" ] && DB_PORT=5432
until nc -z -v -w30 $DB_HOST $DB_PORT; do sleep 2; done

echo "Database is ready. Starting EverShop setup..."

# ขั้นตอนเสริม: ล้างฐานข้อมูลเพื่อให้สะอาดที่สุด (Hard Reset)
node reset_db.js || echo "Reset skipped or failed."

# รัน Install ใหม่
echo "Running fresh evershop install..."
npx evershop install

# สร้าง Admin User
echo "Creating fresh admin user: admin@admin.com"
npx evershop user:create --email "admin@admin.com" --password "password123" --full_name "Admin"

echo "Starting EverShop server..."
exec npm run start
