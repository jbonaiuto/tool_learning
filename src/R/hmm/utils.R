#---------------------------#
#           Plots           :
#---------------------------#

# Higher level plots:
plot_mHMM <- function(out, level = c("higher","lower"), q = 1, burnIn = NULL,
                           target = c("trans","emiss"), plotType = c("trace","density"),
                           scales = "fixed", alpha = 0.4) {
    
    # Extract parameters from output
    if (is.null(burnIn)) {
        burnIn <- out$input[["burn_in"]]
    }
    m       <- out$input[["m"]]
    n_dep   <- out$input[["n_dep"]]
    q_emiss <- out$input[["q_emiss"]]
    
    # Define an index with the variables we want to plot
    if (target == "trans") {
        varNames <- paste("S", rep(1:m, each = m), "toS", rep(1:m, m), sep = "")
    } else if (target == "emiss") {
        varNames <- paste("q", q, "_emiss", rep(1:q_emiss[q], m), "_S", rep(1:m, each = q_emiss[q]), sep = "")
    }
    
    # Exract the useful variables depending on the level:
    if (level == "lower") {
        # Extract subject level data from the list and shpe it as a wide data frame
        data <- do.call(rbind, lapply(seq_along(out$PD_subj), function(e) {
            as.data.frame(out$PD_subj[e]) %>%
                dplyr::select(varNames) %>%
                mutate(iter = row_number(), id = e)
        }))
        # Reshape subj_data into long format
        data <- data %>% gather(key = variable, value = prob, -iter, -id) %>%
            filter(iter >= burnIn)
    } else {
        elemName <- case_when("trans" %in% target ~ "gamma_prob_bar",
                              "emiss" %in% target ~ "emiss_prob_bar")
        
        if (target == "emiss") {
            data <- out[[elemName]][[q]] %>%
                as.data.frame()
            names(data) <- varNames
            data <- data %>%
                mutate(iter = row_number()) %>%
                gather(key = variable, value = prob, -iter) %>%
                filter(iter >= burnIn)
        } else {
            data <- out[[elemName]] %>%
                as.data.frame() %>%
                mutate(iter = row_number()) %>%
                gather(key = variable, value = prob, -iter) %>%
                filter(iter >= burnIn)
        }
    }

    # Put the facets on a nice ordering
    if (target == "emiss") {data$variable <- factor(data$variable, levels = varNames)}
    
    # Plot lower o higher level PD
    if (level == "lower") {
        # Lower level plots
        if (plotType == "trace") {
            ggplot(data, aes(x = iter, y = prob, group = id)) +
                geom_line(alpha = alpha) +
                facet_wrap(variable ~., nrow = m)
        } else if (plotType == "density") {
            ggplot(data, aes(x = prob, group = id)) +
                geom_density(alpha = alpha, linetype = "dotted") +
                facet_wrap(variable~., scales = scales, nrow = m)
        }
    } else {
        # Higher level plots
        if (plotType == "trace") {
            ggplot(data, aes(x = iter, y = prob)) +
                geom_line() +
                facet_wrap(variable ~., nrow = m)
        } else if (plotType == "density") {
            ggplot(data, aes(x = prob)) +
                geom_density(linetype = "dotted") +
                facet_wrap(variable~., scales = scales, nrow = m)
        }
    }

        
}