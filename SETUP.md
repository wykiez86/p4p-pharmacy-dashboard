# ตั้งค่าการเชื่อม Google Sheets และ Deploy

## โครงสร้าง

- Code.gs อ่านและเขียนชีตสำหรับบุคลากร ประเภทงาน และรายการจำนวนงานรายวัน
- Index.html เป็นหน้าจอของเว็บแอป Apps Script และบันทึกผ่าน google.script.run
- GitHub Actions ส่งไฟล์ Apps Script จาก branch main ไปยัง Google Apps Script ด้วย clasp
- การเผยแพร่ตั้งต้นเป็นสิทธิ์เฉพาะเจ้าของแอป (MYSELF) และทำงานภายใต้บัญชีเจ้าของ (USER_DEPLOYING)

ข้อมูลยังไม่ถูกส่งไปยัง GitHub Pages: หน้า GitHub Pages จาก private repository ยังอาจเปิดสู่สาธารณะตามแผนและการตั้งค่าบัญชี จึงใช้ Apps Script เป็นตัวให้บริการหน้าเว็บและเชื่อมชีตโดยตรง

## ตั้งค่าครั้งแรก

1. เปิดชีตที่ต้องการใช้ แล้วเลือก **ส่วนขยาย → Apps Script** เพื่อสร้างหรือเปิด Apps Script project ที่ผูกกับชีตนี้
2. ใน Apps Script ไปที่ **Project Settings** แล้วคัดลอก **Script ID** ไว้ เปิด Apps Script API ที่ https://script.google.com/home/usersettings และสร้างข้อมูลรับรอง clasp ด้วยบัญชี Google เจ้าของโปรเจกต์
3. ใน GitHub ไปที่ **Settings → Secrets and variables → Actions** แล้วเพิ่ม repository secrets:
   - CLASP_JSON: JSON รูปแบบ {"scriptId":"SCRIPT_ID","rootDir":"."}
   - CLASPRC_JSON: เนื้อหาของไฟล์ .clasprc.json จาก clasp login
4. เพิ่ม repository variable GAS_DEPLOY_ENABLED เป็น true.
5. เปิด **Actions → Deploy P4P to Google Apps Script → Run workflow**. การรันครั้งแรกจะส่ง source code ไปยัง Apps Script; หากยังไม่มี deployment ID workflow จะหยุดหลังส่ง source สำเร็จ
6. เมื่อ source ถูกส่งแล้ว ใน Apps Script เลือก **Deploy → New deployment → Web app**. ตั้ง **Execute as: Me** และ **Who has access: Only myself** แล้วสร้าง deployment.
7. คัดลอก deployment ID จาก URL ของ web app แล้วเพิ่มเป็น repository secret ชื่อ GAS_DEPLOYMENT_ID.
8. เปิด web app URL ด้วยบัญชี Google เดียวกับเจ้าของ deployment. การเปิดครั้งแรกอาจขอสิทธิ์เข้าถึงชีต และสร้างแท็บข้อมูลให้โดยอัตโนมัติ

หลังตั้งค่าครบแล้ว การ push การแก้ไข Code.gs, Index.html หรือ appsscript.json ไปยัง main จะเรียก workflow เพื่ออัปโหลดและอัปเดต deployment เดิมโดยอัตโนมัติ

## สิทธิ์และข้อมูล

ค่าเริ่มต้นจำกัดเว็บแอปไว้ที่เจ้าของ deployment เท่านั้น การขยายสิทธิ์ให้บุคลากรอื่นต้องตั้งค่าการเข้าถึงเว็บแอปและกำหนดสิทธิ์ Google Sheet ให้เหมาะสมก่อน ห้ามเปลี่ยนเป็นผู้ใช้ทุกคนโดยไม่มีการตรวจสอบสิทธิ์และการควบคุมผู้ใช้ที่ชัดเจน

เมื่อเปิดแอปครั้งแรก ระบบจะสร้างแท็บ P4P Staff, P4P Activities และ P4P Entries ในชีตที่กำหนดไว้ใน Code.gs ข้อมูลจะแยกตามงวดเดือนและใช้ ID สำหรับเชื่อมโยงรายการ

เก็บ CLASPRC_JSON ไว้ใน GitHub Actions Secrets เท่านั้น ห้าม commit หรือส่ง credential นี้ในแชต

## เอกสารอ้างอิง

- [Apps Script web apps](https://developers.google.com/apps-script/guides/web)
- [clasp และการ deploy ผ่าน GitHub Actions](https://developers.google.com/apps-script/guides/clasp)
- [การเผยแพร่ GitHub Pages และการมองเห็นเว็บไซต์](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
