from fastapi import FastAPI, HTTPException
import numpy as np
import uvicorn
import math
from PSHA_India import compute_uhs 

app = FastAPI(title="SlopeSafe Hazard API")

# --- NEW SAFETY FUNCTION: Prevents JSON crashes by replacing NaN with 0.0 ---
def clean_for_json(data_list):
    """Replaces NaN values with 0.0 to ensure JSON compliance."""
    return [0.0 if (x is None or (isinstance(x, float) and math.isnan(x))) else x for x in data_list]

def get_RS_spectra(T, site_class, direction='H'):
    T = np.asarray(T, dtype=float)
    A = np.zeros_like(T)
    site_class = site_class.upper()
    direction = direction.upper()

    if direction == 'H':
        if site_class in ['A', 'B']:
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.4), (T > 0.4) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 1.0 / T[r4], 6.0 / (T[r5] ** 2)
        elif site_class == 'C':
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.6), (T > 0.6) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 1.5 / T[r4], 9.0 / (T[r5] ** 2)
        elif site_class == 'D':
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.8), (T > 0.8) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 2.0 / T[r4], 12.0 / (T[r5] ** 2)

    elif direction == 'V':
        delta_v = np.zeros_like(T)
        if site_class in ['A', 'B']:
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.4), (T > 0.4) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 1.0 / T[r4], 6.0 / (T[r5] ** 2)
            d1, d2, d3 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.10), (T > 0.10)
            delta_v[d1], delta_v[d2], delta_v[d3] = 0.80, 0.80 - (200.0 / 135.0) * (T[d2] - 0.01), 0.67
        elif site_class == 'C':
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.6), (T > 0.6) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 1.5 / T[r4], 9.0 / (T[r5] ** 2)
            d1, d2, d3 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.10), (T > 0.10)
            delta_v[d1], delta_v[d2], delta_v[d3] = 0.82, 0.82 - (213.0 / 125.0) * (T[d2] - 0.01), 0.67
        elif site_class == 'D':
            r1, r2, r3, r4, r5 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.1), (T > 0.1) & (T <= 0.8), (T > 0.8) & (T <= 6.0), (T > 6.0) & (T <= 10.0)
            A[r1], A[r2], A[r3], A[r4], A[r5] = 1.0, 1.0 + (50.0 / 3.0) * (T[r2] - 0.01), 2.5, 2.0 / T[r4], 12.0 / (T[r5] ** 2)
            d1, d2, d3 = (T >= 0) & (T <= 0.01), (T > 0.01) & (T <= 0.10), (T > 0.10)
            delta_v[d1], delta_v[d2], delta_v[d3] = 0.85, 0.85 - (200.0 / 100.0) * (T[d2] - 0.01), 0.67
        A = A * delta_v
    return A

@app.get("/api/get_hazard_data")
def get_hazard_data(lat: float, lon: float, site_class: str = 'C', return_period: int = 475):
    # --- NEW SAFETY CHECK: India data bounds ---
    if not (60.0 <= lon <= 100.0) or not (2.0 <= lat <= 40.0):
        raise HTTPException(status_code=400, detail="Location outside of supported Indian seismic data range.")
        
    try:
        result = compute_uhs(longitude=lon, latitude=lat, return_period=return_period)
        periods = result["periods"]
        
        # --- APPLY CLEANING: Replaces NaN with 0.0 ---
        psa = clean_for_json(result["psa"])
        rs_h = clean_for_json(get_RS_spectra(periods, site_class, 'H').tolist())
        rs_v = clean_for_json(get_RS_spectra(periods, site_class, 'V').tolist())

        return {
            "status": "success",
            "nearest_grid_lat": result["latitude"],
            "nearest_grid_lon": result["longitude"],
            "data": {
                "periods": periods,
                "psa": psa,
                "rs_horizontal": rs_h,
                "rs_vertical": rs_v
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal Processing Error: {str(e)}")

if __name__ == "__main__":
    # Note: Use port 80 for public AWS access
    uvicorn.run(app, host="0.0.0.0", port=80)