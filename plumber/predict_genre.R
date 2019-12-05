library(ranger)
library(randomForest)
library(tidytext)
library(spotifyr)
library(tidyverse)
library(tidymodels)


fetch_track_topics <- function(artist, title) {
  
  genius::genius_lyrics({{ artist }}, {{ title }}) %>% 
    unnest_tokens(word, lyric) %>% 
    anti_join(get_stopwords()) %>% 
    mutate(word = SnowballC::wordStem(word)) %>%
    mutate(id = glue::glue("{artist}....{title}")) %>% 
    count(id, word, sort = TRUE) %>% 
    cast_dtm(id, word, n) %>% 
    identify_topics()
  
}

pred_genre_audio <- function(artist, title) {
  track_audio_features({{ artist }}, {{ title }}) %>%  
    mutate(key = as.factor(key)) %>% 
    bake(audio_recipe, .) %>% 
    # predict audio genre
    predict(audio_classifier, ., type = "prob") %>% 
    select(country_pred_audio = 1) %>% 
    mutate(artist = {{ artist }},
           title = {{ title }}) %>% 
    select(artist, title, country_pred_audio)
}

pred_genre_lyrics <- function(artist, title) {
  
  fetch_track_topics({{ artist }}, {{ title }}) %>% 
    # predict lyric genre
    predict(lyric_classifier, ., type = "prob") %>% 
    select(country_pred_lyric = 1) %>% 
    mutate(artist = {{ artist }},
           title = {{ title }}) %>% 
    select(artist, title, country_pred_lyric)
}

pred_genre_ensemble <- function(artist, title) {
  
  bind_cols(
    # fetch track features
    track_audio_features({{ artist }}, {{ title }}) %>%  
      mutate(key = as.factor(key)) %>% 
      bake(audio_recipe, .) %>% 
      # predict audio genre
      predict(audio_classifier, ., type = "prob") %>% 
      select(country_pred_audio = 1),
    # lyric topic model
    fetch_track_topics({{ artist }}, {{ title }}) %>% 
      # predict lyric genre
      predict(lyric_classifier, ., type = "prob") %>% 
      select(country_pred_lyric = 1)
  ) %>% 

    bake(genre_ensemble_rec, .) %>% 
    predict(genre_ensemble_model, ., type = "prob") %>% 
    mutate(artist = {{ artist }},
           title = {{ title }}) %>% 
    select(artist, title, everything()) %>% 
    janitor::clean_names()
  
}


