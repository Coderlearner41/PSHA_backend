import geopandas as gpd
import pandas as pd
import os

# Define the grouping for the seismic zones ONLY
zone_files = {
    "Zone_II": [
        'Zone_II_e.shp',
        'North_Zone_II_NewBDRY_Projec3.shp',
        'South_end_Zone_II_NewBDRY_Pr3.shp',
        'South_Zone_II_rev_1_Project_3.shp',
        'Central_circle_II_rev_Projec6.shp',
    ],
    "Zone_III": [
        'IGB_ZONE_III_NewBDRY_Project3.shp',
        'Latur_III_Project_PointsToLi1.shp',
    ],
    "Zone_IV": [
        'Zone_IV_a.shp',
        'Gujarat_Zone_IV_NewBDRY_Proj6.shp',
        'Koyna_IV_NewBDRY_Project_Poi1.shp',
    ],
    "Zone_V": [
        'Gujarat_Zone_V_NewBDRY_Proje9.shp',
        'Himalaya_Zone_V_Dli_NewBDRY_5.shp',
        'Himalaya_Zone_V_NewBDRY_Proj3.shp',
        'Koyna_V_NewBDRY_Project_Poin1.shp',
        'North_East_NewBDGY_Project_P1.shp'
    ],
    "Zone_VI": [
        'Gujarat_Zone_VI_NewBDRY_Proj3.shp',
        'Himalaya_Zone_VI_NewBDRY_Pro3.shp'
    ]
}

# The extensions that make up a complete shapefile bundle
shapefile_extensions = ['.shp', '.shx', '.dbf', '.prj', '.cpg', '.sbn', '.sbx', '.shp.xml']

def merge_and_clean_shapefiles(target_dir):
    for zone, files in zone_files.items():
        gdf_list = []
        for file in files:
            filepath = os.path.join(target_dir, file)
            if os.path.exists(filepath):
                print(f"Reading {file}...")
                gdf = gpd.read_file(filepath)
                gdf_list.append(gdf)
            else:
                print(f"Warning: {file} not found in {target_dir}.")

        if gdf_list:
            # Concat all dataframes for the current zone
            merged_gdf = gpd.GeoDataFrame(pd.concat(gdf_list, ignore_index=True), crs=gdf_list[0].crs)
            
            # Save the combined shapefile back to the same folder
            output_path = os.path.join(target_dir, f"{zone}.shp")
            merged_gdf.to_file(output_path)
            print(f"Successfully saved {output_path}!\n")

            # SAFELY DELETE ORIGINAL FRAGMENT FILES
            print(f"Cleaning up old {zone} files...")
            for file in files:
                base_name = os.path.splitext(file)[0]
                # Delete all associated extensions (.dbf, .shx, etc) for this specific file
                for ext in shapefile_extensions:
                    file_to_delete = os.path.join(target_dir, base_name + ext)
                    if os.path.exists(file_to_delete):
                        os.remove(file_to_delete)
                        print(f"  - Deleted: {base_name}{ext}")
            print("-" * 30)

if __name__ == "__main__":
    # Point this to your Flutter project's assets folder
    target_directory = './' 
    
    print("Starting merge and cleanup process...")
    merge_and_clean_shapefiles(target_dir=target_directory)
    print("Done! Your assets folder is now clean, and untouched files were left alone.")