library(pins)


board_register_rsconnect(server = "connect-server",
                         account = "connect-user",
                         key = "connect-api-key")

genre_topic_model <- pin_get("genre_topic_model")
lyric_classifier <- pin_get("genre_lyric_classifier")
audio_recipe <- pin_get("genre_audio_recipe")
audio_classifier <- pin_get("genre_audio_classifier")
genre_ensemble_rec <- pin_get("genre_ensemble_rec")
genre_ensemble_model <- pin_get("genre_ensemble_model")

# fetch_track_topics("Kendrick Lamar", "Backseat freestyle")
# track_audio_features("Kendrick Lamar", "Backseat freestyle")
# pred_genre_audio("Kendrick Lamar", "Backseat freestyle")
# pred_genre_lyrics("Kendrick Lamar", "Backseat freestyle")
# pred_genre_ensemble("Kendrick Lamar", "Backseat freestyle")
