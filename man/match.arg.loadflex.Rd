% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/match.arg.loadflex.R
\name{match.arg.loadflex}
\alias{match.arg.loadflex}
\title{Require an argument to match the loadflex conventions for that argument name}
\usage{
match.arg.loadflex(arg, choices, several.ok = FALSE)
}
\arguments{
\item{arg}{An argument, passed as a symbol. May be a missing argument to the 
calling function.}

\item{choices}{Optional. A vector of choices, character or logical, that 
should be accepted by partial matching.}

\item{several.ok}{logical. If TRUE, a vector of several choices in \code{arg}
will be accepted and returned as such.}
}
\value{
The argument after matching to the allowed options for that argument 
  name. This may differ from the original value of \code{arg} if \code{arg} 
  is a truncated version of one of the character options for the argument 
  (identified using \code{pmatch}, as in \code{match.arg}.
}
\description{
This function is modeled on \code{match.arg}, but it is designed to 
facilitate consistency in how argument names are used within the 
\code{loadflex} package.
}
\details{
The key differences between this function and \code{match.arg} are that this 
function (1) decides what the available options are without reference to the 
defaults defined in the calling function, and (2) permits atomic but 
non-character choices.
}
\examples{
# match.arg.loadflex knows about some variables by their names alone
flux.or.conc="conc"; flux.or.conc <- loadflex:::match.arg.loadflex(flux.or.conc)
attach.units=TRUE; attach.units <- loadflex:::match.arg.loadflex(attach.units)

# you can also pass in custom choices. as always, partial matching is available
ci.distrib="log"; ci.distrib <- loadflex:::match.arg.loadflex(ci.distrib, c("lognormal","normal"))
}

