# Mohammed Yaseen Jakati — Portfolio

A single-file, static portfolio site (Data Analyst · Power BI · DOMO · SQL).
No build step, no dependencies — just `index.html`.

## Run locally
Open `index.html` in any browser, or serve it:
```bash
python3 -m http.server 8000   # then visit http://localhost:8000
```

## Deploy to Vercel (auto-deploy on every push)

1. **Create a GitHub repo** (empty, no README) at https://github.com/new
   — e.g. `yaseen-portfolio`.

2. **Push this project** (run from inside this folder):
   ```bash
   git remote add origin https://github.com/itzzyaseen/yaseen-portfolio.git
   git branch -M main
   git push -u origin main
   ```
   > If you're starting fresh instead of using the included history, run `./push.sh`
   > first — it initialises git with the correct author (itzzyaseen).

3. **Connect to Vercel** at https://vercel.com/new
   — "Import Git Repository" → pick this repo → **Deploy**.
   Framework preset: **Other** (it's a static site). No build command needed.

That's it. From now on, **every `git push` to `main` redeploys automatically** —
Vercel watches the connected GitHub repo. Pull requests also get preview URLs.

## Updating your contact details
Open `index.html`, find the block marked `ADD YOUR CONTACT DETAILS HERE`
(near the bottom), swap in your real email and phone, then:
```bash
git add index.html
git commit -m "Add contact details"
git push
```
Vercel redeploys within a minute.
