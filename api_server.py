from fastapi import FastAPI, HTTPException
import numpy as np
import uvicorn

# Import your existing compute_uhs function from your PSHA_India file
from PSHA_India import compute_uhs 

app = FastAPI(title="SlopeSafe Hazard API")

# Your exact RS Spectra function
def get_RS_spectra(T, site_class, direction='H'):
    T = np.asarray(T, dtype=float)
    A = np.zeros_like(T)
    site_class = site_class.upper()
    direction = direction.upper()

    if direction == 'H':
        if site_class in ['A', 'B']:
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.4)
            r4 = (T > 0.4) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 1.0 / T[r4]
            A[r5] = 6.0 / (T[r5] ** 2)
            
        elif site_class == 'C':
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.6)
            r4 = (T > 0.6) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 1.5 / T[r4]
            A[r5] = 9.0 / (T[r5] ** 2)
            
        elif site_class == 'D':
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.8)
            r4 = (T > 0.8) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 2.0 / T[r4]
            A[r5] = 12.0 / (T[r5] ** 2)

    elif direction == 'V':
        delta_v = np.zeros_like(T)
        
        if site_class in ['A', 'B']:
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.4)
            r4 = (T > 0.4) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 1.0 / T[r4]
            A[r5] = 6.0 / (T[r5] ** 2)
            
            d1 = (T >= 0) & (T <= 0.01)
            d2 = (T > 0.01) & (T <= 0.10)
            d3 = (T > 0.10)
            delta_v[d1] = 0.80
            delta_v[d2] = 0.80 - (200.0 / 135.0) * (T[d2] - 0.01)
            delta_v[d3] = 0.67
            
        elif site_class == 'C':
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.6)
            r4 = (T > 0.6) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 1.5 / T[r4]
            A[r5] = 9.0 / (T[r5] ** 2)
            
            d1 = (T >= 0) & (T <= 0.01)
            d2 = (T > 0.01) & (T <= 0.10)
            d3 = (T > 0.10)
            delta_v[d1] = 0.82
            delta_v[d2] = 0.82 - (213.0 / 125.0) * (T[d2] - 0.01)
            delta_v[d3] = 0.67
            
        elif site_class == 'D':
            r1 = (T >= 0) & (T <= 0.01)
            r2 = (T > 0.01) & (T <= 0.1)
            r3 = (T > 0.1) & (T <= 0.8)
            r4 = (T > 0.8) & (T <= 6.0)
            r5 = (T > 6.0) & (T <= 10.0)
            A[r1] = 1.0
            A[r2] = 1.0 + (50.0 / 3.0) * (T[r2] - 0.01)
            A[r3] = 2.5
            A[r4] = 2.0 / T[r4]
            A[r5] = 12.0 / (T[r5] ** 2)
            
            d1 = (T >= 0) & (T <= 0.01)
            d2 = (T > 0.01) & (T <= 0.10)
            d3 = (T > 0.10)
            delta_v[d1] = 0.85
            delta_v[d2] = 0.85 - (200.0 / 100.0) * (T[d2] - 0.01)
            delta_v[d3] = 0.67
            
        A = A * delta_v

    return A

@app.get("/api/get_hazard_data")
def get_hazard_data(lat: float, lon: float, site_class: str = 'C', return_period: int = 475):
    try:
        # 1. Fetch data from your .mat file via PSHA_India.py
        result = compute_uhs(longitude=lon, latitude=lat, return_period=return_period)
        
        # 2. Extract periods to feed into your RS function
        periods = result["periods"]
        psa = result["psa"]
        
        # 3. Calculate RS Spectra for both directions
        rs_horizontal = get_RS_spectra(periods, site_class, 'H').tolist()
        rs_vertical = get_RS_spectra(periods, site_class, 'V').tolist()

        # 4. Return as a clean JSON response for Flutter
        return {
            "status": "success",
            "nearest_grid_lat": result["latitude"],
            "nearest_grid_lon": result["longitude"],
            "data": {
                "periods": periods,
                "psa": psa,
                "rs_horizontal": rs_horizontal,
                "rs_vertical": rs_vertical
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)