obtain_emiss_pois <- function(object, level = "group", burn_in = NULL){
  if (level != "group" & level != "subject"){
    stop("The specification at the input variable -level- should be set to either group or subject")
  }
  input   <- object$input
  dep_labels <- input$dep_labels
  n_subj  <- input$n_subj
  if (is.null(burn_in)){
    burn_in <- input$burn_in
  }
  J       <- input$J
  if (burn_in >= (J-1)){
    stop(paste("The specified burn in period should be at least 2 points smaller
               compared to the number of iterations J, J =", J))
  }
  m       <- input$m
  n_dep   <- input$n_dep
  if (level == "group"){
      est <- rep(list(matrix(, nrow = m, ncol = 2, dimnames = list(paste("State", 1:m), c("Mean", "Var")))), n_dep)
      names(est) <- dep_labels
      for(j in 1:n_dep){
        est[[j]][] <-  matrix(round(c(apply(object$emiss_mu_bar[[j]][((burn_in + 1): J),], 2, median), apply(object$emiss_varmu_bar[[j]][((burn_in + 1): J),], 2, median)),3), ncol = 2, nrow = m)
      }
    est_emiss <- est
  }
  if (level == "subject"){
    est_emiss <- vector("list", n_dep)
    names(est_emiss) <- dep_labels
    if(is.mHMM(object)){
      for(j in 1:n_dep){
        est <- matrix(,ncol = q_emiss[j], nrow = m)
        colnames(est) <- paste("Category", 1:q_emiss[j])
        rownames(est) <- paste("State", 1:m)
        est_emiss[[j]] <- rep(list(est), n_subj)
        names(est_emiss[[j]]) <- paste("Subject", 1:n_subj)
      }
      start <- c(0, q_emiss * m)
      for(i in 1:n_subj){
        for(j in 1:n_dep){
          est_emiss[[j]][[i]][] <- matrix(round(apply(object$PD_subj[[i]][burn_in:J, (sum(start[1:j]) + 1) : sum(start[1:(j+1)])], 2, median), 3),
                                          byrow = TRUE, ncol = q_emiss[j], nrow = m)
        }
      }
    } else if (is.mHMM_cont(object)){
      est_emiss <- rep(list(rep(list(matrix(, nrow = m, ncol = 2, dimnames = list(paste("State", 1:m), c("Mean", "Variance")))), n_subj)), n_dep)
      names(est_emiss) <- dep_labels
      for(j in 1:n_dep){
        names(est_emiss[[j]]) <- paste("Subject", 1:n_subj)
        for(i in 1:n_subj){
          est_emiss[[j]][[i]][] <- matrix(round(c(apply(object$PD_subj[[i]][((burn_in + 1): J),((j-1) * m + 1) : ((j-1) * m + m)], 2, median), apply(object$PD_subj[[i]][((burn_in + 1): J),(n_dep * m + (j-1) * m + 1) : (n_dep * m + (j-1) * m + m)], 2, median)),3), ncol = 2, nrow = m)
        }
      }
    }
  }
  return(est_emiss)
  }


#' @keywords internal
# simple functions used in mHMM
dif_matrix <- function(rows, cols){
  return(matrix(, ncol = cols, nrow = rows))
}

