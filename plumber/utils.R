library(topicmodels)
library(purrr)
library(spotifyr)
library(dplyr)
#' Apply genre topic model probabilities
#' 
#' This function takes a DocumentTermMatrix (DTM) and identifies LDA topic model probabilities. 
#' 
#' @param track_dtm A DocumentTermMatrix where each observation is an individual track. Terms are the stemmed word unigram count of each word with stopwords removed.
#' 
#' @importFrom topicmodels posterior
#' @importFrom purrr pluck
#' @importFrom tibble as_tibble
#' @importFrom janitor clean_names
#' @importFrom magrittr %>% 
#' @export

identify_topics <- function(track_dtm) {
  
  posterior(genre_topic_model, track_dtm) %>% 
    pluck(2) %>% 
    as_tibble(rownames = "id") %>% 
    janitor::clean_names()
  
}

#' Fetch audio features from spotify
#' 
#' This function retrieves a song's audio features from spotify based on the artist name and track title. 
#' 
#' @param artist Artist Name
#' @param title Song Title
#' @param type The type of item to search for in spotify. See `?spotifyr::search_spotify()`
#' 
#' @importFrom spotifyr search_spotify get_track_audio_features
#' @importFrom purrr possibly
#' @importFrom dplyr select mutate
#' @importFrom magrittr %>% 
#' @importFrom glue glue
#' @importFrom tibble tibble
#' 
#' @details This function retrieves the first observation returned from the spotifyr search. This may be prone to errors. When this function fails, it returns an empty tibble.
#' @export

track_audio_features <- possibly(.f = {
  function(artist, title, type = "track") {
    search_results <- search_spotify(paste(artist, title), type = type)
    track_audio_feats <- get_track_audio_features(search_results$id[[1]]) %>%
      dplyr::select(-id, -uri, -track_href, -analysis_url) %>% 
      mutate(id = glue::glue("{artist}....{title}")) %>% 
      select(id, everything())
    
    return(track_audio_feats)
  }}, otherwise = tibble())
