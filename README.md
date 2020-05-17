### Introduction
Climbing has relatively recently picked up in popularity, being included for the first time in the Tokyo 2020 olympics. There is very little data on climbing habits of successful (and unsucessful) climbers, and training routines are generally heavily anecdotal. A reddit user, u/higiff, posted a survey on the "climb harder" subreddit (https://www.reddit.com/r/climbharder/comments/6693ua/climbharder_survey_results/), in order to question climbers about their training habits. This to my knowledge is the largest publically available dataset on climbers and their training strategies.

Having been climbing consistently for around six years now, I was intrigued to see what information this dataset might contain. Causal inference is unfortunately impossible with this dataset, but nevertheless, in the absence of better data, understanding the habits of highly effective climbers is still potentially useful. I will be judging the ability of a climber on their maximum boulder grade, as it is the least subjective measure of climbing ability in the dataset and has few missing values.

The analysis is split into three parts, each having it's own notebook:
- Data cleaning and basic feature extraction (in data_cleaning.ipynb)
- Exploratory data analysis (in eda.ipynb)
- Modelling and analysis (in analysis.ipynb)

Following the analysis, I made a shiny timer app, which implements some of the training strategies which seem to be effective (from both the analysis above, and the general cencus of climbers).

The app is based mostly around hangboard training strategies (which is most of what I have available during the current Covid-19 pandemic). After each excercise, the user can input their results (weight and time), which is automatically added to a google sheets, so people can track their progress.
