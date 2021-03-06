#### Data ####

#' Defines the units (or pieces of units) that are permissible in valid load
#' models
#' 
#' Contains a dictionary of valid units and their dimensions
#' 
#' @name valid.metadata.units
#' @docType data
#' @format A data.frame with character columns "unit" and "dimension"
#' @examples
#' data(valid.metadata.units); valid.metadata.units
NULL

#' Defines the units that are permissible to pass to load models
#' 
#' Contains a dictionary with which we will translate a range of possibilities
#' into a smaller, more uniform set of units
#' 
#' @name freeform.unit.translations
#' @docType data
#' @format A data.frame with character columns "new" and "old"
#' @keywords data units
#' @examples
#' data(freeform.unit.translations); freeform.unit.translations
NULL

#' Defines the units that are permissible in load models, along with the 
#' multiplers that will allow common conversions among units
#' 
#' @name unit.conversions
#' @docType data
#' @format A data.frame with character columns "numerator", "denominator", and
#'   numeric column "value", one conversion per row
#' @keywords data units
#' @examples
#' data(unit.conversions); unit.conversions
NULL

#' Generate units conversion & parsing data
#' 
#' Should only need to be run once on a change in the function contents.
#' Generates the units data to be saved in data/valid.metadata.units, 
#' data/freeform.unit.translations, data/unit.conversions, and (all three 
#' combined) R/sysdata.rda. These are then saved with the package.
#' 
#' @importFrom stats setNames
#' @keywords data units internal
generateUnitsData <- function() {
  # valid.metadata.units
  
  valid.metadata.units <- rbind(
    data.frame(
      dimension="volume",
      unit=c("m^3", "ft^3", "dL", "L")),
    data.frame(
      dimension="time",
      unit=c("s", "d")),
    data.frame(
      dimension="mass",
      unit=c("lb", "ton", "ng", "ug", "mg", "g", "kg", "Mg")),
    data.frame(
      dimension="count",
      unit=c("colonies", "million_colonies"))
  )
  save(valid.metadata.units, file="data/valid.metadata.units.RData")

  # freeform.unit.translations
  freeform.unit.translations <- rbind(
    # Volumes
    data.frame(new="m^3", old=c("cubic meter", "cubic meters", "m^3")),
    data.frame(new="ft^3", old=c("cubic foot", "cubic feet", "ft^3")),
    data.frame(new="dL", old=c("100mL", "dL")),
    data.frame(new="L", old=c("liter", "l", "L")),
    
    # Times
    data.frame(new="s", old=c("second", "sec", "s")),
    data.frame(new="d", old=c("day", "d")),
    
    # Masses and counts
    data.frame(new="lb", old=c("pounds", "lbs", "lb")),
    data.frame(new="ton", old=c("tons")),
    data.frame(new="ng", old=c("nanograms", "ng")),
    data.frame(new="ug", old=c("micrograms", "ug")),
    data.frame(new="mg", old=c("milligrams", "mg")),
    data.frame(new="g", old=c("grams", "g")),
    data.frame(new="kg", old=c("kilograms", "kg")),
    data.frame(new="Mg", old=c("metric tons", "Mg")),
    data.frame(new="colonies", old=c("col", "colonies")),
    data.frame(new="million_colonies", old=c("million colonies")),
    
    # Abbreviations
    data.frame(new="m^3 s^-1", old=c("cubic meter per second", "cms")),
    data.frame(new="ft^3 s^-1", old=c("cubic feet per second", "cubic foot per second", "cfs"))
  )
  save(freeform.unit.translations, file="data/freeform.unit.translations.RData")
  
  # unit.conversions
  unit.conversions <- setNames(rbind(
    # Volumes
    data.frame(num="L", rbind(
      data.frame(den="m^3", val=1000),
      data.frame(den="ft^3", val=28.317),
      data.frame(den="dL", val=0.1),
      data.frame(den="L", val=1))
    ),
    
    # Times
    data.frame(num="d", rbind(
      data.frame(den="s", val=1/(60*60*24)),
      data.frame(den="d", val=1))
    ),
    
    # Masses and counts
    data.frame(den="mg", rbind(
      data.frame(num="lb", val=2.204623e-6),
      data.frame(num="ton", val=1.102311e-9),
      data.frame(num="ng", val=1.0e6),
      data.frame(num="ug", val=1.0e3),
      data.frame(num="mg", val=1),
      data.frame(num="g", val=1.0e-3),
      data.frame(num="kg", val=1.0e-6),
      data.frame(num="Mg", val=1.0e-9))
    )[,c(2,1,3)],
    
    data.frame(num="million_colonies", rbind(
      data.frame(den="colonies", val=1.0e-6),
      data.frame(den="million_colonies", val=1)
    ))
  ), c("numerator", "denominator", "value"))
  # Append the reverse conversions
  numerator<-denominator<-value<-".transform.var"
  
  unit.conversions <- rbind(
    unit.conversions,
    transform(unit.conversions, 
              numerator=denominator,
              denominator=numerator,
              value=1/value))
  unit.conversions$numerator <- as.character(unit.conversions$numerator)
  unit.conversions$denominator <- as.character(unit.conversions$denominator)
  unit.conversions <- unique(unit.conversions)
  save(unit.conversions, file="data/unit.conversions.RData")
  
  # The two above save calls (all commented out) put the data into a 
  # user-accessible location (the data folder). But the following is the
  # important line for the functionality of flowconcToFluxConversion(), 
  # translateFreeformToUnitted(), and validMetadataUnits():
  save(valid.metadata.units, unit.conversions, freeform.unit.translations, file="R/sysdata.rda")
  
}


#### Functions ####

#' Check whether these units are acceptable (without translation) for inclusion in metadata
#' 
#' @importFrom unitted separate_units get_units unitbundle
#' @param unitstr A string representing units (just one bundle at a time, please)
#' @param unit.type string. accepts "ANY","flow.units","conc.units","load.units", or "load.rate.units"
#' @param type A string describing the type of units desired
#' @return logical. TRUE if valid for that unit type, FALSE otherwise
#' @keywords units
#' @export
#' @examples
#' validMetadataUnits("colonies d^-1") # TRUE
#' validMetadataUnits("nonsensical") # FALSE
#' validMetadataUnits("g", unit.type="load.units") # TRUE
#' validMetadataUnits("g", unit.type="flow.units") # FALSE
validMetadataUnits <- function(unitstr, unit.type=c("ANY","flow.units","conc.units","load.units","load.rate.units")) {
  unit.type <- match.arg(unit.type)

  # Parse the unit string into numerator and denominator strings
  unitpieces <- separate_units(unitbundle(unitstr))
  numerator <- get_units(unitbundle(unitpieces[which(unitpieces$Power > 0),]))
  denominator <- get_units(1/unitbundle(unitpieces[which(unitpieces$Power < 0),]))
  
  # A useful helper function: returns TRUE iif oneunit is present in valid.metadata.units
  # and has a dimension that's in dims
  unit <- "subset.var"
  hasDim <- function(oneunit, dims) {
    unit_row <- subset(valid.metadata.units, unit==oneunit)
    if(nrow(unit_row) != 1) {
      return(FALSE)
    } else if(!(unit_row$dimension %in% dims)) {
      return(FALSE)
    } else {
      return(TRUE)
    }
  }

  # The numerator (and denominator if it exists) should have specific dimensions
  # for each units type. Check.
  switch(
    unit.type,
    "ANY" = any(sapply(c("flow.units","conc.units","load.units","load.rate.units"), function(eachtype) {
        validMetadataUnits(unitstr, eachtype)
      })),
    flow.units = hasDim(numerator, "volume") & hasDim(denominator, "time"),
    conc.units = hasDim(numerator, c("mass","count")) & hasDim(denominator, "volume"),
    load.units = hasDim(numerator, c("mass","count")) & denominator=="",
    load.rate.units = hasDim(numerator, c("mass","count")) & hasDim(denominator, c("time"))
  )
}


#' Convert units from a greater variety of forms, including rloadest form, to 
#' unitted form
#' 
#' @importFrom unitted unitbundle get_units
#' @param freeform.units character string or list of character strings 
#'   describing one or more sets of units. "Freeform" is an exaggeration but 
#'   gets at the idea that these units can take a greater variety of forms than 
#'   those accepted by unitted and the units conversion functions in 
#'   \code{loadflex}.
#' @param attach.units logical. If TRUE, returned value is unitted; otherwise, 
#'   it's character.
#' @return a unitbundle or list of unitbundles containing equivalent but simpler
#'   and more uniform units
#' @examples
#' loadflex:::translateFreeformToUnitted("cfs") # "ft^3 s^-1"
#' loadflex:::translateFreeformToUnitted("kg/d") # "kg d^-1"
#' loadflex:::translateFreeformToUnitted("mg L^-1") # "mg L^-1"
translateFreeformToUnitted <- function(freeform.units, attach.units=FALSE) {
  # Quick escape if our work is already done.

  if(validMetadataUnits(freeform.units, "ANY")) {
    return(if(attach.units) unitbundle(freeform.units) else get_units(unitbundle(freeform.units)))
  }
  
  # format the string[s] in the vector (may be length 1) and convert it to a
  # list of elements split on "/"; each list element is one bundle of units
  units <- gsub(" per ", "/", freeform.units)
  unitslist <- strsplit(units, "/")
  # for each bundle of units, find each element in the dictionary and translate if needed
  #data(freeform.unit.translations)
  old <- "tidyunit.var"
  units <- lapply(unitslist, function(units) {
    units <- lapply(units, function(unit) {
      tidyunit <- gsub("^ +| +$", "", unit) # strip surrounding spaces
      tidyunit <- as.character(subset(freeform.unit.translations, old == tidyunit)$new) # find in data.frame
      if(length(tidyunit) == 0) {
        stop("unexpected unit '",unit,"'. See 'Valid units options' in ?metadata")
      }
      unitbundle(tidyunit)
    })
    if(length(units) == 1) return(units[[1]])
    else if(length(units) != 2) stop(paste0("unexpected units: '", paste(units, collapse="';'"),"'. See 'Valid units options' in ?metadata"))
    else return(units[[1]]/units[[2]])
  })
  
  if(!attach.units) {
    units <- lapply(units, get_units)
  }
  
  if(length(units) == 1) return(units[[1]]) else return(units)
}


#' Provide the conversion factor which, when multiplied by flow * conc, gives 
#' the flux in the desired units
#' 
#' By dividing rather than multiplying by this factor, the output of this 
#' function may also be used to convert from flux units to the units of the 
#' product of flow and concentration.
#' 
#' @importFrom unitted separate_units get_units unitbundle u
#' @export flowconcToFluxConversion
#' @param flow.units character. The units of flow.
#' @param conc.units character. The units of concentration.
#' @param load.rate.units character. The units of flux.
#' @param attach.units logical. If TRUE, the conversion factor is returned with
#'   units attached.
#' @return numeric, or unitted numeric if unitted=TRUE. The conversion factor.
#' @examples
#' flowconcToFluxConversion("L/d", "g/L", "g/d") # 1
#' flowconcToFluxConversion("cfs", "g/L", "kg/d") # 2446.589
#' library(unitted); u(10, "ft^3 s^-1") * u(2, "mg L^-1") * 
#' flowconcToFluxConversion("cfs", "mg/L", "kg/d", attach.units=TRUE) # u(48.9 ,"kg d^-1")
flowconcToFluxConversion <- function(flow.units, conc.units, load.rate.units, attach.units=FALSE) {
  ## Code inspired by rloadest::loadConvFactor code by DLLorenz and ldecicco
  ## Makes heavy use of unitted package by A Appling
  
  
  # Translate units - goes quickly if they're good already
  flow.units <- translateFreeformToUnitted(flow.units, TRUE)
  conc.units <- translateFreeformToUnitted(conc.units, TRUE)
  load.rate.units <- translateFreeformToUnitted(load.rate.units, TRUE)
  
  # split the flow.units*conc.units into numerator and denominator
  flow.conc.units <- flow.units * conc.units
  fcu_separated <- separate_units(flow.conc.units)
  fcu_numerstrs <- strsplit(get_units(unitbundle(fcu_separated[which(fcu_separated$Power > 0),])), " ")[[1]]
  fcu_denomstrs <- strsplit(get_units(1/unitbundle(fcu_separated[which(fcu_separated$Power < 0),])), " ")[[1]]
  
  # split the load.rate.units into numerator and denominator
  lru_separated <- separate_units(load.rate.units)
  lru_numerstr <- strsplit(get_units(unitbundle(lru_separated[which(lru_separated$Power > 0),])), " ")[[1]]
  lru_denomstr <- strsplit(get_units(1/unitbundle(lru_separated[which(lru_separated$Power < 0),])), " ")[[1]]
  
  # Identify the right components of the multiplier. Components that are
  # unavailable will be omitted from the multipliers data.frame
  #data(unit.conversions)
  numerator<-denominator<- "rbind.var"
  multipliers <- rbind(
    # Convert to mg/day
    numer_to_mg = subset(unit.conversions, numerator == "mg" & denominator %in% fcu_numerstrs),
    numer_to_L = subset(unit.conversions, numerator == "L" & denominator %in% fcu_numerstrs),
    denom_to_L = subset(unit.conversions, denominator == "L" & numerator %in% fcu_denomstrs),
    denom_to_d = subset(unit.conversions, denominator == "d" & numerator %in% fcu_denomstrs),
    # Convert mg/day to load.rate.units
    mg_to_load = subset(unit.conversions, numerator == lru_numerstr & denominator == "mg"),
    d_to_load = subset(unit.conversions, numerator == "d" & denominator == lru_denomstr)
  )
  
  # Combine the component multipliers into a single multiplier
  multiplier <- u(1,"")
  for(row in 1:nrow(multipliers)) {
    multrow <- multipliers[row,]
    multiplier <- multiplier * u(multrow$value, unitbundle(multrow$numerator)/unitbundle(multrow$denominator)) 
  }
  
  # If the conversion isn't right yet, look for conversions that don't pass through "mg"
  if(unitbundle(get_units(u(1,flow.conc.units) * multiplier)) != load.rate.units) {
    # Identify the numerator still to be converted
    residual_units <- load.rate.units / unitbundle(get_units(u(1,flow.conc.units) * multiplier))
    ru_separated <- separate_units(residual_units)
    ru_numerstr <- strsplit(get_units(unitbundle(ru_separated[which(ru_separated$Power > 0),])), " ")[[1]]
    ru_denomstr <- strsplit(get_units(1/unitbundle(ru_separated[which(ru_separated$Power < 0),])), " ")[[1]]
    # We want the multiplier with the same units as residual_units
    num_to_load <- subset(unit.conversions, denominator == ru_denomstr & numerator == ru_numerstr)
    # Do the additional conversion
    if(nrow(num_to_load) == 1) {
      multiplier <- multiplier * u(num_to_load$value, unitbundle(num_to_load$numerator)/unitbundle(num_to_load$denominator))
    }
    
    # Now confirm that the conversion will work - it really should now.
    if(unitbundle(get_units(u(1,flow.conc.units) * multiplier)) != load.rate.units) {
      stop("Failed to identify the right multiplier. Check that all units are valid")
    }
  }
   
  return(if(attach.units) multiplier else v(multiplier))
}


#' observeSolute - instantaneous loads or concentrations
#' 
#' Calculates observed instantaneous loading rates or concentrations from 
#' observed concentrations, flows, and/or fluxes, with units conversions 
#' according to the supplied metadata.
#' 
#' @param data data.frame containing, at a minimum, the columns named by 
#'   metadata@@constituent and metadata@@flow
#' @param flux.or.conc character giving the desired output format
#' @param metadata An object of class "metadata" describing the units of flow 
#'   (flow.units) and concentration (conc.units) of the input data, and the 
#'   desired units of load (load.rate.units) for the output data
#' @param calculate logical. If FALSE, looks for a column containing the output 
#'   of interest. If true, uses the other two columns (out of those for conc, 
#'   flow, and flux) to calculate the output of interest.
#' @param attach.units logical. If TRUE, the converted observations are returned
#'   with units attached.
#' @export
#' @keywords units
#' @examples
#' obs <- data.frame(MyConc=(1:10)/10, MyFlow=rep(10,10), MyFlux=2) # intentionally inconsistent
#' # between conc*flow and flux
#' md <- updateMetadata(exampleMetadata(), constituent="MyConc", flow="MyFlow", 
#' load.rate="MyFlux", dates="none", flow.units="cms", conc.units="mg/l", 
#' load.units="g", load.rate.units="g/s", custom=NULL)
#'   
#' observeSolute(obs, "flux", md, attach.units=TRUE) # calculate flux from conc & flow
#' observeSolute(obs, "flux", md, calculate=FALSE, attach.units=TRUE) # read flux from data column
#' observeSolute(obs, "conc", md, calculate=TRUE, attach.units=TRUE) # calculate conc 
#' # from flow & flux
observeSolute <- function(
  data, flux.or.conc=c("flux","conc"), metadata, 
  calculate=isTRUE(flux.or.conc=="flux"), 
  attach.units=FALSE) {
  
  # Validate arguments
  flux.or.conc <- match.arg.loadflex(flux.or.conc)
  calculate <- match.arg.loadflex(calculate, c(TRUE, FALSE, NA))
  
  out <- switch(
    flux.or.conc,
    "flux"={
      if(is.na(calculate)) {
        # if calculate==NA, don't calculate unless there's no flux rate column in the data
        calculate <- FALSE
        tryCatch(getCol(metadata, data, "flux rate"), error=function(e) { calculate <<- TRUE })
      }
      if(calculate) {
        loads <- getCol(metadata, data, "conc") * getCol(metadata, data, "flow") * 
          flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), TRUE)
      } else {
        loads <- getCol(metadata, data, "flux rate")
      }
      if(attach.units) {
        loads <- u(loads, getUnits(metadata, "flux rate"))
      }
      loads
    },
    "conc"={
      if(is.na(calculate)) {
        # if calculate==NA, don't calculate unless there's no conc column in the data
        calculate <- FALSE
        tryCatch(getCol(metadata, data, "conc"), error=function(e) { calculate <- TRUE })
      }
      if(calculate) {
        concs <- (getCol(metadata, data, "flux rate") / getCol(metadata, data, "flow")) / 
          flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), TRUE)
      } else {
        concs <- getCol(metadata, data, "conc")
      }
      if(attach.units) {
        concs <- u(concs, getUnits(metadata, "conc"))
      }
      concs
    }
  )
  if(!attach.units) {
    return(v(out))
  } else {
    return(out)
  }
}

#' formatPreds raw to final predictions
#' 
#' Convert raw predictions to final predictions, possibly including a switch 
#' between flux and conc. If there is a switch, the units will be converted 
#' according to the metadata.
#' 
#' @param preds raw prediction values
#' @param from.format character in 
#'   \code{c("flux","conc*flow","flux/flow","conc")}. Format of the raw 
#'   predictions.
#' @param to.format character indicating whether the returned value should be a 
#'   flux or a concentration.
#' @param newdata a data.frame with nrow() == length(preds) and containing any 
#'   columns (named as in \code{metadata}) that will be needed to perform the
#'   requested conversion. For example, from="conc" and to="flux" implies that
#'   a discharge column will be available in \code{newdata}.
#' @param metadata An object of class \code{\link{metadata}} used to determine 
#'   the units of inputs and desired output
#' @param attach.units logical. Attach the units to the returned value?
#' @return converted predictions (in the format/units specified by to.format and
#'   metadata)
#' @export
#' @keywords units
#' @examples
#' obs <- transform(data.frame(MyConc=1:10, MyFlow=rep(10,10)), 
#' MyFlux=MyConc*MyFlow*rloadest::loadConvFactor("cms", "mg/l", "kg") )
#' md <- updateMetadata(exampleMetadata(), constituent="MyConc", flow="MyFlow", 
#' load.rate="MyFlux", dates="none", flow.units="cms", conc.units="mg/l", load.units="kg", 
#' load.rate.units="kg/d", custom=NULL)
#'   
#' formatPreds(preds=obs$MyConc, from.format="conc", to.format="flux", newdata=obs, 
#' metadata=md) # == obs$MyFlux
#' formatPreds(preds=obs$MyConc*obs$MyFlow, from.format="conc*flow", to.format="flux", newdata=obs, 
#' metadata=md) # == obs$MyFlux
#' formatPreds(preds=obs$MyFlux, from.format="flux", to.format="conc", newdata=obs, 
#' metadata=md) # == obs$MyConc
#' formatPreds(preds=obs$MyFlux, from.format="flux", to.format="conc", newdata=obs, metadata=md, 
#' attach.units=TRUE) # == u(obs$MyConc, "mg L^-1")
formatPreds <- function(preds, 
                        from.format=c("flux","conc*flow","flux/flow","conc"), 
                        to.format=c("flux","conc"), 
                        newdata, metadata, attach.units=FALSE) {
  
  # Error checking for formats, with case flexibility
  from.format <- match.arg.loadflex(from.format, c("flux","conc*flow","flux/flow","conc"))
  to.format <- match.arg.loadflex(to.format, c("flux","conc"))
  
  # Do the conversion. Use units within flowconcToFluxConversion but not here, to save time.
  preds <-
    if(to.format=="flux") {
      switch(
        from.format,
        "flux"=preds,
        "conc*flow"=preds * flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), FALSE),
        "flux/flow"=preds * getCol(metadata, newdata, "flow"),
        "conc"=preds * getCol(metadata, newdata, "flow") * flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), FALSE)
      )
    } else { #to.format=="conc"
      switch(
        from.format,
        "flux"=(preds / getCol(metadata, newdata, "flow")) / flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), FALSE),
        "conc*flow"=preds / getCol(metadata, newdata, "flow"),
        "flux/flow"=preds / flowconcToFluxConversion(getUnits(metadata, "flow"), getUnits(metadata, "conc"), getUnits(metadata, "flux rate"), FALSE),
        "conc"=preds
      )
    }
  
  # Attach units to predictions if requested
  if(attach.units) {
    preds <- u(preds, switch(
      to.format,
      "flux"=getUnits(metadata, "flux rate"), # this is a little strange now - maybe we should switch flux.or.conc to take c("flux rate","conc") everywhere
      "conc"=getUnits(metadata, "conc")
    ))
  }
  
  preds
}
