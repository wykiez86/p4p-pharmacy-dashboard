# ตั้งค่า Supabase และ Deploy ผ่าน GitHub

## สถานะการเชื่อมต่อ

ไฟล์ `config.js` เชื่อมหน้าเว็บกับ Supabase project แล้ว โดยมีเฉพาะ Project URL และ publishable key ซึ่งใช้ในหน้าเว็บได้เมื่อเปิด RLS และใช้ policy ตาม schema นี้ **ห้ามใส่ secret key หรือ service_role key ในไฟล์นี้**

## 1. สร้างตารางและกำหนดความปลอดภัย

ใน Supabase project ของแอป เปิด **SQL Editor** แล้วรันไฟล์ [supabase/schema.sql](supabase/schema.sql) ก่อนเริ่มใช้งาน ระบบใช้ Supabase Auth และ Row Level Security (RLS) เพื่อจำกัดข้อมูลไว้เฉพาะบัญชีที่ผู้ดูแลอนุมัติใน `app_users`.

## 2. ตั้งค่าการเข้าสู่ระบบ

ใน **Authentication → URL Configuration** ตั้ง Site URL และเพิ่ม Redirect URL:

https://wykiez86.github.io/p4p-pharmacy-dashboard/

ใน **Authentication → Sign In / Providers** ปิดการสมัครสมาชิกสาธารณะ จากนั้นเชิญบัญชีบุคลากรใน **Authentication → Users** และให้ผู้ใช้ตั้งรหัสผ่านผ่านอีเมลเชิญ

คัดลอก User ID ของแต่ละบัญชีจากรายการ Users แล้วเพิ่มใน SQL Editor:

```sql
insert into public.app_users (user_id) values ('USER_UUID');
```

ทำซ้ำกับบัญชีที่ต้องการให้ใช้ระบบ หากไม่มีแถวที่ active ใน `app_users` ผู้ใช้จะอ่านหรือแก้ไขข้อมูล P4P ไม่ได้

## 3. เปิด GitHub Pages

ใน repo ไปที่ **Settings → Pages** แล้วเลือก **Build and deployment → Source: GitHub Actions**. หลังจากนั้น GitHub Actions จะ deploy อัตโนมัติเมื่อมีการเปลี่ยนหน้าเว็บ, config หรือ workflow บน `main`.

URL ของเว็บ:

https://wykiez86.github.io/p4p-pharmacy-dashboard/

## ความปลอดภัยและข้อมูล

GitHub Pages อาจเผยแพร่หน้าเว็บเป็นสาธารณะตามการตั้งค่า repo และแผน GitHub. หน้าเว็บไม่มีข้อมูลภาระงานฝังอยู่; การอ่านและเขียนข้อมูลต้องผ่าน Supabase Auth, allowlist และ RLS. Publishable key ออกแบบมาให้ใช้ใน browser ได้ แต่ต้องคง RLS และ policy ไว้. **ห้ามใช้ secret key หรือ service_role key ในหน้าเว็บ**

Project นี้อยู่ region Sydney, Australia. ควรตรวจสอบข้อกำหนดการจัดเก็บข้อมูลของหน่วยงานก่อนบันทึกข้อมูลบุคลากรจริง

## หมายเหตุการย้าย

Google Sheet เดิมยังไม่ได้รับข้อมูลจากแอป และไม่มีการคัดลอกข้อมูลเข้ามาใน Supabase. ระบบจะเริ่มบันทึกหลังติดตั้ง schema, เพิ่มผู้ใช้ที่อนุญาต และเปิด GitHub Pages แล้ว
