from nltk.sentiment.vader import SentimentIntensityAnalyzer as SIA 
from transformers import pipeline

sentiment_pipeline = pipeline("sentiment-analysis", model="yiyanghkust/finbert-tone")

def get_advanced_sentiment(text):
    result = sentiment_pipeline(text)[0]
    return result['label'], result['score']

# Test

sia=SIA()

def get_sentiment(text):
    score=sia.polarity_scores(text)
    return score['compound']


if __name__ == '__main__':
    examples = [
        "Tesla stock surges after earnings report",
        "Market crash affects major tech stocks",
        "Neutral news without sentiment",
        "This is the worst product ever. I hate it and I regret buying it."
    ]
    for example in examples:
        print(f"Headline: {example}, Sentiment: {get_sentiment(example)}")
        print(get_advanced_sentiment(example))
    