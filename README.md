# Spotify and YouTube Track Analysis (SQL)

![Spotify](spotify_logo.jpg)

SQL analysis of a Spotify and YouTube track dataset in PostgreSQL. I loaded the data, cleaned it, answered 13 business questions from basic filters up to window functions, and then tuned a slow query with an index. **The index cut that query's execution time from 7.97 ms to 0.153 ms, about 52 times faster.**

**Tools:** PostgreSQL, pgAdmin 4
**SQL used:** filtering, GROUP BY / HAVING, subqueries, CTEs, CASE, COALESCE, window functions (DENSE_RANK), EXPLAIN ANALYZE, indexing

## Dataset

The Spotify and YouTube dataset from Kaggle. Each row is one track, with:
- **Track details:** artist, track, album, album type
- **Audio features:** danceability, energy, loudness, liveness, tempo and more
- **YouTube engagement:** views, likes, comments, licensed, official video
- **Spotify:** total streams, and the platform where the track is played most

## Workflow

1. **Table design:** created the `spotify` table with matching types (BIGINT for streams and likes, BOOLEAN for flags).
2. **Exploration:** row counts, distinct artists and albums, album types, and min and max duration.
3. **Cleaning:** found tracks with a duration of 0 minutes and removed them as invalid rows.
4. **Analysis:** wrote 13 queries at three levels (below).
5. **Optimization:** checked the slowest lookup with `EXPLAIN ANALYZE`, added an index and measured again.

## Business questions

**Easy**
1. Which tracks have more than 1 billion streams?
2. List every album with its artist.
3. Total comments on licensed tracks.
4. All tracks released as singles.
5. Number of tracks per artist.

**Medium**

6. Average danceability per album.
7. Top 5 tracks by energy.
8. Views and likes for tracks with an official video.
9. Total views per album.
10. Tracks streamed more on Spotify than on YouTube (conditional aggregation with `CASE` and `COALESCE`).

**Advanced**

11. Top 3 most-viewed tracks for each artist (`DENSE_RANK() OVER (PARTITION BY artist ...)`).
12. Tracks with liveness above the overall average (subquery).
13. Energy range (highest minus lowest) for each album (CTE).

All queries are in [`Spotify_Analysis.sql`](Spotify_Analysis.sql).

## Query optimization

The test query finds an artist's top 25 tracks by streams among tracks played most on YouTube:

```sql
EXPLAIN ANALYZE
SELECT artist, track, views
FROM spotify
WHERE artist = 'Gorillaz'
  AND most_played_on = 'Youtube'
ORDER BY stream DESC
LIMIT 25;
```

Without an index, PostgreSQL read the whole table (sequential scan) to find one artist's rows. I added an index on the column used in the filter:

```sql
CREATE INDEX artist_index ON spotify (artist);
```

| | Execution time | Planning time |
|---|---|---|
| Before index (sequential scan) | 7.97 ms | 0.112 ms |
| After index (index scan) | **0.153 ms** | 0.152 ms |

Execution became about 52 times faster. Planning time went up slightly because the planner now has an index to consider, which is a small cost next to the saving. An index is worth adding on a column that is filtered often and has many distinct values, like `artist`.

## What I learned

- Reading an `EXPLAIN ANALYZE` plan, and telling a sequential scan from an index scan.
- When an index helps, and that it also costs extra planning time and storage.
- Ranking within groups with `DENSE_RANK()` and `PARTITION BY`.
- Pivoting rows into columns with conditional aggregation (`SUM(CASE WHEN ...)`).
- Checking data quality before analysis, for example the zero-duration tracks.

## How to run

1. Create a PostgreSQL database and run the `CREATE TABLE` statement at the top of `Spotify_Analysis.sql`.
2. Import the Kaggle CSV into the `spotify` table (pgAdmin: right-click the table, Import/Export Data).
3. Run the queries one section at a time.

## Author

**Uttkarsh Singh**, Data Analyst
[LinkedIn](https://www.linkedin.com/in/uttkarshsinghdata) · [GitHub](https://github.com/uttkarshrajput)
