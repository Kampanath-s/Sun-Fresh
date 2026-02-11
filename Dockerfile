FROM node:18-alpine

WORKDIR /app

# ติดตั้งแพ็กเกจระบบที่จำเป็น
RUN apk add --no-cache netcat-openbsd git

# คัดลอก package.json
COPY package*.json ./
COPY packages/evershop/package.json ./packages/evershop/
COPY packages/postgres-query-builder/package.json ./packages/postgres-query-builder/

# ติดตั้ง dependencies ทั้งหมด (รวมถึง devDependencies สำหรับการ compile)
# เราไม่ใช้ --omit=dev ที่นี่เพราะต้องการ swc สำหรับการ compile
RUN npm install

# คัดลอกโค้ดทั้งหมด
COPY . .

# ขั้นตอนสำคัญ: Compile packages
# รัน compile เพื่อสร้างไฟล์ใน dist
RUN npm run compile
RUN npm run compile:db || echo "DB compile skipped"

# รัน Build หน้าร้าน
RUN npm run build

# ตั้งค่าสิทธิ์การรันให้กับ entrypoint.sh
RUN chmod +x entrypoint.sh

# ตั้งค่า Environment Variables
ENV PORT=3000
# เรายังคงใช้ production แต่เราติดตั้ง devDeps ไปแล้วข้างบน
ENV NODE_ENV=production

EXPOSE 3000

# ใช้ entrypoint.sh ในการเริ่มระบบ
ENTRYPOINT ["./entrypoint.sh"]
