% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cube-result.R, R/tab-book.R
\docType{methods}
\name{cube-computing}
\alias{cube-computing}
\alias{margin.table}
\alias{prop.table}
\alias{bases}
\alias{margin.table,CrunchCube-method}
\alias{prop.table,CrunchCube-method}
\alias{round,CrunchCube-method}
\alias{bases,CrunchCube-method}
\alias{prop.table,MultitableResult-method}
\alias{prop.table,TabBookResult-method}
\alias{bases,TabBookResult-method}
\alias{bases,MultitableResult-method}
\title{Work with CrunchCubes, MultitableResults, and TabBookResults}
\usage{
\S4method{margin.table}{CrunchCube}(x, margin = NULL)

\S4method{prop.table}{CrunchCube}(x, margin = NULL)

\S4method{round}{CrunchCube}(x, digits = 0)

\S4method{bases}{CrunchCube}(x, margin = NULL)

\S4method{prop.table}{MultitableResult}(x, margin = NULL)

\S4method{prop.table}{TabBookResult}(x, margin = NULL)

\S4method{bases}{TabBookResult}(x, margin = NULL)

\S4method{bases}{MultitableResult}(x, margin = NULL)
}
\arguments{
\item{x}{a CrunchCube}

\item{margin}{index, or vector of indices to generate margin for. See
\code{\link[base]{prop.table}}. \code{bases} accepts an additional valid
value for \code{margin}, \code{0}, which yields the unweighted counts for the
query, without reducing dimension.}

\item{digits}{see \code{\link[base]{round}}}
}
\value{
The appropriate margin.table or prop.table. Calling prop.table on
a MultitableResult returns a list of prop.tables of the CrunchCubes it
contains. Likewise, prop.table on a TabBookResult returns a list of list of
prop.tables.
}
\description{
Crunch.io supports more complex data types than base R does, such as
multiple response and array types. If you want to compute margin or
proportion tables on an aggregation of these variable types, special methods
are required. These functions provide an interface like
\code{\link[base]{margin.table}} and \code{\link[base]{prop.table}} for
the CrunchCube object, handling those special data types.
}
\details{
\code{bases} is an additional method for CrunchCubes. When making weighted
requests, \code{bases} allows you to access the unweighted counts for every
cell in the resulting table (array). The \code{bases} function takes a
"margin" argument to work like \code{margin.table}, or with \code{margin=0}
gives all cell counts.
}
\seealso{
\code{\link[base]{margin.table}} \code{\link[base]{prop.table}}
}
