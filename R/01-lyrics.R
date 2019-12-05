library(topicmodels)
library(tidymodels)
library(tidyverse)
library(tidytext)
library(bbcharts)
library(furrr)
plan(multisession)


#------------------------- Retrieve Billboard Charts --------------------------#

chart_grid <- crossing(
  chart = c("hot-country-songs", "hot-rap-songs"),
  year = 2015:2018
)


charts <- chart_grid %>% 
  mutate(chart_ranks = map2(.x = chart, .y = year, year_end_bb)) %>%
  select(chart_ranks) %>% 
  unnest()

#------------------------- fetch lyrics for each song -------------------------#
chart_lyrics <- distinct(charts, chart, artist, title) %>% 
  mutate(lyrics = future_map2(artist, title, genius::possible_lyrics))

# create unigrams
lyric_unigrams <- chart_lyrics %>% 
  unnest(lyrics) %>% 
  # create unigrams
  unnest_tokens(word, lyric) %>% 
  # remove stop words
  anti_join(get_stopwords()) %>% 
  # stem each word
  mutate(word = SnowballC::wordStem(word)) 


lyric_counts <- lyric_unigrams %>%
  mutate(id = glue::glue("{artist}....{title}")) %>% 
  count(id, word, sort = TRUE)

lyric_dtm <- lyric_counts %>% 
  cast_dtm(id, word, n)


lda_5 <- LDA(lyric_dtm, k = 5, control = list(seed = 0))

lda_inf <- posterior(lda_5, lyric_dtm)

# extract document class probabilities 
chart_lda <- lda_inf[[2]] %>% 
  as_tibble(rownames = "id")

chart_topics <- charts %>% 
  mutate(id = glue::glue("{artist}....{title}")) %>% 
  distinct(chart, id) %>% 
  right_join(chart_lda) %>% 
  janitor::clean_names()


#------------------------------- pre-processing -------------------------------#
set.seed(0)
init_split <- initial_split(chart_topics, strata = "chart")
train_df <- training(init_split)
test_df <- testing(init_split)

# create recipe
chart_rec <- recipe(chart ~ x1 + x2 + x3 + x4 + x5, data = train_df) %>% 
  prep()

# bake the training and testing to have clean dfs
baked_train <- bake(chart_rec, train_df)
baked_test <- bake(chart_rec, test_df)


#--------------------------------- model fit ----------------------------------#

lyric_classifier <- rand_forest(mode = "classification") %>%
  set_engine("randomForest") %>%
  fit(chart ~ ., data = baked_train)


#------------------------------ model evaluation ------------------------------#
rf_estimates <- predict(lyric_classifier, baked_test) %>%
  bind_cols(baked_test) %>%
  yardstick::metrics(truth = chart, estimate = .pred_class)

rf_estimates

#------------------------------------------------------------------------------#
#                              pin model objects                               #
#------------------------------------------------------------------------------#

pins::board_register()

# pin the lyric classifier 
pins::pin(x = lyric_classifier,
          name = "genre_lyric_classifier")

# pin the tiopic model
pins::pin(x = lda_5,
          name = "genre_topic_model")


