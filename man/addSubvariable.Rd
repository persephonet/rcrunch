% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add-subvariable.R
\name{addSubvariable}
\alias{addSubvariable}
\alias{addSubvariables}
\title{Add subvariable to an array}
\usage{
addSubvariable(variable, subvariable)

addSubvariables(variable, subvariable)
}
\arguments{
\item{variable}{the array variable to modify}

\item{subvariable}{the subvariable to add, or a list of those to add, or a
dataset subset}
}
\value{
\code{variable} with the indicated subvariables added.
}
\description{
Add subvariable to an array
}
\examples{
\dontrun{
ds$allpets <- addSubvariable(ds$allpets, ds$allpets_4)
ds$petloc <- addSubvariables(ds$petloc, ds[c("petloc_school", "petloc_daycare")])
}
}
