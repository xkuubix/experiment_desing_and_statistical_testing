library("car")
library("ggplot2")

# HHD BR Force normalized to body weight (HHD measures);
# two depentend groups; dominant and non dominan extremity

mean1 <- .99
mean2 <- .91
std1 <- .16
std2 <- .26
sample_sizes <- seq(10, 500, by = 10)
p_values <- numeric(length(sample_sizes))


check_conditions <- function(x1, x2){
#   print("Test for normality")
  shapiro_x1 <- shapiro.test(x1)
  shapiro_x2 <- shapiro.test(x2)
#   print(shapiro_x1)
#   print(shapiro_x2)
#   print("Test for homogeneity of variances")
  group <- factor(c(rep(1, length(x1)), rep(2, length(x2))))
  combined_data <- c(x1, x2)
  levene <- leveneTest(combined_data ~ group)
#   print(levene)
  if (shapiro_x1$p.value > .05 && shapiro_x2$p.value > .05 && levene$`Pr(>F)`[1] > .05) {
    return("parametric")
  } else {
    return("nonparametric")
  }
}

experiment <- function(n, mean1, mean2, std1, std2){
  x1 <- rnorm(n, mean = mean1, sd = std1)
  x1 <- x1 + runif(n, min = -1e-2, max = 1e-2)
  x2 <- rnorm(n, mean = mean2, sd = std2)
  x2 <- x2 + runif(n, min = -1e-2, max = 1e-2)
  test_type <- check_conditions(x1, x2)
#   print(test_type)
  if (test_type == "parametric") {
    test_restults <- t.test(x1, x2, paired = TRUE)
  } else {
    test_restults <- wilcox.test(x1, x2, paired = TRUE)
  }
  return(test_restults)
}

all_p_values <- list()
for (i in seq_along(sample_sizes)) {
  n <- sample_sizes[i]
  p_values <- numeric(10)
  repetitions <- 0

  for (j in 1:10) {
    test_results <- experiment(n, mean1, mean2, std1, std2)
    p_values[j] <- test_results$p.value
    if (all(p_values < .05)) {
      repetitions <- repetitions + 1
    }
  }
  all_p_values[[i]] <- p_values  # Store p-values
  if (repetitions == 10) {
    print(paste("Minimal sample size for p<.05 in 10 repetitions:", n))
    # break
  }
}

set.seed(123)
x1 <- rnorm(n, mean = mean1, sd = std1)
x1 <- x1 + runif(n, min = -3e-2, max = 3e-2)
x2 <- rnorm(n, mean = mean2, sd = std2)
x2 <- x2 + runif(n, min = -3e-2, max = 3e-2)

data <- data.frame(
  value = c(x1, x2),
  group = rep(c("dominant", "nondominant"), each = n)
)

density_x1 <- density(x1)
density_x2 <- density(x2)
y_at_mean_x1 <- density_x1$y[which.min(abs(density_x1$x - mean(x1)))]
y_at_mean_x2 <- density_x2$y[which.min(abs(density_x2$x - mean(x2)))]

p1 <- ggplot(data, aes(x = value, fill = group)) +
  geom_density(alpha = 0.5) +
  labs(title = "Density plot of HHD BR [kg/kg] among youth athletes",
       x = "force [kg/kg]",
       y = "density",
       fill = "extremity") +
  theme_minimal() +
  geom_segment(aes(x = mean(x1), xend = mean(x1), y = 0,
                   yend = y_at_mean_x1),
               color = "black", linetype = "dotted", size = 1) +
  geom_segment(aes(x = mean(x2), xend = mean(x2), y = 0,
                   yend = y_at_mean_x2),
               color = "black", linetype = "dotted", size = 1) +
  geom_text(aes(x = mean(x1), y = y_at_mean_x1 + 0.02,
                label = paste("Mean = ", round(mean(x1), 2))),
            color = "#d86c6c", size = 4, hjust = -0.1) +
  geom_text(aes(x = mean(x2), y = y_at_mean_x2 + 0.02,
                label = paste("Mean = ", round(mean(x2), 2))),
            color = "#6767b1", size = 4, hjust = 1) +
  theme(
    legend.position = c(0.9, 0.9),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    plot.title = element_text(hjust = 0.5)
  )

repetitions_data <- data.frame(
  sample_size = sample_sizes,
  successful_repetitions = sapply(all_p_values, function(p_vals) sum(p_vals < .05))
)

xxlim <- c(10, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500)
p2 <- ggplot(repetitions_data, aes(x = sample_size, y = successful_repetitions)) +
  geom_line() +
  geom_point() +
  labs(title = "No. of successful repetitions (p < .05) vs No. of sample size",
       x = "sample size", y = "successful repetitions") +
  theme_minimal() +
  scale_y_continuous(breaks = 0:10) +
  scale_x_continuous(breaks = xxlim) +
  theme(
    # panel.grid.major.x = element_blank(),
    plot.title = element_text(hjust = 0.5),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.major.y = element_line(linewidth = 0.5, color = "gray")
  )

ggsave("density_plot.png", plot = p1, width = 8, height = 6, dpi = 300)
ggsave("pval_vs_nsampl.png", plot = p2, width = 8, height = 6, dpi = 300)

results <- experiment(280, mean1, mean2, std1, std2)
print(results)