CREATE TABLE market_news2(
    id BIGINT,
    author VARCHAR,
    headline VARCHAR,
    source VARCHAR,
    summary VARCHAR,
    data_provider VARCHAR,
    `url` VARCHAR,
    symbol VARCHAR,
    sentinent VARCHAR,
    timestamp_ms BIGINT,
    event_time AS TO_TIMESTAMP_LTZ(timestamp_ms,3),
    WATERMARK for event_time AS event_time - INTERVAL '5' SECOND
) WITH(
    'connector' = 'kafka',
    'topic' = 'market-news',
    'properties.bootstrap.servers' = 'redpanda-1:29092,redpanda-2:29093',
    'properties.group.id' = 'market-news-group',
    'properties.auto.offset.reset' = 'earliest',
    'format' = 'json'
);


CREATE TABLE stock_prices2 (
    symbol VARCHAR,
    `open` FLOAT,
    high FLOAT,
    low FLOAT,
    `close` FLOAT,
    volume DECIMAL,
    trade_count BIGINT,
    data_provider VARCHAR,
    vwrap DECIMAL,
    `timestamp` BIGINT,
    event_time AS TO_TIMESTAMP_LTZ(`timestamp`,3),
    WATERMARK for event_time AS event_time - INTERVAL '5' SECOND
)WITH(
    'connector' = 'kafka',
    'topic' = 'stock-prices',
    'properties.bootstrap.servers' = 'redpanda-1:29092,redpanda-2:29093',
    'properties.group.id' = 'stock-prices-group',
    'properties.auto.offset.reset' = 'earliest',
    'format' = 'json'
);



















# KŁOPOT ŚREDNIEJ CENY
# Problem polega na tym że nie bierze pod uwage wszystkich cen z ostatnich 5 dni tylko te które nie sa nullami wytworzonymi przez joina
# warto zauważyc ze inner join rzadko kiedy zwraca nulle ale left join juz tak wiec wartosci w inner join sa ukryte bardziej niz np w left join
# ROZWIAZANY - zamiast obliczac cene srednia przez podzapytanie obliczam ja w oknie z funkcja AVG 


INSERT INTO investment_decisions5
SELECT
    t.symbol,
    t.event_time AS stock_time,
    t.close_price,
    t.avg_close_price,
    t.news_time,
    JSON_VALUE(t.sentinent, '$[0]') as sentinent_label,
    JSON_VALUE(t.sentinent, '$[1]') as sentinent_score,
    CASE
        WHEN JSON_VALUE(t.sentinent, '$[0]') = 'Positive' AND t.avg_close_price < t.close_price THEN 'BUY'
        WHEN JSON_VALUE(t.sentinent, '$[0]') = 'Negative' AND t.avg_close_price > t.close_price THEN 'SELL'
        ELSE 'HOLD'
    END AS investment_decision
FROM (
    SELECT
        sp.symbol,
        sp.event_time,
        sp.`close` AS close_price,
        AVG(sp.`close`) OVER (
        PARTITION BY sp.symbol
        ORDER BY sp.event_time
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS avg_close_price,
        mn.event_time AS news_time,
        mn.sentinent
    FROM stock_prices2 sp
    inner JOIN market_news2 mn
    ON sp.symbol = mn.symbol
       AND mn.event_time BETWEEN sp.event_time - INTERVAL '30' MINUTE AND sp.event_time) t ;




AVG(sp2.`close`) OVER (
    PARTITION BY sp.symbol
    ORDER BY sp.event_time
    ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
) AS avg_close_price



CREATE TABLE investment_decisions5 (
    symbol STRING,
    stock_time TIMESTAMP(3),
    close_price FLOAT,
    avg_close_price FLOAT,
    news_time TIMESTAMP(3),
    sentinent_label STRING,
    sentinent_score STRING,
    investment_decision STRING,
    PRIMARY KEY (symbol, stock_time) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'investment-decisions',
    'properties.bootstrap.servers' = 'redpanda-1:29092,redpanda-2:29093',
    'key.format' = 'json',
    'value.format' = 'json'
);



#######################PROBA Z VADER


INSERT INTO investment_decisions6
SELECT
    t.symbol,
    t.event_time AS stock_time,
    t.close_price,
    t.avg_close_price,
    t.news_time,
    CAST(t.sentinent AS FLOAT) AS sentinent,
    CASE
        WHEN CAST(t.sentinent AS FLOAT)> 0.05 AND t.avg_close_price < t.close_price THEN 'BUY'
        WHEN CAST(t.sentinent AS FLOAT) < -0.05 AND t.avg_close_price > t.close_price THEN 'SELL'
        ELSE 'HOLD'
    END AS investment_decision
FROM (
    SELECT
        sp.symbol,
        sp.event_time,
        sp.`close` AS close_price,
        AVG(sp.`close`) OVER (
        PARTITION BY sp.symbol
        ORDER BY sp.event_time
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS avg_close_price,
        mn.event_time AS news_time,
        mn.sentinent
    FROM stock_prices2 sp
    inner JOIN market_news2 mn
    ON sp.symbol = mn.symbol
       AND mn.event_time BETWEEN sp.event_time - INTERVAL '30' MINUTE AND sp.event_time) t ;





CREATE TABLE investment_decisions6 (
    symbol STRING,
    stock_time TIMESTAMP(3),
    close_price FLOAT,
    avg_close_price FLOAT,
    news_time TIMESTAMP(3),
    sentinent FLOAT,
    investment_decision STRING,
    PRIMARY KEY (symbol, stock_time) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'investment-decisions',
    'properties.bootstrap.servers' = 'redpanda-1:29092,redpanda-2:29093',
    'key.format' = 'json',
    'value.format' = 'json'
);