FROM node:18-alpine

WORKDIR /app

# ติดตั้งแพ็กเกจระบบที่จำเป็น
RUN apk add --no-cache netcat-openbsd git

# คัดลอก package.json
COPY package*.json ./
COPY packages/evershop/package.json ./packages/evershop/
COPY packages/postgres-query-builder/package.json ./packages/postgres-query-builder/

# ติดตั้ง dependencies ทั้งหมด (รวมถึง devDependencies สำหรับการ compile)
RUN npm install

# คัดลอกโค้ดทั้งหมด
COPY . .

# ขั้นตอนสำคัญ: Compile packages
# เราใช้คำสั่งตรงไปยัง bin เพื่อเลี่ยงปัญหา PATH
RUN node ./packages/evershop/dist/bin/build/index.js || npm run compile
RUN npm run compile:db || echo "DB compile skipped"

# รัน Build หน้าร้าน
RUN npm run build

# ลบ node_modules และติดตั้งใหม่เฉพาะ production เพื่อลดขนาด image (Optional)
# RUN rm -rf node_modules && npm install --omit=dev

# ตั้งค่าสิทธิ์การรันให้กับ entrypoint.sh
RUN chmod +x entrypoint.sh

# ตั้งค่า Environment Variables พื้นฐาน
ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

# ใช้ entrypoint.sh ในการเริ่มระบบ
ENTRYPOINT ["./entrypoint.sh"]
