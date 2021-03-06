% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/retrieve_dist_to_utm.R
\name{retrieve_dist_to_utm}
\alias{retrieve_dist_to_utm}
\title{Using the coordinates of the point ids and trigonometry,
get precise locations of trees}
\usage{
retrieve_dist_to_utm(dista, angle, xcord, ycord)
}
\arguments{
\item{dista}{numeric. distance between point id and tree stem}

\item{angle}{numeric. Azimut angle between point id and tree stem}

\item{xcord}{numeric. UTM East of the point ID}

\item{ycord}{numeric. UTM West of the point ID}
}
\description{
Using the coordinates of the point ids and trigonometry,
get precise locations of trees
}
\examples{
retrieve_dist_to_utm(dista = 20, angle = 87, xcord = 432)


}
