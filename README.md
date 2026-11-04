# P4P Pharmacy Dashboard

ระบบบันทึกและประเมินภาระงาน P4P กลุ่มงานเภสัชกรรม โรงพยาบาลสมเด็จพระยุพราชสว่างแดนดิน

## Stack

- Frontend: static HTML on GitHub Pages
- Database and authentication: Supabase
- Access control: Supabase Auth plus PostgreSQL Row Level Security (RLS)
- Deployment: GitHub Actions

The dashboard tracks daily activity counts, calculates role-based monthly scores, summarizes progress, and exports summary and daily matrix sheets to Excel.

Monthly targets: เภสัชกร 1,440; เจ้าพนักงานเภสัชกรรม 960; พนักงานประจำห้องยา 600. Activity point values remain configurable because the supplied requirements did not include a detailed activity scoring table.

## Setup

Follow [SETUP.md](SETUP.md) to create the Supabase schema, authorize users, configure GitHub Actions, and publish the app.

Only the Supabase publishable key is placed in the browser bundle. Never use a Supabase secret or service_role key in this frontend. RLS must remain enabled on all app tables.
