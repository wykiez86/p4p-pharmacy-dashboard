# ตั้งค่าการเชื่อม Google Sheets และ Deploy

## โครงสร้าง

- Code.gs อ่านและเขียนชีตสำหรับบุคลากร ประเภทงาน และรายการจำนวนงานรายวัน
- Index.html เป็นหน้าจอของเว็บแอป Apps Script และบันทึกผ่าน google.script.run
- GitHub Actions ส่งไฟล์ Apps Script จาก branch main ไปยัง Google Apps Script ด้วย clasp
- การเผยแพร่ตั้งต้นเป็นสิทธิ์เฉพาะเจ้าของแอป (MYSELF) และทำงานภายใต้บัญชีเจ้าของ (USER_DEPLOYING)

ข้อมูลยังไม่ถูกส่งไปยัง GitHub Pages: หน้า GitHub Pages จาก private repository ยังอาจเปิดสู่สาธารณะตามแผนและการตั้งค่าบัญชี จึงใช้ Apps Script เป็นตัวให้บริการหน้าเว็บและเชื่อมชีตโดยตรง

## ตั้งค่าครั้งแรก

1. เปิดชีตที่ต้องการใช้ แล้วเลือก **ส่วนขยาย → Apps Script** เพื่อสร้าง/เปิด Apps Script project ที่ผูกกับชีตนี้
2. ใน Apps Script ไปที่ **Project Settings** แล้วคัดลอก **Script ID** ไว้ เปิด Apps Script API ในบัญชี Google ที่ https://script.google.com/home/usersettings
3. ใน Apps Script เลือก **Deploy → New deployment → Web app** ตั้ง **Execute as: Me** และ **Who has access: Only myself** จากนั้นสร้าง deployment เพื่อให้ได้ deployment ID และ URL
4. สร้างข้อมูลรับรอง clasp ด้วยบัญชี Google เจ้าของ Apps Script project ตามคู่มือ Google แล้วเก็บไฟล์ .clasprc.json ไว้เป็นความลับ ห้าม commit หรือส่งในแชต
5. ใน GitHub ไปที่ **Settings → Secrets and variables → Actions** แล้วเพิ่ม repository secrets:
   - CLASP_JSON: JSON รูปแบบ {"scriptId":"SCRIPT_ID","rootDir":"."}
   - CLASPRC_JSON: เนื้อหาของไฟล์ .clasprc.json
   - GAS_DEPLOYMENT_ID: ID ของ web app deployment ที่สร้างไว้ในขั้นตอน 3
6. เพิ่ม repository variable GAS_DEPLOY_ENABLED เป็น true.
7. เปิด **Actions → Deploy P4P to Google Apps Script → Run workflow**. การ push ครั้งแรกอัปโหลดโค้ดก่อน แล้ว deployment ที่มีอยู่จะถูกอัปเดต
8. เปิด web app URL จาก summary ของ workflow หรือจาก **Deploy → Manage deployments**. ในการเปิดครั้งแรก Apps Script อาจขอให้เจ้าของอนุญาตการเข้าถึง Google Sheet

หลังตั้งค่าแล้ว การ push การแก้ไข Code.gs, Index.html หรือ appsscript.json ไปยัง main จะเรียก workflow เพื่ออัปเดต web app อัตโนมัติ

## สิทธิ์และข้อมูล

ค่าเริ่มต้นจำกัดเว็บแอปไว้ที่เจ้าของ deployment เท่านั้น การขยายสิทธิ์ให้บุคลากรอื่นต้องตั้งค่าการเข้าถึงเว็บแอปและกำหนดสิทธิ์ Google Sheet ให้เหมาะสมก่อน ห้ามเปลี่ยนเป็นผู้ใช้ทุกคนโดยไม่มีการตรวจสอบสิทธิ์และการควบคุมผู้ใช้ที่ชัดเจน

เมื่อเปิดแอปครั้งแรก ระบบจะสร้างแท็บ P4P Staff, P4P Activities และ P4P Entries ในชีตที่กำหนดไว้ใน Code.gs ข้อมูลจะถูกแยกตามงวดเดือนและใช้ ID สำหรับเชื่อมโยงรายการ

## เอกสารอ้างอิง

- [Apps Script web apps](https://developers.google.com/apps-script/guides/web)
- [clasp และการ deploy ผ่าน GitHub Actions](https://developers.google.com/apps-script/guides/clasp)
- [การเผยแพร่ GitHub Pages และการมองเห็นเว็บไซต์](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
