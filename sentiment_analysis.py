"""Extract customer reviews from SQL Server and enrich them with VADER sentiment.

Run with Windows integrated authentication after setting SQL_SERVER and SQL_DATABASE.
Output data is stored under data/processed/, which is ignored by Git.
This is a portfolio reference script; validate labels on a hand-reviewed sample.
"""
from __future__ import annotations

import os
from pathlib import Path
from contextlib import closing

import pandas as pd
import pyodbc
from nltk.sentiment.vader import SentimentIntensityAnalyzer

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'data' / 'processed' / 'fact_customer_reviews_with_sentiment.csv'


def fetch_reviews() -> pd.DataFrame:
    server = os.getenv('SQL_SERVER')
    database = os.getenv('SQL_DATABASE')
    driver = os.getenv('SQL_ODBC_DRIVER', 'ODBC Driver 17 for SQL Server')
    if not server or not database:
        raise RuntimeError('Set SQL_SERVER and SQL_DATABASE in the environment.')

    connection_string = (
        f'DRIVER={{{driver}}};SERVER={server};DATABASE={database};'
        'Trusted_Connection=yes;'
    )
    query = """
        SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText
        FROM dbo.fact_customer_reviews
    """
    with closing(pyodbc.connect(connection_string)) as connection:
        return pd.read_sql_query(query, connection)


def categorize_sentiment(score: float, rating: float) -> str:
    if pd.isna(rating):
        return 'Unknown'
    if score > 0.05:
        return 'Positive' if rating >= 4 else ('Mixed Positive' if rating == 3 else 'Mixed Negative')
    if score < -0.05:
        return 'Negative' if rating <= 2 else ('Mixed Negative' if rating == 3 else 'Mixed Positive')
    return 'Positive' if rating >= 4 else ('Negative' if rating <= 2 else 'Neutral')


def sentiment_bucket(score: float) -> str:
    if score >= 0.5:
        return '0.5 to 1.0'
    if score >= 0:
        return '0.0 to 0.49'
    if score >= -0.5:
        return '-0.49 to 0.0'
    return '-1.0 to -0.5'


def main() -> None:
    reviews = fetch_reviews()
    try:
        analyzer = SentimentIntensityAnalyzer()
    except LookupError as exc:
        raise RuntimeError('Download the VADER data first: python -m nltk.downloader vader_lexicon') from exc

    text = reviews['ReviewText'].fillna('').astype(str)
    reviews['Rating'] = pd.to_numeric(reviews['Rating'], errors='coerce')
    reviews['SentimentScore'] = text.map(lambda review: analyzer.polarity_scores(review)['compound'])
    reviews['SentimentCategory'] = reviews.apply(
        lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1
    )
    reviews['SentimentBucket'] = reviews['SentimentScore'].map(sentiment_bucket)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    reviews.to_csv(OUTPUT, index=False, encoding='utf-8')
    print(f'Processed {len(reviews)} reviews. Saved: {OUTPUT}')


if __name__ == '__main__':
    main()
