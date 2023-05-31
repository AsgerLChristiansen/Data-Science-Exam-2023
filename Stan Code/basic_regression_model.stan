// Model 3, used for Iowa and Missouri
data {
  
  // number of observations per state (that is, n_months or n_years)
  int N;
  // n_killed, n_injured or n_incidents.
  vector<lower=0>[N] y;
  // A matrix with two columns: One for months, one for whether or not
  // a SYG law was in effect that month.
  matrix [N, 2] X;
  
}
parameters {
  real<lower=0> alpha;
  real beta;
  real gamma;
  real<lower=0.1, upper = 2> sigma;
}
transformed parameters {
  vector[N] mu;
  // Regression model specification
  mu = alpha + X[,1] * beta + X[,2] * gamma;
}
model {
  // establish priors
  alpha ~ normal(0.2, 0.1);
  beta ~ normal(0.1, 0.1);
  gamma ~ normal(0.1,0.1);
  sigma ~ gamma(1, 1);
  // compute y based on model and uncertainty
  y ~ normal(mu, sigma);
}


generated quantities {
   real alpha_prior;
   real beta_prior;
   real sigma_prior;
   alpha_prior = normal_rng(0.2, 0.1);
   beta_prior = normal_rng(0.1, 0.1);
   sigma_prior = normal_rng(0.1, 0.1);
}
