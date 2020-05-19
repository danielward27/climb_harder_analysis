### Introduction
Climbing has relatively recently picked up in popularity, being included for the first time in the Tokyo 2020 Olympics. There is very little data on climbing habits of successful (and unsuccessful) climbers, and training routines are generally heavily anecdotal. A reddit user, u/higiff, posted a survey on the "climb harder" subreddit (https://www.reddit.com/r/climbharder/comments/6693ua/climbharder_survey_results/). Using this survey, I identified some of the habits of highly successful climbers, and using this information subsequently made a training app.

The analysis is split into three parts, each having it's own notebook:
- Data cleaning and basic feature extraction (in data_cleaning.ipynb)
- Exploratory data analysis (in eda.ipynb)
- Modelling and analysis (in analysis.ipynb)

The app is based mostly around hangboard training strategies (which is most of what I have available during the current Covid-19 pandemic). App features include:
- A timer that beeps to indicate the user to carry out the specified exercise.
- An easy way to record data, which is automatically uploaded to a google sheets page.
- Graphs of the data, so users can track their progress.
