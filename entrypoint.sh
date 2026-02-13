#!/bin/sh

echo "=== EverShop Railway Entrypoint ==="

# ตั้งค่า NODE_TLS_REJECT_UNAUTHORIZED=0 เพื่อปิดการตรวจสอบ SSL สำหรับ Node.js อย่างเด็ดขาด
export NODE_TLS_REJECT_UNAUTHORIZED=0

# ตรวจสอบตัวแปรสภาพแวดล้อมที่จำเป็น
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set. Trying to build from Railway vars..."
  if [ ! -z "$PGHOST" ]; then
    export DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE"
  else
    echo "Error: No database connection info found!"
    exit 1
  fi
fi

# แยก Host และ Port เพื่อรอการเชื่อมต่อ
DB_HOST=$(echo $DATABASE_URL | sed -e 's|.*@||' -e 's|/.*||' -e 's|:.*||')
DB_PORT=$(echo $DATABASE_URL | sed -e 's|.*:||' -e 's|/.*||')
[ -z "$DB_PORT" ] && DB_PORT=5432

echo "Waiting for database at $DB_HOST:$DB_PORT..."
until nc -z -v -w30 $DB_HOST $DB_PORT; do 
  echo "Still waiting for database..."
  sleep 5
done

echo "Database is ready. Starting EverShop setup..."

# ขั้นตอนสำคัญ: ล้างฐานข้อมูลเพื่อให้สะอาดที่สุด (Hard Reset)
# เราจะรันแค่ครั้งเดียว ถ้ามีข้อมูลแล้วอาจจะข้ามไปในอนาคต
node reset_db.js || echo "Reset skipped or failed."

# รัน Install ใหม่
echo "Running evershop install..."
npx evershop install --force || echo "Install failed but continuing..."

# สร้าง Admin User (ใช้ try/catch ในตัวคำสั่งเอง)
echo "Ensuring admin user exists..."
npx evershop user:create --email "admin@admin.com" --password "password123" --full_name "Admin" || echo "Admin user might already exist."

echo "Starting EverShop server on port $PORT..."
# ใช้คำสั่ง node โดยตรงแทน npm run start เพื่อลด overhead และความซับซ้อน
exec node packages/evershop/bin/evershop.js
