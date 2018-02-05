# OPM - Load / Create a dataset from flat text files or r datasource


# Set this to true to force a refresh from source datafiles
refresh = false
# Set this to true to install packages from the internet
install = false
# Hardcode a location to the sctfile here.
sctfile = raw"C:\Users\ME\Desktop\data\1973-09-to-2014-06\SCTFILE.TXT"
# This is the location of the root of the files
fileroot = raw"C:\Users\ME\Desktop\data\1973-09-to-2014-06"

# Location of files of interest within our root
subdir = "non-dod/status"
path = joinpath(fileroot, subdir)
# Filename to write our results to disk or read from disk.
result_filename = joinpath(path, "../non-dod-summary.rds")
filtered_filename = joinpath(path, "../non-dod-filtered.rds")
model_filename = joinpath(path, "../non-dod-model.rds")

# List of fields to pull from the files.
fields_of_interest = vcat(:PSEUDO_ID, :FILE_DATE, :AGENCY, :OCCUPATION, :LOS_LEVEL, :PAY_PLAN, :GRADE, :ADJUSTED_BASIC_PAY, :WORK_SCHEDULE)

### Executed code from here on ###
# Get our filelist and parse sctdata
files = [files for (root, dirs, files) in walkdir(path)]
files = [joinpath(path, file) for file in files[1]]
# This loads all files and includes depencenies
include(raw"C:\Users\ME\OneDrive\Documents\julia\FWF\src\FWF.jl")
include("OPMInstallDeps.jl")
sctdata = opm_parse_sctfile_fwf(sctfile)

# For now, load ad-hoc here - julia
files = files[endswith.(files, "_12.txt")]
data = opm_load_filelist(files, sctdata, columns = fields_of_interest, silent=false)
# If refresh...delete our files.
#if (refresh) {
#    file.remove(c(result_filename, filtered_filename, model_filename))
#}

# Load and prepare data...
# otherwise load from source files and sleep for a few hours.
##if (!file.exists(result_filename)) {
#    print(paste(Sys.time(), "No Basic Result File, Reparsing sources."))
#    result <- opm_generate_dataset_from_fwfs(files, sctdata = sctdata, columns = fields_of_interest)
#    write_rds(result, result_filename)
#    # If we wrote this file remove the filtered file, just to be sure
#    file.remove(filtered_filename)
#    print(paste(Sys.time(), "Result file generated"))
#}

#if (!file.exists(filtered_filename)) {
#    print(paste(Sys.time(), "No Filtered File, Performing filtering and grouping"))
#    rm(result)
#    gc()
    # This just always reads from the rds to hopefully allow the above to cleanup memory.
#    result <- read_rds(result_filename) %>% ungroup() %>% opm_filter_unusable_rows() %>% opm_add_years() %>% group_by(`PSEUDO-ID`)
    # Sneak in a gc to eek out a bit more memory.
#    gc()
#    result <- result %>% opm_filter_unusable_ids() %>% opm_number_year_runs() %>% group_by(`PSEUDO-ID`, `group-id`)
#    write_rds(result, filtered_filename)
#    print(paste(Sys.time(), "Filtered file generated"))
#} else if (!file.exists(model_filename)) {
#    print(paste(Sys.time(), "Filtered File found.  Loading for model building."))
#    result <- read_rds(filtered_filename)
#}


#if (!file.exists(model_filename)) {
#    print(paste(Sys.time(), "Model file not found, building model"))
#    model <- opm_generate_model_tibble(result)
#    write_rds(model, model_filename)
#    rm(result)
#    gc()
#   print(paste(Sys.time(), "Model file generated"))
#} else {
#    print(paste(Sys.time(), "Loading model file."))
#    model <- read_rds(model_filename)
#}
# Interesting cases to look at...
# 8,289, 21, 14, 10357722, 166
# 21 is kelli
# 8 departs after 3 years of no increases
# 166, 289, 14 fragmented employment
#
#72738 - termination + long service