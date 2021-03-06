% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/loadReg2.R
\name{loadReg2}
\alias{loadReg2}
\title{Create a fitted loadReg2 object.}
\usage{
loadReg2(load.reg, pred.format = c("flux", "conc"), store = c("data",
  "fitting.function"), ...)
}
\arguments{
\item{load.reg}{An unevaluated call to \code{\link[rloadest]{loadReg}}. This 
call will be parsed and evaluated within \code{loadReg2} to create a fully 
functional load model for use within \pkg{loadflex}.}

\item{pred.format}{character is the model for flux or concentration can 
be "flux" or "Conc"}

\item{store}{One or more character strings specifying which information to 
write within the model. Options are 'data': the original fitting data; 
'fitting.function': a fitting function that can produce a new loadComp 
object from new data}

\item{...}{Other arguments passed to this model.}
}
\value{
A fitted loadReg2 model.
}
\description{
Generates a new model of class loadReg2 (\code{\link{loadReg2-class}}). loadReg2s are wrappers for loadReg 
objects produced by the USGS \pkg{rloadest} package. \code{loadReg2}s can implement the 
\code{\link{loadModelInterface}} more reliably than is possible for a \code{loadReg} object.
}
\seealso{
Other load.model.inits: \code{\link{loadComp}},
  \code{\link{loadInterp}}, \code{\link{loadLm}},
  \code{\link{loadModel}}
}

