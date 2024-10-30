from kafka import KafkaProducer
import json
from alpaca.data import StockHistoricalDataClient,StockBarsRequest
from datetime import datetime
from alpaca_trade_api.common import URL
from alpaca.common import Sort
from typing import List
from alpaca_config.keys import config
from utils import get_sentiment
from alpaca.data.timeframe import TimeFrame

def get_producer(brokers: List[str]):
    producer = KafkaProducer(
        bootstrap_servers = brokers,
        key_serializer= str.encode,
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    return producer



def produce_historical_price(
        redpanda_client: KafkaProducer,
        topic: str,
        start_date:str,
        end_date:str,
        symbol=str       
):
    api = StockHistoricalDataClient(
        api_key=config['key_id'],
        secret_key=config['secret_key'])
    start_date=datetime.strptime(start_date, '%Y-%m-%d')
    end_date=datetime.strptime(end_date,'%Y-%m-%d')
    granularity = TimeFrame.Minute
    request_params=StockBarsRequest(
        symbol_or_symbols=symbol,
        timeframe=granularity,
        start=start_date,
        end=end_date

    )
    prices_df=api.get_stock_bars(request_params).df
    prices_df.reset_index(inplace=True)

    print(prices_df.head())

if __name__ == '__main__':
    redpanda_client=get_producer(config['redpanda_brokers'])
    produce_historical_price(
        redpanda_client,
        topic='stock-prices',
        start_date='2024-01-01',
        end_date='2024-06-01',
        symbol='NVDA'
    )
    redpanda_client.close()