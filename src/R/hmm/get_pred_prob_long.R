# Get predicted transition probabilities as a function of a covariate
get_pred_prob_long <- function(x, xx, method, type = NULL, cov_name, cov_val = NULL) {
    
    # Checks
    if(is.null(type)){stop("Argument 'type' has to be equal to 'gamma' or 'emiss'")}
    
    # Get input values
    m       <- x[["input"]][["m"]]
    n_dep   <- x[["input"]][["n_dep"]]
    q_emiss <- x[["input"]][["q_emiss"]]
    J       <- x[["input"]][["J"]]
    burn_in <- x[["input"]][["burn_in"]]
    
    if (type == "gamma"){
        
        # Additional inputs
        n_cov   <- ncol(xx[[1]]) - 1
        n_subj  <- nrow(xx[[1]])
        
        # Burn in
        gamma_int_bar <- x[["gamma_int_bar"]][(burn_in+1):J,]
        gamma_cov_bar <- x[["gamma_cov_bar"]][(burn_in+1):J,]
        
        # Gamma
        out <- vector("list", length = m+1)
        names(out) <- c(paste0("from_S",1:m), "covariate_values")
        
        # Initialize covariate values
        if(is.numeric(cov_name)) {
            cov_idx <- cov_name
            cov_vec <- xx[[1]][,cov_idx+1]
        } else if (is.character(cov_name)) {
            cov_idx <- which(colnames(xx[[1]]) == cov_name)-1
            cov_vec <- xx[[1]][,cov_idx+1]
        }
        
        # Initialize a vector of values of the covariate (user input, dichotomous, or continuous)
        if (is.null(cov_val)) {
            if (identical(unique(cov_vec), c(0,1))){
                cov_val <- c(0,1)
                cov_mat <- matrix(0, nrow = 2, ncol = n_cov*(m-1))
                cov_mat[,(1+(cov_idx-1)*(m-1)):(cov_idx*(m-1))] <- cov_val
                row_names <- paste0(cov_name,"=",round(cov_val,1))
            } else {
                cov_vec <- scale(cov_vec)
                cov_mean <- mean(cov_vec)
                cov_sd <- sd(cov_vec)
                cov_val <- c(cov_mean-cov_sd, cov_mean, cov_mean+cov_sd)
                cov_mat <- matrix(0, nrow = 3, ncol = n_cov*(m-1))
                cov_mat[,(1+(cov_idx-1)*(m-1)):(cov_idx*(m-1))] <- cov_val
                row_names <- paste0(cov_name," = ",c("Mean - 1SD","Mean","Mean + 1SD"))
            }
        } else {
            cov_mat <- matrix(0, nrow = length(cov_val), ncol = n_cov*(m-1))
            cov_mat[,(1+(cov_idx-1)*(m-1)):(cov_idx*(m-1))] <- cov_val
            row_names <- paste0(cov_name,"=",round(cov_val,1))
        }
        
        for(i in seq(m)){
            
            if (is.matrix(gamma_int_bar)) {
                int1 <- matrix(gamma_int_bar[,(1+(m-1)*(i-1)):(i*(m-1))], ncol = m-1)
                cov1 <- matrix(gamma_cov_bar[,(1+(m-1)*n_cov*(i-1)):(i*(m-1)*n_cov)], ncol = (m-1)*n_cov)
            } else {
                int1 <- matrix(gamma_int_bar[(1+(m-1)*(i-1)):(i*(m-1))], ncol = m-1)
                cov1 <- matrix(gamma_cov_bar[(1+(m-1)*n_cov*(i-1)):(i*(m-1)*n_cov)], ncol = (m-1)*n_cov)
            }
            
            # For each hidden state and each level of the covariate, calculate the predicted transition probabilities
            # (they are maximum a posteriori)
            out[[i]] <- do.call(rbind,lapply(1:nrow(cov_mat),function(e) {
                
                val <- cov_mat[e,]
                
                if(is.matrix(int1)){
                    prob1 <- matrix(nrow = nrow(int1), ncol = ncol(int1) + 1)
                    # prob1cci <- matrix(nrow = nrow(int1), ncol = 2*(ncol(int1) + 1))
                    for(r in 1:nrow(int1)){
                        exp_int1    <- matrix(exp(c(0, int1[r,] + colSums(matrix((cov1[r,] * val), nrow = n_cov, byrow = TRUE)))), nrow  = 1)
                        
                        prob1[r,]   <- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
                    }
                    # prob1 <- round(apply(prob1,2,median),4)
                    # prob1cci <- round(apply(prob1,2,quantile,percentiles),4)
                    # return(prob1)
                    # print(cbind(prob1, i, max(val)))
                    return(cbind(prob1, i, max(val)))
                    
                } else {
                    exp_int1    <- matrix(exp(c(0, int1 + colSums(matrix((cov1[r,] * val), nrow = n_cov, byrow = TRUE)))), nrow  = 1)
                    prob1 	    <- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
                }
            }))
            
            # Add informative names to the output
            # print(out[[i]])
            # colnames(out[[i]]) <- c(paste0("S",i,"toS",1:m),"state","cov_val")
            colnames(out[[i]]) <- c(paste0("toS",1:m),"state","cov_val")
            # rownames(out[[i]]) <- row_names
            
        }
        
        # Return values
        # out[[m+1]] <- round(cov_val, 4)
        # out <- list(do.call(rbind, out), round(cov_val, 4))
        return(do.call(rbind, out))
        
    } else if (type == "emiss") {
        
        # Additional inputs
        n_cov   <- ncol(xx[[2]]) - 1
        n_subj  <- nrow(xx[[2]])
        
        # Emiss
        out <- vector("list", length = n_dep+1)
        names(out)[n_dep+1] <- "covariate_values"
        if(is.null(names(x[["emiss_int_bar"]]))){
            names(out)[1:n_dep] <- paste0("observation ",1:n_dep)
        } else {
            names(out)[1:n_dep] <- names(x[["emiss_int_bar"]])
        }
        
        print(out)
        for (q in 1:(n_dep)) {
            out[[q]] <- vector("list", m)
            names(out[[q]]) <- paste0("S",1:m)
        }
        
        for (q in seq(n_dep)){
            
            # Burn in
            emiss_int_bar <- x[["emiss_int_bar"]][[q]][(burn_in+1):J,]
            emiss_cov_bar <- x[["emiss_cov_bar"]][[q]][(burn_in+1):J,]
            
            # Initialize covariate values
            if(is.numeric(cov_name)) {
                cov_idx <- cov_name + 1
                cov_vec <- xx[[q+1]][,cov_idx]
            } else if (is.character(cov_name)) {
                # cov_idx <- which(colnames(xx[[q+1]]) == cov_name)-1
                cov_idx <- which(colnames(xx[[q+1]]) == cov_name)
                cov_vec <- xx[[q+1]][,cov_idx]
            }
            
            # Initialize a vector of values of the covariate (user input, dichotomous, or continuous)
            if (is.null(cov_val)) {
                if (identical(unique(cov_vec), c(0,1))){
                    cov_val <- c(0,1)
                    cov_mat <- matrix(0, nrow = 2, ncol = n_cov*(q_emiss[q]-1))
                    cov_mat[,(1+(cov_idx-2)*(q_emiss[q]-1)):((cov_idx-1)*(q_emiss[q]-1))] <- cov_val
                    row_names <- paste0(cov_name,"=",round(cov_val,1))
                } else {
                    cov_vec <- scale(cov_vec)
                    cov_mean <- mean(cov_vec)
                    cov_sd <- sd(cov_vec)
                    cov_val <- c(cov_mean-cov_sd, cov_mean, cov_mean+cov_sd)
                    cov_mat <- matrix(0, nrow = 3, ncol = n_cov*(q_emiss[q]-1))
                    cov_mat[,(1+(cov_idx-2)*(q_emiss[q]-1)):((cov_idx-1)*(q_emiss[q]-1))] <- cov_val
                    row_names <- paste0(cov_name," = ",c("Mean - 1SD","Mean","Mean + 1SD"))
                }
            } else {
                cov_mat <- matrix(0, nrow = length(cov_val), ncol = n_cov*(q_emiss[q]-1))
                cov_mat[,(1+(cov_idx-2)*(q_emiss[q]-1)):((cov_idx-1)*(q_emiss[q]-1))] <- cov_val
                row_names <- paste0(cov_name,"=",round(cov_val,1))
            }
            
            for(i in seq(m)){
                
                if (is.matrix(emiss_int_bar)) {
                    int1 <- matrix(emiss_int_bar[,(1+(q_emiss[q]-1)*(i-1)):(i*(q_emiss[q]-1))], ncol = q_emiss[q]-1)
                    cov1 <- matrix(emiss_cov_bar[,(1+(q_emiss[q]-1)*n_cov*(i-1)):(i*(q_emiss[q]-1)*n_cov)], ncol = (q_emiss[q]-1)*n_cov)
                } else {
                    int1 <- matrix(emiss_int_bar[(1+(q_emiss[q]-1)*(i-1)):(i*(q_emiss[q]-1))], ncol = q_emiss[q]-1)
                    cov1 <- matrix(emiss_cov_bar[(1+(q_emiss[q]-1)*n_cov*(i-1)):(i*(q_emiss[q]-1)*n_cov)], ncol = (q_emiss[q]-1)*n_cov)
                }
                
                # For each hidden state and each level of the covariate, calculate the predicted transition probabilities
                # (they are maximum a posteriori)
                out[[q]][[i]] <- do.call(lapply(1:nrow(cov_mat), function(e) {
                    
                    val <- cov_mat[e,]
                    
                    if(is.matrix(int1)){
                        prob1 <- matrix(nrow = nrow(int1), ncol = ncol(int1) + 1)
                        # prob1_cci <- matrix(nrow = nrow(int1), ncol = 2*(ncol(int1) + 1))
                        for(r in 1:nrow(int1)){
                            exp_int1    <- matrix(exp(c(0, int1[r,] + colSums(matrix((cov1[r,] * val), nrow = n_cov, byrow = TRUE)))), nrow  = 1)
                            
                            prob1[r,]   <- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
                        }
                        # return(prob1)
                        return(cbind(prob1, q, i, max(val)))
                        # prob1 <- round(apply(prob1,2,median),4)
                        # prob1_cci <- round(apply(prob1,2,quantile,percentiles),4)
                    } else {
                        exp_int1    <- matrix(exp(c(0, int1 + colSums(matrix((cov1[r,] * val), nrow = n_cov, byrow = TRUE)))), nrow  = 1)
                        prob1 	    <- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
                    }
                }))
                
                # Add informative names to the output
                colnames(out[[q]][[i]]) <- c(paste0("emiss",1:q_emiss[q]),"n_dep","state","cov_val")
                # rownames(out[[q]][[i]]) <- row_names
                
            }
            
        }
        
        # Return values
        out[[n_dep+1]] <- round(cov_val, 4) 
        return(out)
        # return(do.call(rbind, out))
        
    }
    
}