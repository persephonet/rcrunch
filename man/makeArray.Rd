% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make-array.R
\name{makeArray}
\alias{makeArray}
\alias{makeMR}
\alias{deriveArray}
\title{Make a Categorical Array or Multiple Response variable}
\usage{
makeArray(subvariables, name, ...)

makeMR(subvariables, name, selections, ...)

deriveArray(subvariables, name, ...)
}
\arguments{
\item{subvariables}{a list of Variable objects to bind together, or a
Dataset object containing only the Variables to bind (as in from subsetting
a Dataset)}

\item{name}{character, the name that the new Categorical Array variable
should have. Required.}

\item{...}{Optional additional attributes to set on the new variable.}

\item{selections}{character, for \code{makeMR}, the names of the
categories to mark as the dichotomous selections. Required for
\code{makeMR}; ignored in \code{makeArray}.}
}
\value{
A VariableDefinition that when added to a Dataset will create the
categorical-array or multiple-response variable. \code{deriveArray} will
make a derived array expression, while \code{makeArray} and \code{makeMR}
return an expression that "binds" variables together, removing them from
independent existence.
}
\description{
Make a Categorical Array or Multiple Response variable
}
