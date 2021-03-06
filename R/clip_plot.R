#' this function is used to clip plots around NEON vegetation structure or CFC
#'
#'
#' @inheritParams str_detect
#' @return A list of dataframe
#' @export
#' @examples from_inventory_to_shp()
#' @importFrom magrittr "%>%"
#' @import sf, reticulate, stringr
clip_plot <- function(plt, list_data,
                      which_python = "/home/s.marconi/.conda/envs/quetzal3/bin/python",
                      bff=12,
                      outdir = "////orange/ewhite/s.marconi/brdf_classification/"
){
  library(lidR)
  library(stringr)
  library(reticulate)
  get_epsg_from_utm <- function(utm){
    utm <-  substr(utm,1,nchar(utm)-1)
    if(as.numeric(utm)<10)utm <- paste('0', utm, sep="")
    epsg <- paste("326", utm, sep="")
    return(epsg)
  }

  #source("./R/get_epsg_from_utm.R")
  # get tile for the plot
  plt <- data.frame(t(plt), stringsAsFactors=F)
  #convert plots coordinates from character to numeric
  plt[["easting"]]<- as.numeric(plt[["easting"]])
  plt[["northing"]]<- as.numeric(plt[["northing"]])

  tile <- paste(plt[["plt_e"]], plt[["plt_n"]], sep="_")
  tile <- grep(tile, list_data, value = TRUE)
  missed_plots <- list()
  #in case of multiple data products per neon product
  for(f in tile[1]){
   tryCatch({
     year = unlist(strsplit(f,split = "/FullSite/"))[[1]]
     year = substr(year, nchar(year)-3, nchar(year))
    #load raster or las file
    if(substr(f, nchar(f)-4+1, nchar(f))==".tif"){
      prd = substr(f, nchar(f)-8+1, nchar(f)-4)
      #prd = "bdrf"
      f<-raster::brick(f)
      #get object with  extent of plot center + buffer
      e <- raster::extent(plt[["easting"]] - bff,
                          plt[["easting"]] + bff,
                          plt[["northing"]] - bff,
                          plt[["northing"]] + bff)
      #crop
      tif <- raster::crop(f, e)
      #and save
      raster::writeRaster(tif,  paste(outdir, prd, "/",
                                      plt[1,1], "_", year, ".tif", sep=""), overwrite=TRUE)
    }else if(substr(f, nchar(f)-4+1, nchar(f))==".laz"){
      #skip files in metadata
      if(!str_detect(f, "Metadata")){
        #read pointcloud
        f <- lidR::readLAS(f)
        #clip by extent
        las <- lidR::lasclipRectangle(f, xleft = plt[["easting"]] - bff,
                                      ybottom=plt[["northing"]] - bff,
                                      xright=plt[["easting"]] + bff,
                                      ytop=plt[["northing"]] + bff)
        #and save
        lidR::writeLAS(las, paste(outdir, "/las/", #./outdir/plots/las/",
                                  plt[1,1], ".las", sep=""))
      }
    }else if(substr(f, nchar(f)-3+1, nchar(f))==".h5"){
      #get epsg from h5
      epsg <- get_epsg_from_utm(plt[["utmZone"]])
      #convert h5 into a tif for the extent of the plot using python
      use_python(which_python, required = T)
      #check if the libraries required are installed in the virtual environment
      h5py <- import("h5py")
      source_python("./R/extract_raster_from_h5.py")
      h5_to_tif <- extract_hsi_and_brdf_data(f,
                               paste(plt[1,1], plt[1,2], sep="_"),
                               plt[["easting"]] - bff,
                               plt[["easting"]] + bff,
                               plt[["northing"]] - bff,
                               plt[["northing"]] + bff,
                               epsg,
                               ras_dir = paste(outdir, "/", sep=""),
                               year = as.character(year)) #
      #ras_dir = './outdir/plots/hsi/')
    }
    }, error = function(e) {
      missed_plots[[plt[1,1]]] <- c(f, plt[1,1], plt[["easting"]], plt[["northing"]])
    })
  }
  return(missed_plots)
}
