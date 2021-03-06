#' @title Function to run bayts on mulitple raster bricks
#' 
#' @description Implements bayts function on multiple time series rasterBrick object(s). 
#' Time information is provided as an extra object and the time series can be regular or irregular. Information describing F and NF distributions is provided for each time series. See (\code{\link{bayts}}) for more details. 

#' @references \href{http://www.mdpi.com/2072-4292/7/5/4973}{Reiche et al. (2015): A Bayesian Approach to Combine Landsat and ALOS PALSAR Time Series for Near Real-Time Deforestation Detection. Remote Sensing. 7(5), 4973-4996; doi:10.3390/rs70504973}

#' @author Johannes Reiche (Wageningen University)

#' @param bL list of raster bricks. Raster bricks need to have the same extent and spatial resolution.
#' @param datesL list of time vector of the format: "2014-10-07". 
#' @param pdfL list of "pdf" object(s) describing F and NF distributions (see \code{\link{calcPNF}}). 
#' "pdf" object: pdf[1] = pdf type F, pdf[2] = pdf type NF, pdf[3] and pdf[4] = pdf parameter describing F, pdf[5] and pdf[6] = pdf parameter describing NF. pdf types supported: Gaussian or Weibull.
#' @param bwf block weighting function to truncate the NF probability; Default=c(0.1,0.9); (c(0,1) = no truncation) 
#' @param chi threshold of Pchange at which the change is confirmed; Default=0.5
#' @param PNFmin threshold of pNF above which the first observation is flagged; Default=0.5
#' @param start start date of monitoring period. Default=NULL (start of input time series).
#' @param end end date of monitoring period. Default=NULL (end of input time series)
#' @param pptype character. Type of preprocessing to be applied to individual time series vectors. The two options are 'irregular' and '16-days'. See \code{\link{bfastts}} for more details.
#' @param outfile output file
#' @param mc.cores numeric. number of cores to be used for the job. See \code{\link{mc.calc}} for more details (default = 1)

#' @return A rasterBrick with 5 layers: 
#' (1) flag: time at which unconfirmed change got flagged; 
#' (2) change.flagged: time at which confirmed change got flagged; 
#' (3) change.confirmed: time at which change is confirmed; 
#' (4) Pflag: Probabilty of change for unconfirmed flagged changes; 
#' (5) Pchange.confirmed: Probabilty of change for confirmed changes.

#' @examples 
#' #TBD

#' @export 


baytsSpatial <- function(bL = list(NULL,...), datesL=list(NULL,...), pdfL=list(NULL,...), bwf=c(0.1, 0.9), chi=0.9, PNFmin=0.5, start=NULL, end=NULL, pptype='irregular', out_file=NULL, mc.cores=1)
{
  
  is.integer0 <- function(x)
  {
    is.integer(x) && length(x) == 0L
  }
  cell_index <<- 0 
  fun <- function(v) {
    cell_index <<- cell_index+1
    if(!all(is.na(v))){
      #get number of time series and create time series list
      l <- 0
      for(i in 1:length(datesL)){
        d <- datesL[[i]] 
        b <- v[l+1:(l+length(d))]
        ts <- bfastts(b,d,type=pptype)
        
        if(length(na.omit(as.zoo(ts))>0)){
          if(exists("pdfL2")){
            pdfL2 <- c(pdfL2,list(pdfL[[i]]))
            tsL <- c(tsL,list(ts))
          } else {
            pdfL2 <- list(pdfL[[i]])
            tsL <- list(ts)
          }
        }
        l <- l + length(d)
      }
      
      #run Bayts
      bayts <- createBayts(tsL=tsL, pdfL=pdfL2, bwf=bwf)
      bayts <- detectBayts(bayts, chi=chi, PNFmin=PNFmin, start=start, end=end)
      
      #get output information
      if(is.integer0(which(bayts$Flag=="Change"))==FALSE){
        change = index(bayts[min(which(bayts$Flag=="Change"))])
        change.confirmed = index(bayts[max(which(bayts$Flag=="Change"))])
        if(length(as.double(na.omit(bayts$PChange[max(which(bayts$Flag=="Change"))])))>0){
          pchange = as.double(na.omit(bayts$PChange[max(which(bayts$Flag=="Change"))]))
        } else {pchange = NA}
      } else {
        change = NA
        change.confirmed = NA
        pchange = NA
      }
      if(is.integer0(which(bayts$Flag=="Flag"))==FALSE){
        flag = index(bayts[min(which(bayts$Flag=="Flag"))])
        if(length(as.double(na.omit(bayts$PChange[max(which(bayts$Flag=="Flag"))])))>0){
          pflag = as.double(na.omit(bayts$PChange[max(which(bayts$Flag=="Flag"))]))
        } else {pflag = NA}
      } else {
        flag = NA
        pflag = NA
      }
      res <- cbind(flag,change,change.confirmed,pflag,pchange)
    } else {
      res <- cbind(NA,NA,NA,NA,NA)
    }
    return(res) 
  }
  
  b <- bL[[1]]
  if(length(bL)>1){
    for(i in 2:length(bL)){
      b <- addLayer(b,bL[[i]])  
    }
  }
  
  x <- calc(b, fun=fun, mc.cores=1) # mc.calc mc.cores
  names(x) <- c("flag","change.flagged","change.confirmed","Pflag","Pchange.confirmed")
  
  if (!is.null(out_file)) {writeRaster(x,filename=out_file,overwrite=TRUE)}
  
  return(x)
}