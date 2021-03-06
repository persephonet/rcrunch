#' Main Crunch API handling function
#' @param http.verb character in GET, PUT, POST, PATCH, DELETE
#' @param url character URL to do the verb on
#' @param ... additional arguments passed to \code{GET}, \code{PUT},
#' \code{POST}, \code{PATCH}, or \code{DELETE}
#' @param config list of config parameters. See httr documentation.
#' @param status.handlers named list of specific HTTP statuses and a response
#' function to call in the case where that status is returned. Passed to the
#' \code{\link{handleAPIresponse}} function.
#' @keywords internal
crunchAPI <- function (http.verb, url, config=list(), status.handlers=list(), ...) {
    url ## force lazy eval of url before inserting in try() below
    if (isTRUE(getOption("crunch.debug"))) {
        ## TODO: work this into httpcache.log
        payload <- list(...)$body
        if (!is.null(payload)) try(cat("\n", payload, "\n"), silent=TRUE)
    }
    FUN <- get(http.verb, envir=asNamespace("httpcache"))
    x <- FUN(url, ..., config=config)
    out <- handleAPIresponse(x, special.statuses=status.handlers)
    return(out)
}

#' HTTP methods for communicating with the Crunch API
#'
#' @param ... see \code{\link{crunchAPI}} for details. \code{url} is the first
#' named argument and is required; \code{body} is also required for PUT,
#' PATCH, and POST.
#' @return Depends on the response status of the HTTP request and any custom
#' handlers.
#' @importFrom httpcache GET PUT PATCH POST DELETE
#' @name http-methods
#' @export
crGET <- function (...) crunchAPI("GET", ...)
#' @rdname http-methods
#' @export
crPUT <- function (...) crunchAPI("PUT", ...)
#' @rdname http-methods
#' @export
crPATCH <- function (...) crunchAPI("PATCH", ...)
#' @rdname http-methods
#' @export
crPOST <- function (...) crunchAPI("POST", ...)
#' @rdname http-methods
#' @export
crDELETE <- function (...) crunchAPI("DELETE", ...)

#' Do the right thing with the HTTP response
#' @param response an httr response object
#' @param special.statuses an optional named list of functions by status code.
#' @return The full HTTP response object, just the content, or any other
#' status-specific action
#' @importFrom httr content http_status
#' @keywords internal
handleAPIresponse <- function (response, special.statuses=list()) {
    code <- response$status_code
    handler <- special.statuses[[as.character(code)]]
    if (is.function(handler)) {
        invisible(handler(response))
    } else if (tolower(http_status(response)$category) == "success") {
        if (code == 202) {
            ## 202 Continue: a few cases:
            ## 1) Legacy: POST /batches/ returns Batch entity in Location, no response content
            ## 2) Progress body with Location
            ## 3) Progress body without Location
            ## So, if there's a shoji:value response, it's a Progress, so poll it.
            ## Otherwise, return the location.
            loc <- locationHeader(response)
            if (length(response$content) > 0) {
                ## Progress URL comes in a shoji:value
                progress_url <- handleShoji(content(response))
                ## Quick validation
                if (is.character(progress_url) && length(progress_url) == 1) {
                    tryCatch(pollProgress(progress_url),
                        error=function (e) {
                            ## Handle the error here so we can message the
                            ## Location header, if present
                            if (!is.null(loc)) {
                                message("Result URL: ", loc)
                            }
                            stop(e)
                        })
                }
            }
            ## Return the location header, if it exists
            invisible(loc)
        } else if (code == 201) {
            ## 201 Location: return the Location header
            return(locationHeader(response))
        } else if (code == 204 || length(response$content) == 0) {
            ## If No Content, invisibly return NULL
            invisible(NULL)
        } else {
            ## Parse the content
            return(handleShoji(content(response)))
        }
    } else {
        if (code == 401) {
            halt("You are not authenticated. Please `login()` and try again.")
        } else if (code == 410) {
            halt("The API resource at ",
                response$url,
                " has moved permanently. Please upgrade crunch to the ",
                "latest version.")
        }
        msg <- http_status(response)$message
        msg2 <- try(content(response)$message, silent=TRUE)
        if (!is.error(msg2)) {
            msg <- paste(msg, msg2, sep=": ")
        }
        if (code == 409 && grepl("current editor", msg)) {
            halt("You are not the current editor of this dataset. `unlock()` it and try again.")
        }
        halt(msg)
    }
}

locationHeader <- function (response) {
    loc <- response$headers$location
    return(loc)
}

#' @importFrom httr config add_headers
crunchConfig <- function () {
    return(c(config(verbose=isTRUE(getOption("crunch.debug")), postredir=3),
        add_headers(`user-agent`=crunchUserAgent())))
}

#' @importFrom utils packageVersion
#' @importFrom curl curl_version
crunchUserAgent <- function (x) {
    ## Cf. httr:::default_ua
    versions <- c(
        libcurl = curl_version()$version,
        curl = as.character(packageVersion("curl")),
        httr = as.character(packageVersion("httr")),
        rcrunch = as.character(packageVersion("crunch"))
    )
    ua <- paste0(names(versions), "/", versions, collapse = " ")
    if (!missing(x)) ua <- paste(ua, x)
    return(ua)
}

handleShoji <- function (x) {
    if (is.shoji.like(x)) {
        class(x) <- c("shoji", x$element)
    }
    if ("shoji:view" %in% class(x)) {
        x <- x$value %||% x$views ## Special-casing the dataset export :(
    }
    return(x)
}

getAPIRoot <- function (x=getOption("crunch.api")) {
    ShojiObject(crGET(x))
}

sessionURL <- function (key, collection="catalogs") {
    if (is.authenticated()) {
        return(shojiURL(session_store$root, collection, key))
    } else {
        halt("You must authenticate before making this request")
    }
}

rootURL <- function (x, obj=session_store$root) {
    ## DEPRECATE ME
    if (!is.authenticated()) {
        halt("You must authenticate before making this request")
    }
    if (is.shojiObject(obj)) {
        return(obj@urls[[paste0(x, "_url")]])
    } else {
        return(NULL)
    }
}
