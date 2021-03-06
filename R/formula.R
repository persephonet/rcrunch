formulaToQuery <- function (formula, data) {
    formula <- try(as.formula(formula), silent=TRUE)
    if (is.error(formula)) {
        halt(dQuote("formula"), " is not a valid formula")
    }

    ## Parse the formula
    f <- terms(formula, allowDotAsName=TRUE) ## To catch "."
    f.vars <- attr(f, "variables")
    all.f.vars <- all.vars(f.vars)

    ## More input validation
    if ("." %in% all.f.vars) {
        halt("crtabs does not support ", dQuote("."), " in formula")
    }
    if (!length(all.f.vars)) {
        halt("Must supply one or more variables")
    }

    ## Find variables either in 'data' or in the calling environment
    ## Evaluate the formula's terms in order to catch derived expressions
    v.call <- do.call(substitute,
        list(expr=f.vars, env=registerCubeFunctions(all.f.vars)))
    where <- environment(formula) #parent.frame()
    vars <- eval(v.call, as.environment(data), environment(formula))

    ## Validate that vars are non-null
    nullvars <- vapply(vars, is.null, logical(1))
    if (any(nullvars)) {
        ## Get the NULL expressions.
        ## Note the off-by-one problem:
        ## If f.vars == language list(CA$mr_1, CA$NOTAVAR),
        ## as.character(f.vars) == [1] "list"       "CA$mr_1"    "CA$NOTAVAR"
        varexprs <- as.character(f.vars)[-1]
        halt("Invalid cube dimension", ifelse(sum(nullvars) > 1, "s: ", ": "),
            serialPaste(varexprs[nullvars]), " cannot be NULL")
    }

    ## Construct the "measures", either from the formula or default "count"
    resp <- attr(f, "response")
    if (resp) {
        measures <- lapply(vars[resp], zcl)
        vars <- vars[-resp]
    } else {
        measures <- list(count=zfunc("cube_count"))
    }

    ## Make "dimensions".
    dimensions <- lapply(vars, varToDim)

    ## Final validations
    badmeasures <- vapply(measures, Negate(isCubeAggregation), logical(1))
    if (any(badmeasures)) {
        halt("Left side of formula must be a valid aggregation")
    }
    baddimensions <- vapply(unlist(dimensions, recursive=FALSE),
        isCubeAggregation, logical(1))
    if (any(baddimensions)) {
        halt("Right side of formula cannot contain aggregation functions")
    }

    ## One last munge
    names(measures) <- vapply(measures, function (m) {
        sub("^cube_", "", m[["function"]])
    }, character(1))

    return(list(dimensions=dimensions, measures=measures))
}

registerCubeFunctions <- function (varnames=c()) {
    ## Return a list of "cube functions" to substitute()
    ## in. A better approach, which would avoid potential name collisions, would
    ## probably be to have vars be an environment inside of another environment
    ## that has the cube functions. This version just checks for name collisions
    ## and errors if there is one.

    numfunc <- function (func, ...) {
        force(func)
        moreArgs <- list(...)
        return(function (x) {
            if (is.Categorical(x)) {
                ## "Cast" it on the fly
                x <- list(zfunc("cast", x, "numeric"))
            }
            do.call("zfunc", c(func, x, moreArgs))
            # zfunc(func, x)
        })
    }

    funcs <- list(
        mean=numfunc("cube_mean"),
        min=numfunc("cube_min"),
        max=numfunc("cube_max"),
        sd=numfunc("cube_stddev"),
        sum=numfunc("cube_sum"),
        median=numfunc("cube_quantile", list(value=I(.5))),
        as_array=function (x) {
            ## Kinda hacky way to do a query of an MR as CA
            if (!is.MR(x)) {
                halt("Cannot analyze a variable of type ", dQuote(type(x)),
                    " 'as_array'")
            }
            zfunc("as_array", x)
        }
    )

    overlap <- intersect(varnames, names(funcs))
    if (length(overlap)) {
        halt("Cannot evaluate a cube with reserved name",
            ifelse(length(overlap) > 1, "s", ""), ": ",
            serialPaste(dQuote(overlap)))
    }
    return(funcs)
}

isCubeAggregation <- function (x) {
    "function" %in% names(x) && grepl("^cube_", x[["function"]])
}

varToDim <- function (x) {
    ## Given variable, construct the appropriate ZCL to get a cube with them
    ## as dimensions
    v <- zcl(x)
    if (is.MR(x)) {
        ## Multiple response gets "selected_array" and "each"
        return(list(zfunc("selected_array", v),
            list(each=self(x))))
    } else if (is.CA(x)) {
        ## Categorical array gets the var reference and "each"
        ## Put "each" first so that the rows, not columns, are subvars
        return(list(list(each=self(x)),
            v))
    } else if (is.list(x) && "function" %in% names(x) && x[["function"]] == "as_array") {
        ## Pseudo-ZCL from registerCubeFunctions, used to treat an MR like a CA
        ## x is thus list(`function`="as_array", args=list(list(variable=self)))
        ## Return instead list(list(each=self), list(variable=self))
        return(list(list(each=x$args[[1]]$variable), x$args[[1]]))
    } else {
        ## Just the var ref, but nest in a list so we can unlist to flatten
        return(list(v))
    }
}

formulaRHS <- function (f) {
    if (!is.character(f)) f <- deparse(f)
    sub("^ +", "", tail(unlist(strsplit(f, "~")), 1))
}
