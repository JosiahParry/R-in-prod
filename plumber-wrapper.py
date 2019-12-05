import pandas as pd
import requests


# using an API key depends on the authentication method connect uses
def post_plumber_endpoint(endpoint, artist, title):
    url_template = "your-api-path/{}?title={}&artist={}"
    url = url_template.format(endpoint, title, artist)
    response = requests.post(url)
    resp_df = pd.read_json(response.content)
    return(resp_df)

def fetch_track_topics(artist, title):
    r = post_plumber_endpoint("track_topics", artist, title)
    return(r)

def fetch_audio_features(artist, title):
    r = post_plumber_endpoint("audio_features", artist, title)
    return(r)


def pred_lyrics(artist, title):
    r = post_plumber_endpoint("predict_lyrics", artist, title)
    return(r)

def pred_audio(artist, title):
    r = post_plumber_endpoint("predict_audio", artist, title)
    return(r)

def pred_ensemble(artist, title):
    r = post_plumber_endpoint("predict_ensemble", artist, title)
    return(r)

