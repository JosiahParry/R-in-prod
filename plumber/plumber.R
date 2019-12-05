library(pins)
library(plumber)
library(ranger)
library(randomForest)
library(tidytext)
library(spotifyr)
library(tidyverse)
library(tidymodels)

source("pinned_objects.R")
source("utils.R")
source("predict_genre.R")


# include explicit fetching of spotifyr api token
access_token <- get_spotify_access_token()

#* @apiTitle Rap or Country Genre Prediction

#* Identify lyric LDA topic probabilities
#* @param artist The name of the artist
#* @param title The title of the song
#* @post /track_topics
function(artist, title) {
  fetch_track_topics({{ artist }}, {{ title }})
}

#* Retrieve a songs audio features from Spotifyr
#* @param artist The name of the artist
#* @param title The title of the song
#* @post /audio_features
function(artist, title){
  track_audio_features({{ artist }}, {{ title }})
}

#* Predict song genre based on song lyrics
#* @param artist The name of the artist
#* @param title The title of the song
#* @post /predict_lyrics
function(artist, title) {
  pred_genre_lyrics({{ artist }}, {{ title }})
}

#* Predict song genre based on a song's audio features
#* @param artist The name of the artist
#* @param title The title of the song
#* @post /predict_audio
function(artist, title) {
  pred_genre_audio({{ artist }}, {{ title }})
}

#* Predict song genre based on song lyrics and audio features
#* @param artist The name of the artist
#* @param title The title of the song
#* @post /predict_ensemble
function(artist, title) {
  pred_genre_ensemble({{ artist }}, {{ title }})
}

