#' Crunch xtabs: Crosstab and otherwise aggregate variables in a Crunch Dataset
#'
#' Create a contingency table or other aggregation from cross-classifying
#' variables in a CrunchDataset.
#'
#' @param formula an object of class 'formula' object with the
#' cross-classifying variables separated by '+' on the right side of the
#' "~". If aggregating by functions other than counts, include the aggregation
#' expression on the left-hand side.
#' Compare to \code{\link[stats]{xtabs}}.
#' @param data an object of class \code{CrunchDataset}
#' @param weight a CrunchVariable that has been designated as a potential
#' weight variable for \code{data}, or \code{NULL} for unweighted results.
#' Default is the currently applied weight, \code{\link{weight}(data)}.
#' @param useNA whether to include missing values in tabular results. See
#' \code{\link[base]{table}}.
#' @return an object of class \code{CrunchCube}
#' @importFrom stats as.formula terms
#' @export
crtabs <- function (formula, data, weight=crunch::weight(data),
                     useNA=c("no", "ifany", "always")) {
    ## Validate inputs
    if (missing(formula)) {
        halt("Must provide a formula")
    }
    if (missing(data) || !is.dataset(data)) {
        halt(dQuote("data"), " must be a Dataset")
    }

    query <- formulaToQuery(formula, data)
    query$dimensions <- unlist(query$dimensions, recursive=FALSE)
    names(query$dimensions) <- NULL

    ## Handle "weight"
    force(weight)
    if (is.variable(weight)) {
        weight <- self(weight)
        ## Should confirm that weight is in weight_variables. Server 400s
        ## if it isn't.
    } else {
        weight <- NULL
    }
    query["weight"] <- list(weight)

    ## Get filter
    f <- zcl(activeFilter(data))

    ## GET it.
    resp <- crGET(cubeURL(data),
        query=list(query=toJSON(query), filter=toJSON(f)))
    return(CrunchCube(resp, useNA=match.arg(useNA)))
}
