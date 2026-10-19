-- Spotify and YouTube track analysis (PostgreSQL)
-- Author: Uttkarsh Singh

-- create table

CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

-- EDA 

SELECT * FROM spotify;

SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;

SELECT COUNT(DISTINCT album) FROM spotify;

SELECT DISTINCT album_type FROM spotify;

SELECT MAX(duration_min) FROM spotify;

SELECT MIN(duration_min) FROM spotify;
-- Some tracks have a duration of 0 minutes, which is not possible, so they are removed.

SELECT * FROM spotify
WHERE duration_min = 0;


DELETE FROM spotify
WHERE duration_min = 0;

-- Data Analysis

-- Q.1. Retrieve the names of all tracks that have more than 1 billion streams.

SELECT track 
FROM spotify
WHERE stream > 1000000000;

-- Q.2. List all the albums along with their respective artists. 

SELECT DISTINCT album, artist FROM spotify
ORDER BY 1;

-- Q.3. Get the total number of comments for tracks where licensed = TRUE.

SELECT 
SUM(comments) AS total_comments
FROM spotify
WHERE licensed = TRUE;

-- Q.4. Find all the tracks that belong to the album type single.

SELECT track
FROM spotify
WHERE album_type = 'single';

-- Q.5. Count the total number of tracks by each artist.

SELECT
    artist,
    COUNT(*) AS total_no_of_songs
FROM spotify
GROUP BY 1;

-- Q.6. Calculate the average danceability of tracks in each album.

SELECT
    album,
AVG(danceability) AS avg_danceability
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- Q.7. Find the top 5 tracks with the highest energy values.

SELECT track, MAX(energy) AS max_energy
FROM spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Q.8. List all the tracks along with their total views and likes where official_video = True.

SELECT
    track,
	SUM(views) AS total_views,
	SUM(likes) AS total_likes
FROM spotify
WHERE official_video = TRUE
GROUP BY 1;

-- Q.9. For each album, calculate the total views of all associated tracks.

SELECT 
    album,
	SUM(views) AS total_views
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- Q.10. Retrieve the track names that have been streamed on Spotify more than on YouTube.

SELECT * FROM
(SELECT 
    track,
	COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) AS streamed_on_youtube,
	COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS streamed_on_Spotify
FROM spotify
GROUP BY 1)
AS t1
WHERE streamed_on_Spotify > streamed_on_Youtube
AND
streamed_on_Youtube <> 0;

-- Q.11. Find the top 3 most-viewed tracks for each artist using window functions.

WITH ranking_artist
AS
(SELECT
    artist,
    track,
    SUM(views) AS total_view,
    DENSE_RANK() OVER (
        PARTITION BY artist 
        ORDER BY SUM(views) DESC
    ) AS rank
FROM spotify
GROUP BY 1, 2
ORDER BY 1, 3 DESC
)
SELECT * FROM ranking_artist
WHERE rank <= 3;

-- Q.12. Write a query to find tracks where the liveness score is above the average.

SELECT track FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify);

-- Q.13. Use a with clause to calculate the difference between the highest and lowest energy values for tracks in each album.

WITH CTE
AS
(SELECT
	album,
	MAX(energy) AS highest_energy,
	MIN(energy) AS lowest_energy
FROM spotify
GROUP BY 1
)
SELECT 
	album,
	highest_energy - lowest_energy AS energy_range
FROM CTE
ORDER BY 2 DESC;


-- Query Optimization

-- Before indexing: execution time 7.97 ms, planning time 0.112 ms (sequential scan)
EXPLAIN ANALYZE
SELECT
    artist,
    track,
    views
FROM spotify
WHERE artist = 'Gorillaz'
  AND most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;

CREATE INDEX artist_index ON spotify (artist);

-- After indexing: execution time 0.153 ms, planning time 0.152 ms (index scan on artist_index)
-- About 52 times faster than before.
EXPLAIN ANALYZE
SELECT
    artist,
    track,
    views
FROM spotify
WHERE artist = 'Gorillaz'
  AND most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;
