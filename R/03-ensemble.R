library(ranger)
library(randomForest)
library(tidyverse)
library(tidymodels)

chart_df <- chart_analysis %>% 
  mutate(id = glue::glue("{artist}....{title}")) %>% 
  inner_join(chart_topics) %>% 
  distinct(chart, id, .keep_all = TRUE) %>% 
  select(-c("duration_ms", "time_signature", "type", "mode",
            "rank", "year", "artist", "featured_artist", "title")) %>%
  mutate(chart = as.factor(chart),
         key = as.factor(key))

#------------------------------------------------------------------------------#
#                                 pre-process                                  #
#------------------------------------------------------------------------------#
# Here we use feed the same songs to each model independently. Then, the pred- #
# -ictions will be used as our training data set.                              #
#                                                                              #
# `train_preds` and `test_preds` will be used for training and testing sets.   #
#------------------------------------------------------------------------------#

set.seed(1)
init_split <- initial_split(chart_df, strata = "chart")
train_df <- training(init_split)
test_df <- testing(init_split)

train_preds <- bind_cols(
  predict(audio_classifier, train_df, type = "prob") %>% 
    select(country_pred_audio = 1),
  predict(lyric_classifier, train_df, type = "prob") %>% 
    select(country_pred_lyric = 1)
) %>% 
  bind_cols(select(train_df, chart)) %>% 
  janitor::clean_names()


test_preds <- bind_cols(predict(audio_classifier, test_df, type = "prob") %>% 
                          select(country_pred_audio = 1),
                        predict(lyric_classifier, test_df, type = "prob") %>% 
                          select(country_pred_lyric = 1)
                          ) %>% 
  bind_cols(select(test_df, chart)) %>% 
  janitor::clean_names()


#------------------------------------------------------------------------------#
#                                model training                                #
#------------------------------------------------------------------------------#
chart_rec <- recipe(chart ~ ., data = train_preds)  %>%
  step_center(all_numeric()) %>%
  step_scale(all_numeric()) %>%
  prep()


baked_train <- bake(chart_rec, train_preds)
baked_test <- bake(chart_rec, test_preds)


ranger_fit <- rand_forest(mode = "classification") %>%
  set_engine("ranger") %>%
  fit(chart ~ ., data = baked_train)

rf_fit <- rand_forest(mode = "classification") %>%
  set_engine("randomForest") %>%
  fit(chart ~ ., data = baked_train)

c50_fit <- decision_tree(mode = "classification") %>%
  set_engine("C5.0") %>%
  fit(chart ~ ., data = baked_train)

#------------------------------------------------------------------------------#
#                                  evaluation                                  #
#------------------------------------------------------------------------------# 

rf_estimates <- predict(rf_fit, baked_test) %>%
  bind_cols(baked_test) %>%
  yardstick::metrics(truth = chart, estimate = .pred_class)

ranger_estimates <- predict(ranger_fit, baked_test) %>%
  bind_cols(baked_test) %>%
  yardstick::metrics(truth = chart, estimate = .pred_class)

c50_estimates <- predict(c50_fit, baked_test) %>%
  bind_cols(baked_test) %>%
  yardstick::metrics(truth = chart, estimate = .pred_class)

bind_rows(
  rf_estimates,
  ranger_estimates,
  c50_estimates
) %>% 
  filter(.metric == "accuracy") %>% 
  mutate(model = c("rf", "ranger rf", "c50"))

genre_ensemble_model <- ranger_fit
genre_ensemble_rec <- chart_rec

#------------------------------------------------------------------------------#
#                              pin model objects                               #
#------------------------------------------------------------------------------#

pins::board_register()

# pin the tiopic model
pins::pin(x = genre_ensemble_model,
          name = "genre_ensemble_model")

pins::pin(x = genre_ensemble_rec,
          name = "genre_ensemble_rec")


