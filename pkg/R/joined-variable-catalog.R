setMethod("[[", c("JoinedVariableCatalog", "character"), function (x, i, ...) {
    if (i %in% names(index(x))) {
        callNextMethod()
    } else {
        for (j in seq_along(x@joins)) {
            if (i %in% urls(x@joins[[j]])) {
                return(x@joins[[j]][[i]])
            }
        }
        halt("Variable not found")
    }
})

setMethod("active", "JoinedVariableCatalog", function (x) {
    x
})
