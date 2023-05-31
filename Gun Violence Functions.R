# Functions for analysis of gun violence


pacman::p_load(pacman, tidyverse, stringr)

#### PREPROCESSING FUNCTIONS

# Helper function to turn a row in a dataframe into a vector instead of
# a list.
row_to_vector = function(dataframe_row){
  
  new_vector = unlist(c(dataframe_row))
  new_vector = new_vector[!is.na(new_vector)]
  return(new_vector)
}


# The raw data has all labels for each incident in one string.
# This function takes the incidents_characteristics column and turns it into a list
# of label vectors, including each incident's ID.
### WARNING: Takes a long time on the full dataset!
split_strings_and_list = function(dataframe){
  i = 0
  splitstrings = list()
  for (string in dataframe$incident_characteristics){
    i = i + 1
    ID = dataframe$incident_id[i]
    string = string %>% str_replace_all("\\|", "BLA")
    string_vector = unlist(str_split(string, "BLA"))
    splitstrings[[i]] =c(ID, string_vector)
  }
  return(splitstrings)
}


# This function takes the list of labels produced above, and 
# counts how many instances of each unique label is in that list.
# Very useful for figuring out how filtering by certain labels affect the data.
# Must be used after split_strings_and_list().
unique_labels_counter = function(splitstrings){
  unique_characteristics = c()
  for (string_vector in splitstrings){
    string_vector = string_vector[-1]
    unique_characteristics = unique(c(unique_characteristics, string_vector))
    
  }
  dataframe = data.frame(unique_characteristics)
  i = 0
  for (label in dataframe$unique_characteristics){
    # Keep track of label index
    i = i + 1
    # Initialize counter
    count = 0
    # Prepare to split all strings.
    for (string_vector in splitstrings){
      # If label in split vector
      if (label %in% string_vector){
        count = count + 1
        
      }
    }
    dataframe$count[i] = count
  }
  return(dataframe)
}



# This function takes the same list created above, and turns it into a dataframe,
# with labels in individual columns. Each list entry is supplemented with NA's
# to ensure equal length.
# NOTICE: There is no logic to which labels go in which columns 
#- this is mainly done because dataframes can be easier to work with than lists in some cases.
# In others, the list format is preferrable.
labels_by_ID = function(split_strings_list){
for (i in 1:length(split_strings_list)){
  len = length(unlist(split_strings_list[i]))
  if (len < 38){
    diff = 38 - len
    for (j in 1:diff){
      split_strings_list[i] = list(c(unlist(split_strings_list[i]), NA))
    }
  }
}
  labels_by_ID = as.data.frame(t(as.matrix(data.frame(split_strings_list, row.names = NULL))))
  
  return(labels_by_ID)
}

### The following function filters a labelled dataframe, such as the one produced
# by labels_by_ID(), according to exclusion and inclusion labels.
# It outputs a vector of incident ID's, which can then be used to filter the
# raw data.
filter_incidents_by_labels = function(label_dataframe, labels_included = NULL, labels_excluded = NULL){
  ID_filter_vector = c()
  for (i in 1:nrow(label_dataframe)){
    incident = row_to_vector(label_dataframe[i,])
    ID = incident[1]
    if (length(intersect(incident, labels_included )) > 0){ # If contains labels we want to include
      if ((length(intersect(incident, labels_excluded)) > 0) == FALSE){ # If does not contain labels we don't want.
        
        ID_filter_vector = c(ID_filter_vector, as.numeric(ID)) # Save the ID
      }}
  }
  
  filtered_incidents = label_dataframe %>% filter(V1 %in% ID_filter_vector)
  return(filtered_incidents)
}

#### DATA FORMATTING FUNCTIONS

# Once data has been filtered for the labels of interest, new columns
# must be added to it. This function adds date and year and month.
add_date_columns = function(incident_dataframe){
  incident_dataframe$year = NA
  
  incident_dataframe$month = NA
  
  incident_dataframe$day = NA
  
  for (i in 1:nrow(incident_dataframe)){
    date_vector = unlist(str_split(incident_dataframe$date[i], "-"))
    
    incident_dataframe$year[i] = date_vector[1]
    incident_dataframe$month[i] = date_vector[2]
    incident_dataframe$day[i] = date_vector[3]
    
    
  }
  return(incident_dataframe)
}


# This function adds a population column based on the state population
# dataset.
add_population_column = function(state_incident_dataframe, state_pop){
  state_incident_dataframe$population = NA
  state_pops_by_year = c(state_pop$y2013
                         ,state_pop$y2014
                         , state_pop$y2015
                         , state_pop$y2016
                         , state_pop$y2017
                         , state_pop$y2018)
  
  year_vec = c(2013,2014,2015,2016,2017,2018)
  for (i in 1:nrow(state_incident_dataframe)){
    for (j in 1:length(year_vec)){
      
      if (as.numeric(state_incident_dataframe$year[i]) == year_vec[j]){
        state_incident_dataframe$population[i] = state_pops_by_year[j]
      }
      
    }
  }
  return(state_incident_dataframe)
}


# Finally, this function calculates per capita (that is, per million people) killed,
# injured, and total incidents in a year.
per_capita_per_year = function(incident_dataframe){
  df_subset = incident_dataframe %>% select("state", "n_injured", "n_killed", "year", "population")
  State = incident_dataframe$state[1]
  years = unique(df_subset$year)
  df = data.frame(state = character(), year = numeric(), incidents = numeric(),
                  n_injured = numeric(), 
                  n_killed = numeric(), incidents_per_capita = numeric(), injured_per_capita = numeric(), killed_per_capita = numeric())
  
  for (Year in years){
    year_df = df_subset %>% filter(year == Year)
    population = year_df$population[1] # The available data only has one pop estimate per year.
    pop_mill = population/1000000
    new_df = data.frame(state = State, year = Year, n_incidents = nrow(year_df), n_injured = sum(year_df$n_injured),
                        n_killed = sum(year_df$n_killed))

    new_df$incidents_per_capita = new_df$n_incidents / pop_mill

    new_df$injured_per_capita = new_df$n_injured / pop_mill
    new_df$killed_per_capita = new_df$n_killed / pop_mill

    df = rbind(df, new_df)
  }
  
  return(df)
}


# This function does the same, only by month.
per_capita_per_month = function(incident_dataframe){
  df_subset = incident_dataframe %>% select("state","n_injured", "n_killed", "year","month", "population")
  df_subset$month = as.numeric(df_subset$month)
  State = incident_dataframe$state[1]
  years = unique(df_subset$year)
  months = c(1,2,3,4,5,6,7,8,9,10,11,12)
  df = data.frame(state = character(), year = numeric(), month = numeric(), n_incidents = numeric(),
                  n_injured = numeric(), 
                  n_killed = numeric(), incidents_per_capita = numeric(), injured_per_capita = numeric(), killed_per_capita = numeric())
  
  for (Year in years){
    year_df = df_subset %>% filter(year == Year)
    population = year_df$population[1] # The available data only has one pop estimate per year anyway.
    pop_mill = population/1000000 # Number of millions of people
    for (Month in months){
      month_df = year_df %>% filter(month == Month)
      new_df = data.frame(state = State, year = Year, month = Month, n_incidents = nrow(month_df),
                          n_injured = sum(month_df$n_injured), n_killed = sum(month_df$n_killed))
      new_df$incidents_per_capita = new_df$n_incidents / pop_mill
      new_df$injured_per_capita = new_df$n_injured / pop_mill
      new_df$killed_per_capita = new_df$n_killed / pop_mill
      df = rbind(df, new_df)
    }}
  
  return(df)
}


# Finally, this function takes all the data, formats it by state, then rbinds
# it together. Doing it this way is less likely to crash R than doing it on the
# entire dataframe at once.
# Prints are included to tell the user which state is being processed at the time.
format_data_by_year = function(data, state_list){
  for (State in state_list){
    print(State)
    state_pop = pop_data %>% filter(Name == State)
    sub_data = data %>% filter(state == State)
    
    sub_data = sub_data %>% select("incident_id", "date", "state","n_killed", "n_injured", "incident_characteristics")
    sub_data = sub_data %>% add_date_columns()
    sub_data = sub_data %>% add_population_column(state_pop)
    sub_data = sub_data %>% per_capita_per_year()
    
    if (exists("merged_per_capita") == FALSE){
      merged_per_capita = sub_data
    }
    else{
      merged_per_capita = rbind(merged_per_capita, sub_data)
    }
  }
  
  return(merged_per_capita)
}

# Same function, but by month instead of by year.
format_data_by_month = function(data, state_list){
  for (State in state_list){
    print(State)
    state_pop = pop_data %>% filter(Name == State)
    sub_data = data %>% filter(state == State)
    
    sub_data = sub_data %>% select("incident_id", "date", "state","n_killed", "n_injured", "incident_characteristics")
    sub_data = sub_data %>% add_date_columns()
    sub_data = sub_data %>% add_population_column(state_pop)
    sub_data = sub_data %>% per_capita_per_month()
    
    if (exists("merged_per_capita") == FALSE){
      merged_per_capita = sub_data
    }
    else{
      merged_per_capita = rbind(merged_per_capita, sub_data)
    }
  }
  return(merged_per_capita)
}

# This function removes those years with least data, and filters out D.C.
remove_bad_data = function(data){
  
  data = data %>% filter(year != 2013) %>% filter(year != 2018) %>% filter(state != "District of Columbia")
  return(data)
}






### SIMULATION AND ANALYSIS FUNCTIONS


# This function simulates data for the hierarchical regression model, given
# a set of parameters, and two sets of states, and a set of months.
sim_data = function(mu_alpha, mu_beta, delta_alpha, delta_beta, SD_alpha, SD_beta, SD_state, n_states_1, n_states_2, n_months){
  mu_alpha1 = mu_alpha + delta_alpha/2
  mu_beta1 = mu_beta + delta_beta/2
  mu_alpha2 = mu_alpha - delta_alpha/2
  mu_beta2 = mu_beta - delta_beta/2
  for (i in 1:n_states_1){
    state_alpha = rnorm(n = 1,mean = mu_alpha1, sd = SD_alpha)
    state_beta = rnorm(n = 1,mean = mu_beta1, sd = SD_beta)
    y_vec = c()
    month_vec = c(seq(1:n_months))
    state_vec = rep(i, n_months)
    group_vec = rep(1, n_months)
    state_sigma = rgamma(n = 1, SD_state[1], SD_state[2])
    for (month in 1:n_months){
      mu = state_alpha + state_beta*month
      
      y = rnorm(n = 1, mean = mu, sd = state_sigma)
      
      y_vec = c(y_vec, y)
    }
    
    state_sims = data.frame(state = state_vec, group = group_vec, month = month_vec, y = y_vec)
    
    if(exists("all_states_sims") == TRUE){
      all_states_sims = rbind(all_states_sims, state_sims)
      
    }
    else{
      all_states_sims = state_sims
      
    }
  }
  
  for (i in 1:n_states_2){
    state_alpha = rnorm(n = 1,mean = mu_alpha2, sd = SD_alpha)
    state_beta = rnorm(n = 1,mean = mu_beta2, sd = SD_beta)
    y_vec = c()
    month_vec = c(seq(1:n_months))
    state_vec = rep(i, n_months)
    group_vec = rep(2, n_months)
    state_sigma = rgamma(n = 1, SD_state[1], SD_state[2])
    for (month in 1:n_months){
      mu = state_alpha + state_beta*month
      
      y = rnorm(n = 1, mean = mu, sd = state_sigma)
      
      y_vec = c(y_vec, y)
    }
    
    state_sims = data.frame(state = state_vec, group = group_vec, month = month_vec, y = y_vec)
    
    
    
    
    if(exists("all_states_sims") == TRUE){
      all_states_sims = rbind(all_states_sims, state_sims)
      
    }
    else{
      all_states_sims = state_sims
      
    }
    
    
    
  }
  
  for (i in 1:nrow(all_states_sims)){
    if (all_states_sims$y[i] < 0){
      all_states_sims$y[i] = 0
    }
    
  }
  
  return(all_states_sims)
}


### This function fits the hierarchical regression model to a simulated or real dataset.
# Note that for simulated datasets, n_states_1, n_states_2 and n_months must be the same as when creating the data.
fit_to_data = function(sim_data,n_states_1, n_states_2,n_months, mod){
  group_1 = sim_data %>% filter(group == 1)
  group_2 = sim_data %>% filter(group == 2)
  
  y_1 = select(group_1[1:n_months,], "y")
  
  for (i in 2:n_states_1){
    y_1 = cbind(y_1, select(group_1[(n_months*(i-1)+1):(n_months*i),], "y"))
    
  }
  y_1 = as.matrix(y_1)
  
  y_2 = select(group_2[1:n_months,], "y")
  
  
  for (i in 2:n_states_2){
    
    y_2 = cbind(y_2, select(group_2[(n_months*(i-1)+1):(n_months*i),], "y"))
    
  }
  y_2 = as.matrix(y_2)
  
  
  
  
  X = group_1$month[1:n_months]
  
  data <- list(states_1 = n_states_1, states_2 = n_states_2, N = n_months, y_1 = y_1, y_2 = y_2, X = X)
  
  
  samples <- mod$sample(
    data = data,
    seed = 1000,
    chains = 1,
    parallel_chains = 1,
    threads_per_chain = 1,
    iter_warmup = 1000,
    iter_sampling = 2000,
    refresh = 0,
    max_treedepth = 20,
    adapt_delta = 0.99,)
  return(samples)
}


# Helper function to extract a parameter estimate from a stan model summary.
get_est = function(summary, var_name){
  est = unlist(c(summary[summary$variable==var_name,"mean"]))
  return(est)
}

# And a function that brings it all together. Given a vector of possible values
# for each parameter, this function samples parameters, simulates data,
# fits a model, extracts the estimated parameters, and stores true and estimated
# parameter values in a dataframe, which is the output.
# Takes very long time to run.
parameter_recovery = function(mu_alpha_vec, mu_beta_vec, delta_alpha_vec, delta_beta_vec, SD_alpha_vec, SD_beta_vec, SD_state, n_states_1_vec, n_states_2_vec, n_months = 48, n_sims = 100, mod){
  
  for (j in 1:length(n_states_1_vec)){
    
    n_states_1 = n_states_1_vec[j]
    n_states_2 = n_states_2_vec[j]
    mu_alpha_true = c()
    mu_beta_true = c()
    delta_alpha_true = c()
    delta_beta_true = c()
    SD_alpha_true = c()
    SD_beta_true = c()
    
    mu_alpha_est = c()
    mu_beta_est = c()
    delta_alpha_est = c()
    delta_beta_est = c()
    SD_alpha_1_est = c()
    SD_alpha_2_est = c()
    SD_beta_1_est = c()
    SD_beta_2_est = c()
    
    for (i in 1:n_sims){
      
      mu_alpha = sample(mu_alpha_vec, 1)
      mu_beta = sample(mu_beta_vec, 1)
      delta_alpha = sample(delta_alpha_vec, 1)
      delta_beta = sample(delta_beta_vec, 1)
      SD_alpha = sample(SD_alpha_vec, 1)
      SD_beta = sample(SD_beta_vec, 1)
      
      
      sims = sim_data(mu_alpha, mu_beta, delta_alpha, delta_beta, SD_alpha, SD_beta, SD_state, n_states_1, n_states_2, n_months)
      samples = fit_to_data(sims,n_states_1, n_states_2,n_months, mod)
      
      summary = samples$summary()
      
      mu_alpha_true = c(mu_alpha_true, mu_alpha)
      mu_beta_true = c(mu_beta_true, mu_beta)
      delta_alpha_true = c(delta_alpha_true, delta_alpha)
      delta_beta_true = c(delta_beta_true, delta_beta)
      SD_alpha_true = c(SD_alpha_true, SD_alpha)
      SD_beta_true = c(SD_beta_true, SD_beta)
      mu_alpha_est = c(mu_alpha_est, get_est(summary,"mu_alpha"))
      mu_beta_est = c(mu_beta_est, get_est(summary,"mu_beta"))
      delta_alpha_est = c(delta_alpha_est, get_est(summary,"delta_alpha"))
      delta_beta_est = c(delta_beta_est, get_est(summary,"delta_beta"))
      SD_alpha_1_est = c(SD_alpha_1_est, get_est(summary,"SD_alpha_1"))
      SD_beta_1_est = c(SD_beta_1_est, get_est(summary,"SD_beta_1"))
      SD_alpha_2_est = c(SD_alpha_2_est, get_est(summary,"SD_alpha_2"))
      SD_beta_2_est = c(SD_beta_2_est, get_est(summary,"SD_beta_2"))
    }
    
    sim_results = data.frame("mu_alpha_true" = mu_alpha_true,
                             "mu_beta_true" = mu_beta_true,
                             "delta_alpha_true" = delta_alpha_true,
                             "delta_beta_true" = delta_beta_true,
                             "SD_alpha_true" = SD_alpha_true,
                             "SD_beta_true" = SD_beta_true,
                             "mu_alpha_est" = mu_alpha_est,
                             "mu_beta_est" = mu_beta_est,
                             "delta_alpha_est" = delta_alpha_est,
                             "delta_beta_est" = delta_beta_est,
                             "SD_alpha_1_est" = SD_alpha_1_est,
                             "SD_alpha_2_est" = SD_alpha_2_est,
                             "SD_beta_1_est" = SD_beta_1_est,
                             "SD_beta_2_est" = SD_beta_2_est)  
    sim_results$n_states_1 = n_states_1
    sim_results$n_states_2 = n_states_2
    
    if (exists("final_results")){
      final_results =rbind(final_results, sim_results)
    }
    else{
      final_results = sim_results
    }
    
  }
  return(final_results)
  
}

