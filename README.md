# Data-Science-Exam-2023
Data Science Exam for Asger L. Christiansen at the Master's Degree at Cognitive Science, Aarhus University, 2023.
### DEPENDENCIES
The present code uses pacman to load packages, and at minimum requires an installation of pacman to run. For details on package versions, see the report.

### REPO STRUCTURE

## Root directory
The root contains all the code necessary to perform the analysis and reproduce the results, including three numbered markdowns which should be run in order if you wish to reproduce everything. However, it should be possible to skip Markdown nr. 1 and go straight to number 2, since I've put the preprocessed data in the Cleaned Data folder.
Upon setting the working directory to the root folder, the three markdowns in the root directory should be able to be run without any errors.

# Gun Violence Functions.R
This is an R-script which contains all the necessary functions for the code to run. Comments are included that describe what functions do, but not every line of code is commented. An attempt has been made to pick variable and function names that are sensible and intuitive. That said, the dataset is messy (try having a look at the incidents_characteristics column yourself!), so the data wrangling solution is naturally also somewhat convoluted.

# Data Science Exam 1 - preprocessing.Rmd
This is where the main data wrangling occurs. This markdown's main purpose is to create the files you will find in the Cleaned Data folder - you will find that they are already there. Thus, if you download the repo, you should be able to skip running markdown number 1 and go straight to number 2.
Markdown 1 does also create a number of files in the Temp folder (which you will find is currently empty, because many of the files are too large for github). These files include subsets of the data in different formats, and how many tables that count how many instances of a particular type of incident can be found in the data, or a subset thereof. Some of these files were used to generate some of the tables in the report. If you wish to reproduce them, you can run this markdown file, but beware that it runs slowly.

# Data Science Exam 2 - parameter recovery and analysis.Rmd
This is where the models found in the Stan Code folder come into play. This markdown takes, in total, well over two hours to run on my machine, so be wary of running it all in one go.
Parameter recovery for all models is undertaken, and subsequently the models are fit to the data found in the Cleaned Data folder. The results (draws dataframes and summary tables) are saved as CSV's and put in the Out folder, and are generally speaking far too large to put on GitHub, so to reproduce those, you will have to run this markdown.
At all times, before sampling in stan begins, seed is set to 1337. If everything goes well, this should ensure that all figures and results produced at the end are exactly identical to those I got on my own.

# Data Science Exam 3 - plotting.Rmd
Quite simply the markdown that, using the results produced by markdown nr. 2 in the Out folder, produces all of the figures found in the report. Doesn't take very long to run, but requires (unfortunately) that markdown nr. 2 is run first, since some of the files in Out are too large for GitHub.
The plots produced by this markdown are already in the Plots folder, and should be identical to those in the report.
