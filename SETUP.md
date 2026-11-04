# ตั้งค่า Supabase และ Deploy ผ่าน GitHub

## 1. สร้างฐานข้อมูลและตั้ง URL สำหรับ Auth

1. สร้าง project ใน Supabase.
2. เปิด **SQL Editor** แล้วรันไฟล์ [supabase/schema.sql](supabase/schema.sql).
3. ใน **Authentication → URL Configuration** ตั้ง **Site URL** และเพิ่ม Redirect URL เป็น:
   https://wykiez86.github.io/p4p-pharmacy-dashboard/

## 2. อนุมัติผู้ใช้

1. ใน **Authentication → Sign In / Providers** ปิดการสมัครสมาชิกสาธารณะ (Allow new users to sign up). แอปไม่มีปุ่มสมัครบัญชีและให้เข้าได้เฉพาะผู้ใช้ที่อนุมัติ
2. ใน **Authentication → Users** เชิญบัญชีอีเมลที่จะใช้แอป และให้ผู้ใช้ตั้งรหัสผ่านผ่านอีเมลเชิญ
3. คัดลอก User ID ของบัญชีจากรายการ Users แล้วเพิ่มใน SQL Editor:

   ```sql
   insert into public.app_users (user_id) values ('USER_UUID');
   ```

ทำซ้ำกับแต่ละบัญชีที่ต้องใช้ระบบ หากไม่มีแถวที่ active ใน app_users แม้ login สำเร็จ ผู้ใช้ก็จะอ่านหรือแก้ไขข้อมูล P4P ไม่ได้

## 3. ตั้งค่า GitHub Pages

1. ใน repo ไปที่ **Settings → Pages** แล้วเลือก **Build and deployment → Source: GitHub Actions**.
2. ใน **Settings → Secrets and variables → Actions → Secrets** เพิ่ม:
   - SUPABASE_URL: Project URL จาก Supabase Project Settings / Connect.
   - SUPABASE_PUBLISHABLE_KEY: publishable key ของโปรเจกต์ (หรือ legacy anon key ถ้าโปรเจกต์ยังใช้ key แบบเดิม).
3. เพิ่ม Actions variable ชื่อ PAGES_DEPLOY_ENABLED และตั้งค่าเป็น true.
4. เปิด **Actions → Deploy P4P dashboard to GitHub Pages → Run workflow** เพื่อ deploy ครั้งแรก.

หลังตั้งค่านี้ การ push การแก้ไข index.html หรือ workflow ไปยัง main จะ deploy อัตโนมัติ URL ของเว็บคือ:

https://wykiez86.github.io/p4p-pharmacy-dashboard/

นำ URL นี้ไปเพิ่มใน Supabase **Authentication → URL Configuration → Redirect URLs** หากยังไม่ได้เพิ่ม

## ความปลอดภัย

GitHub Pages อาจให้บริการหน้าเว็บเป็นสาธารณะ แม้ source repository เป็น private ทั้งนี้ขึ้นกับแผน GitHub และการตั้งค่า Pages. ตัวหน้าเว็บไม่บรรจุข้อมูลภาระงาน; การเข้าถึงข้อมูลต้องผ่าน Supabase Auth และ RLS. Publishable key ออกแบบมาให้ใช้ใน browser ได้ แต่ต้องรักษา RLS และ allowlist ไว้. **ห้ามใช้ secret key หรือ service_role key ใน frontend หรือ GitHub Pages artifact**.

คู่มือ Supabase ระบุว่า publishable key เป็นค่าที่อ่านได้จาก browser และ RLS เป็นตัวกำหนดสิทธิ์เข้าถึงข้อมูล. ดู [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) และ [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site).

## หมายเหตุการย้าย

Google Sheet เดิมยังไม่ได้รับข้อมูลจากแอป และไม่มีการคัดลอกข้อมูลเข้ามาในการเปลี่ยนครั้งนี้. ระบบจะเริ่มใช้ Supabase หลังรัน schema, ตั้งค่า secrets และ deploy สำเร็จ.
