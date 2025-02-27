# 4_Calculator.R: performs calculations and visualization routine given a file
# Used with 1_Master.R | This is a fix of the current existing script.

# PLEASE READ: Despite the fact that this script is a fix of the current
# existing script, many variables are removed/renamed for better readability.
# Please don't try to copy and paste this script into original script.

library(MASS)

# Some positions of interest
thorax_x_mean <- mean(ab_x)
thorax_y_mean <- mean(ab_y)
frame_len <- length(ab_x) # this is how many frames are in the dataset

#' This function takes in 2 vectors of x and y coordinates in a timed series
#' and return the center mode of the points.
#'
#' @param x A time series of x coordinates
#' @param y A time series of y coordinates
#'
#' @return A vector of x and y coordinates of the center mode
center_point <- function(x, y) {
  # Estimate the density of the points using kernel density estimation
  # NOTE: when n is too small kde gets weird, N = 200 glitched.
  dens <- kde2d(na.omit(x), na.omit(y), n = 300)

  # Find the index of the point with the highest density
  max_idx <- which(dens$z == max(dens$z), arr.ind = TRUE)

  # Extract the x and y coordinates of the center point
  center_x <- dens$x[max_idx[1]]
  center_y <- dens$y[max_idx[2]]

  # Return the center point as a vector
  return(c(center_x, center_y))
}

anchor <- center_point(wax_x, wax_y)
anchor_x <- anchor[1]
anchor_y <- anchor[2]

# Find the angle between the abdomen and the center line:
# Note: This part would've been much easier computationally, but since this is
# not really a time consuming part I'm just going to use it as it is.

a <- dist.func(ab_x, ab_y, anchor_x, ab_y)
b <- dist.func(anchor_x, anchor_y, anchor_x, ab_y)
c <- dist.func(ab_x, ab_y, anchor_x, anchor_y)

angles <- acos((b^2 + c^2 - a^2) / (2 * b * c)) * 180 / pi # angle calculation

# Define center line (wax) as zero; make angles positive or negative deviation
# from that line:
for (i in 1:frame_len) {
  if (is.na(ab_x[i])) {next}
  if (ab_x[i] <= anchor_x) {
    angles[i] <- -angles[i]
  }
}

frames <- 1:frame_len
frames_per_shot <- 12 # Changeable
average_angle_per_shot <- rep(0, ceiling(frame_len / frames_per_shot))

for (i in seq(0, frame_len, frames_per_shot)) {
  average_angle_per_shot[i / frames_per_shot] <-
  mean(angles[i:i + frames_per_shot - 1])
}

shots <- seq(0, frame_len, frames_per_shot)

# Calculate the wax-abdomen-knee angle (wax_ab_knee_angle)
left_wax_ab_knee_angle <-
  angle_between_points(ab_x, ab_y, wax_x, wax_y, left_knee_x, left_knee_y)
right_wax_ab_knee_angle <-
  angle_between_points(ab_x, ab_y, wax_x, wax_y, right_knee_x, right_knee_y)

# Calculate the abdomen-knee-leg angle (ab_knee_leg_angle)
left_ab_leg_foot_angle <-
  angle_between_points(left_knee_x, left_knee_y, left_foot_x, left_foot_y,
                       ab_x, ab_y)
right_ab_leg_foot_angle <-
  angle_between_points(right_knee_x, right_knee_y, right_foot_x, right_foot_y,
                       ab_x, ab_y)

# Calculate the distance between centerline (wax-abdomen) and leg
left_leg_center_dist <- perpendicular_distance(wax_x, wax_y, ab_x, ab_y,
                                                left_foot_x, left_foot_y)
right_leg_center_dist <- perpendicular_distance(wax_x, wax_y, ab_x, ab_y,
                                                 right_foot_x, right_foot_y)

foot_distance <- dist.func(left_foot_x, left_foot_y, right_foot_x, right_foot_y)

# Normalize the distance between centerline and foot by the length
# of the hind leg
left_hind_leg_length <- mean(dist.func(left_knee_x, left_knee_y,
                                      left_foot_x, left_foot_y), na.rm = TRUE)
right_hind_leg_length <- mean(dist.func(right_knee_x, right_knee_y,
                                      right_foot_x, right_foot_y), na.rm = TRUE)

if (abs(left_hind_leg_length - right_hind_leg_length) > 10) {
  print(paste0("WARNING: At ", file_name,
  " left and right hind leg length are not equal (>10 px)",
  abs(left_hind_leg_length - right_hind_leg_length), " px"))
}

average_hind_leg_length <- mean(c(left_hind_leg_length, right_hind_leg_length), na.rm = TRUE)

left_leg_center_dist_normalized <- left_leg_center_dist / average_hind_leg_length
right_leg_center_dist_normalized <- right_leg_center_dist / average_hind_leg_length

## Convert sound from DLC coordinates into dB
ss_x_db <- scale.sound(ss_x, minimum_sound, maximum_sound)
frame.db <- rep(0, frame_len)

# end the script early because it is flawed.
return()
