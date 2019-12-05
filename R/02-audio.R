library(spotifyr)
library(tidyverse)
library(tidymodels)
library(purrr)

track_audio_features <- possibly(.f = {
  function(artist, title, type = "track") {
    search_results <- search_spotify(paste(artist, title), type = type)
    track_audio_feats <- get_track_audio_features(search_results$id[[1]]) %>%
      dplyr::select(-id, -uri, -track_href, -analysis_url)
    
    return(track_audio_feats)
  }}, otherwise = tibble())



chart_analysis <- charts %>%
  mutate(audio_features = map2(artist, title, track_audio_features)) %>%
  unnest(audio_features) %>% 
  as_tibble()

clean_chart <- select(chart_analysis, 
                      -c("duration_ms", "time_signature", "type", "mode",
                         "rank", "year", "artist", "featured_artist", "title")) %>%
  mutate(chart = as.factor(chart),
         key = as.factor(key))


# set a seed for reproducibility 
set.seed(0)

# partition data
init_split <- initial_split(clean_chart, strata = "chart")

# extract training set
train_df <- training(init_split)

# extract testing set
test_df <- testing(init_split)


chart_rec <- recipe(chart ~ ., data = train_df)  %>%
  step_center(all_numeric()) %>%
  step_scale(all_numeric()) %>%
  prep()


# apply pre-processing to create tibbles ready for modeling
baked_train <- bake(chart_rec, train_df)
baked_test <- bake(chart_rec, test_df)


audio_classifier <- rand_forest(mode = "classification") %>%
  set_engine("ranger") %>%
  fit(chart ~ ., data = baked_train)


ranger_estimates <- predict(audio_classifier, baked_test) %>%
  bind_cols(baked_test) %>%
  metrics(truth = chart, estimate = .pred_class)


#------------------------------------------------------------------------------#
#                              pin model objects                               #
#------------------------------------------------------------------------------#

pins::board_register()

pins::pin(audio_classifier,
          name = "genre_audio_classifier")

pins::pin(audio_recipe,
          name = "genre_audio_recipe")

#usethis::use_data(audio_classifier, audio_recipe)
