FROM node:18-alpine

WORKDIR /app

# ติดตั้งแพ็กเกจระบบที่จำเป็น
RUN apk add --no-cache netcat-openbsd git

# คัดลอก package.json และติดตั้ง dependencies ทั้งหมด
COPY package*.json ./
COPY packages/evershop/package.json ./packages/evershop/
COPY packages/postgres-query-builder/package.json ./packages/postgres-query-builder/
RUN npm install

# คัดลอกโค้ดทั้งหมด
COPY . .

# ขั้นตอนสำคัญ: Compile packages ก่อนรัน build
RUN npm run compile
RUN npm run compile:db

# รัน Build หน้าร้าน
RUN npm run build

# ตั้งค่าสิทธิ์การรันให้กับ entrypoint.sh
RUN chmod +x entrypoint.sh

# ตั้งค่า Environment Variables พื้นฐาน
ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

# ใช้ entrypoint.sh ในการเริ่มระบบ
ENTRYPOINT ["./entrypoint.sh"]
