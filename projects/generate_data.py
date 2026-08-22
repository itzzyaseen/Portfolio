"""
Generates realistic sample datasets for all four portfolio projects, plus a
compact data.js (pre-aggregated) that powers each interactive HTML dashboard.

Data is synthetic but modelled on realistic distributions so the SQL and
dashboards behave like the real thing. Run:  python generate_data.py
"""
import numpy as np, pandas as pd, json, os
rng = np.random.default_rng(42)
BASE = os.path.dirname(os.path.abspath(__file__))

def w(df, path):
    full = os.path.join(BASE, path)
    df.to_csv(full, index=False)
    print(f"  {path:<48} {len(df):>7,} rows")

def js(obj, path):
    full = os.path.join(BASE, path)
    with open(full, "w") as f:
        f.write("window.DASH = " + json.dumps(obj, separators=(',', ':')) + ";")
    print(f"  {path}")

MONTHS = pd.date_range("2024-01-01", "2024-12-01", freq="MS")
MONTH_LABELS = [m.strftime("%b") for m in MONTHS]

# ============================================================ 1. SUPPLY CHAIN
print("Supply Chain:")
cats = ["Electronics", "Packaging", "Raw Material", "Components", "Consumables"]
sup = pd.DataFrame({
    "supplier_id": [f"SUP{100+i}" for i in range(15)],
    "supplier_name": [f"{n} {s}" for n, s in zip(
        rng.choice(["Apex","Nova","Prime","Vertex","Union","Delta","Orbit","Summit",
                    "Peak","Cedar","Iron","Blue","Metro","Grand","Hexa"], 15, replace=False),
        rng.choice(["Supplies","Traders","Logistics","Industries","Distributors"], 15))],
    "country": rng.choice(["India","China","Germany","USA","Vietnam"], 15),
    "category": rng.choice(cats, 15),
})
w(sup, "supply-chain/data/suppliers.csv")

nprod = 60
prod = pd.DataFrame({
    "product_id": [f"P{1000+i}" for i in range(nprod)],
    "product_name": [f"{c[:4].upper()}-{rng.integers(100,999)}" for c in rng.choice(cats, nprod)],
    "category": rng.choice(cats, nprod),
    "unit_cost": np.round(rng.uniform(5, 480, nprod), 2),
    "reorder_point": rng.integers(40, 200, nprod),
    "supplier_id": rng.choice(sup.supplier_id, nprod),
})
w(prod, "supply-chain/data/products.csv")

# orders: OTIF improves through the year
rows = []
oid = 5000
for mi, m in enumerate(MONTHS):
    n = rng.integers(150, 210)
    ontime_p = 0.87 + mi * 0.010      # improves over the year -> ~98% by Dec
    for _ in range(n):
        p = prod.sample(1).iloc[0]
        qty = int(rng.integers(20, 400))
        promised = m + pd.Timedelta(days=int(rng.integers(5, 20)))
        late = rng.random() > ontime_p
        delivered = promised + pd.Timedelta(days=int(rng.integers(1, 9))) if late else \
                    promised - pd.Timedelta(days=int(rng.integers(0, 4)))
        infull = rng.random() < (0.93 + mi * 0.005)
        qty_del = qty if infull else int(qty * rng.uniform(0.6, 0.95))
        rows.append((f"ORD{oid}", p.product_id, m.date().isoformat(), qty, qty_del,
                     promised.date().isoformat(), delivered.date().isoformat(),
                     "On-Time" if not late else "Late"))
        oid += 1
orders = pd.DataFrame(rows, columns=["order_id","product_id","order_date","qty_ordered",
                      "qty_delivered","promised_date","delivered_date","status"])
w(orders, "supply-chain/data/orders.csv")

# inventory snapshots
inv_rows = []
for _, p in prod.iterrows():
    stock = int(rng.integers(80, 400))
    for mi, m in enumerate(MONTHS):
        sold = int(rng.integers(30, 260))
        opening = stock
        received = int(rng.integers(40, 260))
        closing = max(0, opening + received - sold)
        inv_rows.append((p.product_id, m.strftime("%Y-%m"), opening, received, sold, closing,
                         1 if closing < p.reorder_point else 0))
        stock = closing
inv = pd.DataFrame(inv_rows, columns=["product_id","snapshot_month","opening_stock",
                   "received","units_sold","closing_stock","below_reorder"])
w(inv, "supply-chain/data/inventory.csv")

o = orders.copy()
o["on_time"] = (o.status == "On-Time")
o["in_full"] = (o.qty_delivered >= o.qty_ordered)
o["otif"] = o.on_time & o.in_full
o["m"] = pd.to_datetime(o.order_date).dt.strftime("%b")
otif_by_month = [round(o[o.m == lbl].otif.mean() * 100, 1) for lbl in MONTH_LABELS]
stockouts_by_month = [int(inv[inv.snapshot_month == m.strftime("%Y-%m")].below_reorder.sum())
                      for m in MONTHS]
turnover = round(inv.units_sold.sum() / inv.closing_stock.replace(0, 1).mean() / len(prod), 1)
cat_spend = (orders.merge(prod, on="product_id")
             .assign(val=lambda d: d.qty_ordered * d.unit_cost)
             .groupby("category").val.sum().round(0).sort_values(ascending=False))
ontime_by_month = [round(o[o.m == lbl].on_time.mean() * 100, 1) for lbl in MONTH_LABELS]
js({
  "kpis": {"otif": otif_by_month[-1], "ontime": ontime_by_month[-1],
           "orders": len(o), "stockouts": int(inv.below_reorder.sum()),
           "turnover": turnover, "suppliers": len(sup)},
  "months": MONTH_LABELS, "otif": otif_by_month, "stockouts": stockouts_by_month,
  "target": 95,
  "categories": [{"name": k, "value": int(v)} for k, v in cat_spend.items()],
}, "supply-chain/dashboard/data.js")

# ============================================================ 2. VENDOR PERF
print("Vendor Performance:")
regions = ["North","South","East","West","Central"]
vcats = ["Logistics","IT Services","Raw Material","Facilities","Marketing"]
nv = 120
vendors = pd.DataFrame({
    "vendor_id": [f"V{2000+i}" for i in range(nv)],
    "vendor_name": [f"Vendor-{2000+i}" for i in range(nv)],
    "category": rng.choice(vcats, nv),
    "region": rng.choice(regions, nv),
    "onboarded_date": [ (pd.Timestamp("2020-01-01") +
                        pd.Timedelta(days=int(rng.integers(0, 1600)))).date().isoformat()
                        for _ in range(nv)],
})
w(vendors, "vendor-performance/data/vendors.csv")

# each vendor has an intrinsic quality that drives its POs
quality = rng.beta(5, 2, nv)          # skewed toward good, with a tail of weak vendors
po_rows, dl_rows = [], []
pid = 7000
for vi, v in vendors.iterrows():
    q = quality[vi]
    for _ in range(int(rng.integers(15, 45))):
        po_date = pd.Timestamp("2024-01-01") + pd.Timedelta(days=int(rng.integers(0, 364)))
        promised = po_date + pd.Timedelta(days=int(rng.integers(7, 30)))
        val = round(float(rng.uniform(2000, 90000)), 2)
        on_time = rng.random() < (0.55 + 0.4 * q)
        delivered = promised - pd.Timedelta(days=int(rng.integers(0,4))) if on_time else \
                    promised + pd.Timedelta(days=int(rng.integers(1,12)))
        qty = int(rng.integers(50, 1000))
        defect_rate = max(0.0, rng.normal(0.10 - 0.08*q, 0.03))
        rejected = int(qty * min(defect_rate, 0.4))
        po_rows.append((f"PO{pid}", v.vendor_id, po_date.date().isoformat(),
                        promised.date().isoformat(), val, qty))
        dl_rows.append((f"PO{pid}", delivered.date().isoformat(), qty - rejected, rejected,
                        1 if rejected > 0 else 0))
        pid += 1
po = pd.DataFrame(po_rows, columns=["po_id","vendor_id","po_date","promised_date","order_value","qty_ordered"])
dl = pd.DataFrame(dl_rows, columns=["po_id","delivered_date","accepted_qty","rejected_qty","defect_flag"])
w(po, "vendor-performance/data/purchase_orders.csv")
w(dl, "vendor-performance/data/deliveries.csv")

m = po.merge(dl, on="po_id")
m["on_time"] = pd.to_datetime(m.delivered_date) <= pd.to_datetime(m.promised_date)
m["defect_rate"] = m.rejected_qty / m.qty_ordered
g = m.groupby("vendor_id").agg(pos=("po_id","count"),
        on_time=("on_time","mean"), defect=("defect_rate","mean"),
        spend=("order_value","sum")).reset_index()
# weighted score: 50% delivery, 35% quality, 15% cost-efficiency (inverse of avg value proxy)
g["delivery"] = (g.on_time*100).round(1)
g["quality"] = ((1-g.defect)*100).round(1)
g["cost"] = (100 - (g.spend.rank(pct=True)*30)).round(1)
g["score"] = (g.delivery*0.5 + g.quality*0.35 + g.cost*0.15).round(1)
g = g.merge(vendors[["vendor_id","vendor_name","category","region"]], on="vendor_id")
top = g.sort_values("score", ascending=False).head(6)
bot = g.sort_values("score").head(3)
js({
  "kpis": {"vendors": len(g), "avg_ontime": round(g.on_time.mean()*100,1),
           "avg_defect": round(g.defect.mean()*100,2), "pos": len(po),
           "spend": int(g.spend.sum()), "avg_score": round(g.score.mean(),1)},
  "top": [{"name": r.vendor_id, "score": r.score, "delivery": r.delivery,
           "quality": r.quality} for r in top.itertuples()],
  "bottom": [{"name": r.vendor_id, "score": r.score} for r in bot.itertuples()],
  "by_region": [{"name": k, "value": round(v,1)} for k, v in
                g.groupby("region").score.mean().round(1).items()],
}, "vendor-performance/dashboard/data.js")

# ============================================================ 3. STOCK FORECAST
print("Stock Forecasting:")
tickers = {"NORTHWIND":120, "ORBITEK":68, "HELIOS":210, "VANTA":45}
dates = pd.bdate_range("2023-01-02", "2024-12-31")
srows = []
series = {}
for tk, start in tickers.items():
    mu, sigma = rng.uniform(0.0002, 0.0008), rng.uniform(0.012, 0.022)
    price = start
    closes = []
    for d in dates:
        ret = rng.normal(mu, sigma)
        price = max(1, price * (1 + ret))
        op = price * (1 + rng.normal(0, 0.004))
        hi = max(op, price) * (1 + abs(rng.normal(0, 0.005)))
        lo = min(op, price) * (1 - abs(rng.normal(0, 0.005)))
        vol = int(abs(rng.normal(1_200_000, 400_000)))
        srows.append((tk, d.date().isoformat(), round(op,2), round(hi,2), round(lo,2),
                      round(price,2), vol))
        closes.append(round(price,2))
    series[tk] = closes
stock = pd.DataFrame(srows, columns=["ticker","date","open","high","low","close","volume"])
w(stock, "stock-forecasting/data/stock_prices.csv")

# simple forecast for dashboard: EWMA trend + widening band, last 90 trading days shown
def forecast(closes, horizon=30):
    s = pd.Series(closes)
    ewma = s.ewm(span=20).mean()
    drift = (ewma.iloc[-1] - ewma.iloc[-20]) / 20
    last = s.iloc[-1]
    fc = [round(last + drift*(i+1), 2) for i in range(horizon)]
    resid = float(s.diff().std())
    band = [round(resid * np.sqrt(i+1) * 1.96, 2) for i in range(horizon)]
    return fc, band

dash_series = {}
for tk, closes in series.items():
    hist = closes[-90:]
    fc, band = forecast(closes, 30)
    dash_series[tk] = {"hist": hist, "fc": fc,
                       "upper": [round(f+b,2) for f,b in zip(fc,band)],
                       "lower": [round(f-b,2) for f,b in zip(fc,band)],
                       "last": closes[-1]}
js({
  "kpis": {"tickers": len(tickers), "rows": len(stock), "horizon": 30, "conf": 95,
           "span": "2023–2024"},
  "tickers": list(tickers.keys()),
  "series": dash_series,
}, "stock-forecasting/dashboard/data.js")

# ============================================================ 4. AIRLINES
print("Airlines:")
carriers = ["IndiGo","Air India","Vistara","SpiceJet","AkasaAir","GoFirst"]
airports = ["DEL","BOM","BLR","HYD","MAA","CCU","PNQ","GOI","AMD","COK","JAI","LKO"]
n = 15000
carr = rng.choice(carriers, n, p=[0.34,0.18,0.14,0.16,0.10,0.08])
carrier_delay = {"IndiGo":4,"Air India":11,"Vistara":5,"SpiceJet":9,"AkasaAir":6,"GoFirst":13}
dep_hour = rng.integers(4, 24, n)
base = np.array([carrier_delay[c] for c in carr])
# evening flights and certain carriers delay more
dep_delay = np.maximum(-12, rng.normal(base + (dep_hour>18)*6 + (dep_hour<7)*-3, 10)).round().astype(int)
arr_delay = np.maximum(-15, dep_delay + rng.normal(0, 6, n)).round().astype(int)
cancelled = (rng.random(n) < 0.03).astype(int)
distance = rng.integers(200, 2400, n)
origin = rng.choice(airports, n); dest = rng.choice(airports, n)
flights = pd.DataFrame({
    "flight_id": [f"FL{100000+i}" for i in range(n)],
    "flight_date": [ (pd.Timestamp("2024-01-01") +
                     pd.Timedelta(days=int(d))).date().isoformat() for d in rng.integers(0,365,n)],
    "carrier": carr, "origin": origin,
    "dest": [d if d != o else rng.choice(airports) for o, d in zip(origin, dest)],
    "sched_dep_hour": dep_hour, "dep_delay_min": dep_delay, "arr_delay_min": arr_delay,
    "distance_km": distance, "cancelled": cancelled,
})
w(flights, "airlines/data/flights.csv")

f = flights[flights.cancelled == 0]
ontime = int((f.arr_delay_min <= 15).sum())
delayed = int((f.arr_delay_min > 15).sum())
canc = int(flights.cancelled.sum())
by_carrier = (f.groupby("carrier").arr_delay_min.mean().round(1)
              .sort_values(ascending=False))
by_hour = f.groupby("sched_dep_hour").arr_delay_min.mean().round(1)
routes = (flights.assign(route=flights.origin+"→"+flights.dest)
          .groupby("route").size().sort_values(ascending=False).head(6))
js({
  "kpis": {"flights": len(flights), "ontime_pct": round(ontime/len(flights)*100,1),
           "avg_delay": round(f.arr_delay_min.mean(),1), "cancel_pct": round(canc/len(flights)*100,1),
           "carriers": len(carriers), "routes": flights.assign(r=flights.origin+flights.dest).r.nunique()},
  "status": {"ontime": ontime, "delayed": delayed, "cancelled": canc},
  "by_carrier": [{"name": k, "value": float(v)} for k, v in by_carrier.items()],
  "by_hour": {"hours": [int(h) for h in by_hour.index], "delay": [float(v) for v in by_hour.values]},
  "routes": [{"name": k, "value": int(v)} for k, v in routes.items()],
}, "airlines/dashboard/data.js")

print("\nAll datasets + dashboard data generated.")
