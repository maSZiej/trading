from alpaca_config.keys import config
from alpaca.trading.client import TradingClient
from alpaca.trading.requests import GetAssetsRequest
from alpaca.trading.enums import AssetClass


#webhook_url = https://hooks.slack.com/services/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
#

if __name__=='__main__':
   
  trading_client = TradingClient(config['key_id'], config['secret_key'])

  account = trading_client.get_account()
  #print(account)

  search_params = GetAssetsRequest(asset_class=AssetClass.US_EQUITY)

  assets = trading_client.get_all_assets(search_params)

  print([assets[i].symbol for i in range(len(assets)) if "NV" in assets[i].name ])