.init.Cube <- function (.Object, ...) {
    .Object <- callNextMethod(.Object, ...)
    ## Fill in these reshaped values if loading an API response
    if (!length(.Object@dims)) .Object@dims <- cubeDims(.Object)
    if (!length(.Object@arrays)) {
        .Object@arrays <- lapply(.Object$result$measures, cToA,
            dims=.Object@dims)
    }
    return(.Object)
}
setMethod("initialize", "CrunchCube", .init.Cube)

cToA <- function (x, dims) {
    ## Just make an array from the cube "measure's" data. Nothing else
    
    d <- unlist(x$data)
    ## Identify missing values
    nas <- names(d) %in% "?"
    d[nas & d == -8] <- NaN
    d[nas & d != -8] <- NA
    # d <- round(d) ## TODO digits should be an argument
    ## and rounding should also depend on whether you're looking at count or not
    
    dimsizes <- dim(dims)
    ndims <- length(dims)
    if (ndims > 1) {
        ## Cube arrays come in row-col-etc. order, not column-major.
        ## Keep the labels right here, then aperm the array back to order
        dimsizes[1:2] <- dimsizes[c(2,1)]
    }
    out <- array(d, dim=dimsizes)
    if (ndims > 1) {
        ap <- seq_len(ndims)
        ap[1:2] <- 2:1
        out <- aperm(out, ap)
    }
    return(out)
}

cubeToArray <- function (x, measure=1) {
    out <- x@arrays[[measure]]
    dimnames(out) <- dimnames(x@dims)
    out <- pruneCubeArray(out, x)
    return(out)
}

pruneCubeArray <- function (x, cube) {
    keep.these <- evalUseNA(x, cube@dims, cube@useNA)
    return(subsetCubeArray(x, keep.these))
    return(x)
}

subsetCubeArray <- function (array, bools, drop=FALSE) {
    ## Given a named list of logicals corresponding to the dims, extract
    do.call("[", c(list(x=array, drop=drop), bools))
}

evalUseNA <- function (data, dims, useNA) {
    ## Return dimnames-shaped list of logical vectors indicating which 
    ## values should be kept, according to the @useNA parameter
    
    ## Figure out which dims are non-zero
    margin.counts <- lapply(seq_along(dim(data)),
        function (i) margin.table(data, i))
    keep.these <- mapply(keepWithNA,
        dimension=dims, 
        marginal=margin.counts, 
        MoreArgs=list(useNA=useNA),
        SIMPLIFY=FALSE,
        USE.NAMES=FALSE)
    names(keep.these) <- names(dims)
    return(keep.these)
}

keepWithNA <- function (dimension, marginal, useNA) {
    ## Returns logicals of which rows/cols/etc. should be kept
    
    ## Always drop __any__ and __none__, regardless of other missingness
    out <- !dimension$any.or.none
    
    if (useNA != "always") {
        ## Means drop missing always, or only keep if there are any
        valid.cats <- !dimension$missing
        if (useNA == "ifany") {
            valid.cats <- valid.cats | vapply(marginal, length, integer(1)) > 0
        }
        ## But still drop __any__ or __none__
        out <- valid.cats & out
    }

    return(out) 
}

cubeMarginTable <- function (x, margin=NULL, measure=1) {
    ## Given a CrunchCube, get the right margin table for percentaging
    data <- x@arrays[[measure]]
    dimnames(data) <- dimnames(x@dims)
    aon <- anyOrNone(x@dims)
    missings <- is.na(x@dims)
    
    if (!is.null(margin) && max(margin) > length(dim(data))) {
        ## Validate the input and give a useful error message.
        ## base::margin.table says:
        ## "Error in if (d2 == 0L) { : missing value where TRUE/FALSE needed"
        ## which is terrible.
        halt("Margin ", max(margin), " exceeds Cube's number of dimensions (",
            length(dim(data)), ")")
    }
    
    ## If multiple response, sum __any__ + __none__ (and missing, if included)
    ## (if ca, is there that on the other slice?)
    ## Else, sum all
    args <- lapply(seq_along(aon), function (i) {
        a <- aon[[i]]
        has.any.or.none <- any(a)
        if (!has.any.or.none) {
            ## If there isn't "any" or "none", keep all to sum over
            a <- rep(TRUE, length(a))
        } else if (i %in% margin) {
            ## If this does have any/none AND this is a margin we're sweeping,
            ## keep everything *except* any/none because we want to match
            ## the dimensions in "data"
            a <- !a
        }
        if (x@useNA == "no") {
            ## Exclude missings if we're supposed to
            a <- a & !missings[[i]]
        } else if (has.any.or.none) {
            ## Re-include missings for multiple response vars
            a <- a | missings[[i]]
        }
        return(a)
    })
    names(args) <- names(aon)
    data <- subsetCubeArray(data, args)
    return(margin.table(data, margin))
}

##' Work with CrunchCubes
##'
##' Crunch.io supports more complex data types than base R does, such as
##' multiple response and array types. If you want to compute margin or 
##' proportion tables on an aggregation of these variable types, special methods
##' are required. These functions provide an interface like
##' \code{\link[base]{margin.table}} and \code{\link[base]{prop.table}} for 
##' the CrunchCube object, handling those special data types.
##' 
##' @param x a CrunchCube
##' @param margin index, or vector of indices to generate margin for. See
##' \code{\link[base]{prop.table}}
##' @param digits see \code{\link[base]{round}}
##' @return The appropriate margin.table or prop.table. 
##' @name cube-computing
##' @aliases cube-computing margin.table prop.table
##' @seealso \code{\link[base]{margin.table}} \code{\link[base]{prop.table}}
NULL

##' @rdname cube-computing
##' @export
setMethod("margin.table", "CrunchCube", function (x, margin=NULL) {
    cubeMarginTable(x, margin)
})

##' @export
as.array.CrunchCube <- function (x, ...) cubeToArray(x, ...)

##' @rdname cube-computing
##' @export
setMethod("prop.table", "CrunchCube", function (x, margin=NULL) {
    out <- as.array(x)
    marg <- margin.table(x, margin)
    if (length(margin)) {
        out <- sweep(out, margin, marg, "/", check.margin=FALSE)
    } else {
        ## Don't just do sum(out) like the default does.
        ## cubeMarginTable handles missingness, any/none, etc.
        out <- out/marg
    }
    return(out)
})

##' @rdname cube-computing
##' @export
setMethod("round", "CrunchCube", function (x, digits=0) {
    round(as.array(x), digits)
})