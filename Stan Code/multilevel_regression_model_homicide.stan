
data {
  int states_1;
  int states_2;
  // number of observations per state (that is, n_months or n_years)
  int N;
  // n_killed, n_injured or n_incidents by state.
  matrix<lower=0>[N, states_1] y_1;
  matrix<lower=0>[N, states_2] y_2;
  // 48 months.
  vector<lower=0>[N] X;
}
parameters {
  // Country level parameters for alpha (intercept) and beta (slope)
  real<lower=0, upper = 15>mu_alpha;
  real mu_beta;
  // Group difference parameters for intercept and slope
  real<lower=-mu_alpha, upper=mu_alpha> delta_alpha;
  real delta_beta;

  // State-level beta 0 and beta-1.
  vector<lower=0, upper = 15>[states_1] alpha_1; 
  vector[states_1] beta_1;
  vector<lower=0, upper = 15>[states_2] alpha_2;
  vector[states_2] beta_2;
  vector<lower=0.1, upper=2>[states_1] sigma_1; // Each state has a sigma parameter
  vector<lower=0.1, upper=2>[states_2] sigma_2; // Each state has a sigma parameter

  real<lower=0.1, upper=2> SD_beta_1;
  real<lower=0.1, upper=2> SD_beta_2;
  real<lower=0.1, upper=2> SD_alpha_1;
  real<lower=0.1, upper=2> SD_alpha_2; 
}
transformed parameters {
    // Group mean and SD parameters for intercept and slope. There are two groups.
  real<lower=0, upper = 15> mu_alpha_1;
  real<lower=0, upper = 15> mu_alpha_2;
  real mu_beta_1;
  real mu_beta_2;
  matrix[N, states_1]  mu_1;
  matrix[N, states_2]  mu_2;
  for (i in 1:states_1){
  mu_1[,i] = alpha_1[i] + X * beta_1[i];
  }
  
  for (i in 1:states_2){
    mu_2[,i] = alpha_2[i] + X * beta_2[i];
  }
  // Group level parameters. 1 means SYG, 2 means no SYG.
  mu_alpha_1 = mu_alpha + delta_alpha/2;
  mu_alpha_2 = mu_alpha - delta_alpha/2;
  mu_beta_1 = mu_beta + delta_beta/2;
  mu_beta_2 = mu_beta - delta_beta/2;
}

model {
  // country level priors
  mu_alpha ~ normal(2., 0.5);
  mu_beta ~ normal(1., 1);
  // Difference priors
  delta_alpha ~ normal(0.5, 2);
  delta_beta ~ normal(1., 2);
  // Standard deviations at group level. Both groups get same prior.
  SD_alpha_1 ~ gamma(1, 1);
  SD_beta_1 ~ gamma(1., 1);
  SD_alpha_2 ~ gamma(1., 1);
  SD_beta_2 ~ gamma(1., 1);
  // State level parameters
  sigma_1 ~ gamma(1, 1); // state-level variance. // Shouldn't be normal!
  sigma_2 ~ gamma(1,1);
  alpha_1 ~ normal(mu_alpha_1, SD_alpha_1);
  beta_1 ~ normal(mu_beta_1, SD_beta_1);
  alpha_2 ~ normal(mu_alpha_2, SD_alpha_2);
  beta_2 ~ normal(mu_beta_2, SD_beta_2);
  
  // compute likelihood for each of the groups
  for (i in 1:states_1){
    y_1[,i] ~ normal(mu_1[,i], sigma_1[i]);
}
  for (i in 1:states_2){
    y_2[,i] ~ normal(mu_2[,i], sigma_2[i]);
}

}

generated quantities {
   real mu_alpha_prior;
   real mu_beta_prior;
   real delta_alpha_prior;
   real delta_beta_prior;
   mu_alpha_prior = normal_rng(2., 0.5);
   mu_beta_prior = normal_rng(1., 1);
   delta_alpha_prior = normal_rng(0.5, 2);
   delta_beta_prior = normal_rng(1, 2);
}
