# Mohammed Yaseen Jakati — Portfolio

A single-file, static portfolio site (Data Analyst · Power BI · DOMO · SQL).
No build step, no dependencies — just `index.html`.

## Projects
Four end-to-end BI case studies live under [`projects/`](projects/PROJECTS.md) — each with a
dataset, runnable SQL, DAX measures, and an interactive dashboard wired into the portfolio.

## Run locally
Open `index.html` in any browser, or serve it:
```bash
python3 -m http.server 8000   # then visit http://localhost:8000
```

## Deploy / update

This portfolio is a static site and is deployed from the `main` branch. After editing the files:

```bash
git add .
git commit -m "Update portfolio"
git push origin main
```

Vercel can then redeploy the connected GitHub repository automatically.
