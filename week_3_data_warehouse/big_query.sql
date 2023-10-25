-- Query public available table
SELECT station_id, name FROM
    bigquery-public-data.new_york_citibike.citibike_stations
LIMIT 100;


-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `clear-router-390022.trips_data_all.external_green_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://trip_data_all_clear-router-390022/green/green_tripdata_2019-*.parquet', 'gs://trip_data_all_clear-router-390022/green/green_tripdata_2020-*.parquet']
);

-- Check green trip data
SELECT * FROM clear-router-390022.trips_data_all.external_green_tripdata limit 10;

-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE clear-router-390022.trips_data_all.green_tripdata_non_partitoned AS
SELECT * FROM clear-router-390022.trips_data_all.external_green_tripdata;


-- Create a partitioned table from external table
CREATE OR REPLACE TABLE clear-router-390022.trips_data_all.green_tripdata_partitoned
PARTITION BY
  DATE(tpep_pickup_datetime) AS
SELECT * FROM clear-router-390022.trips_data_all.external_green_tripdata;

-- Impact of partition
-- Scanning 1.6GB of data
SELECT DISTINCT(VendorID)
FROM clear-router-390022.trips_data_all.green_tripdata_non_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';

-- Scanning ~106 MB of DATA
SELECT DISTINCT(VendorID)
FROM clear-router-390022.trips_data_all.green_tripdata_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';

-- Let's look into the partitons
SELECT table_name, partition_id, total_rows
FROM `nytaxi.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'green_tripdata_partitoned'
ORDER BY total_rows DESC;

-- Creating a partition and cluster table
CREATE OR REPLACE TABLE clear-router-390022.trips_data_all.green_tripdata_partitoned_clustered
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS
SELECT * FROM clear-router-390022.trips_data_all.external_green_tripdata;

-- Query scans 1.1 GB
SELECT count(*) as trips
FROM clear-router-390022.trips_data_all.green_tripdata_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID=1;

-- Query scans 864.5 MB
SELECT count(*) as trips
FROM clear-router-390022.trips_data_all.green_tripdata_partitoned_clustered
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID=1;

