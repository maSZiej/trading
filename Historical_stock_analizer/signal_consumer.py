from kafka import KafkaConsumer
from typing import List
import json
from alpaca_config.keys import config
from alpaca_trade_api.common import URL
from alpaca_trade_api import REST





def get_consumer(brokers: List[str],topic:str):
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers = brokers,
        key_deserializer=lambda k: k.decode('utf-8') if k else None, 
        auto_offset_reset='earliest',
        value_deserializer=lambda v: json.loads(v.decode('utf-8'))if v else None,
        enable_auto_commit=True,
    )
    return consumer


def consume_signal_news(
        redpanda_consumer: KafkaConsumer
):
    key_id=config['key_id']
    secret_key = config['secret_key']
    base_url = config['base_url']

    api = REST(key_id=key_id,
               secret_key=secret_key,
               base_url=URL(base_url))
    print("Rozpoczynam konsumpcję danych z topicu...")
    try:
        for message in redpanda_consumer:
            key = message.key
            value = message.value
            topic = message.topic
            partition = message.partition
            offset = message.offset

            #print(f"--- Otrzymano wiadomość ---")
            #print(f"Topic: {topic}, Partition: {partition}, Offset: {offset}")
            #print(f"Key: {key}")
            #print(f"Value: {json.dumps(value, indent=2)}")
            investment_decision = value.get('investment_decision', 'UNKNOWN')
            print(f"Decyzja inwestycyjna: {investment_decision}")
            # Opcjonalnie: wykonaj dodatkowe akcje, np. API Alpaca
            # response = api.some_endpoint(value['data'])
            # print(response)

    except KeyboardInterrupt:
        print("Konsumpcja przerwana.")
    finally:
        redpanda_consumer.close()


if __name__ == '__main__':
    brokers = config['redpanda_brokers']
    topic='investment-decisions'
    consumer = get_consumer(brokers,topic=topic)
    consume_signal_news(consumer)

    




