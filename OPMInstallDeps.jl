# OPMInstallDeps - Load / Install depencies for rest of the files to operate


if (install)  
    Pkg.add(["FWF","DataFrames","CategoricalArrays", "Query", "ShiftedArraysShiftedArrays"])
    #install.packages("dplyr", repos = "http://mran.revolutionanalytics.com")
    #install.packages("tidyverse", repos = "http://mran.revolutionanalytics.com")
    #install.packages("reshape2", repos = "http://mran.revolutionanalytics.com")
end
using FWF
using DataFrames
using CategoricalArrays
using Query
using ShiftedArrays

include("OPMFileParsing.jl")
include("OPMFileTransform.jl")
include("OPMOperations.jl")
# Keep this last
include("OPMExternalData.jl")
