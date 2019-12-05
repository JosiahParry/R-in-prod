# Productionizing R with Plumber

This repository contains the materials used for a presentation prepared for the National Science Foundation. 

In this talk I outlined taking a question, in this case "is Old Town Road a country song?", creating a model, making the code "functional", and creating a RESTful API from it. 

## Getting Started

The code used to generate the data uses my unpublished package `bbcharts`. Ensure this is installed by running `remotes::install_github("josiahparry/bbcharts")`.


Additionally, this utilizes the `spotifyr` R package. In order to work with this, you will need to create an API key. Please follow the instructions [here](https://github.com/charlie86/spotifyr/) to generate an API key. I placed this in an `.Rprofile` file in the root of the project directory.

The contents of the `.Rprofile` should look like

```
Sys.setenv(SPOTIFY_CLIENT_ID = 'xxxxxxxxxxxxxxxxxxxxx')
Sys.setenv(SPOTIFY_CLIENT_SECRET = 'xxxxxxxxxxxxxxxxxxxxx')
```

To install the required packages please use the `renv.lock`. Run `renv::restore()`. This will prompt you to install all of the packages that were used in this project. If you do not want to do this or have trouble doing so, please run the following lines of code.

```
pkgs <- c("tidymodels", "topicmodels", "tidyverse", "furrr", "spotifyr", "ranger", "randomForest", "glue", "pins", "C50", "plumber", "furrr")

install.packages(pkgs)
```

## Contents


1. `R`: 
    - this contains the R files used to generate the data and R models that the plumber API is based on. These are ordered from 01 to 03. Run these in order.
    - at the bottom of each script there is a call to `pins` which hosts the data on RStudio Connect. I have changed this code to pin the objects locally. 
2. `plumber`:
    - this contains the `.R` files used to create the API.
    - `plumber.R` sources the `pinned_objects.R` file to read in the model objects from RStudio Connect.
    - `utils.R` is sourced to provide utility functions (think modularization of transformations and data pre-processing) to be used in the plumber API.
    - `predict_genre.R` is sourced to provide functions that are fed to the `plumber.R` file. This enables us to maintain the functions themselves rather than manipulating the plumber.R file. 
        - since we have modularized the operations by creating functions, this also creates an opportunity to develop an R package which has much more rigorous methods of versioning and maintenance. This is my recommended path forward. You will noticed that the `utils.R` file is documented as if it were part of a package. 
3. `plumber-wrapper.py`: this is a python file that creates a python wrapper for the plumber API. 

## Recreate the API

- Run the contents of `R/` in order.
    - note that `01-lyrics.R` and `02-audio.R` may take upwards of 10 minutes to run. 
- open `plumber/plumber.R` and press the `Run API` button at the top of your source editor in RStudio.
