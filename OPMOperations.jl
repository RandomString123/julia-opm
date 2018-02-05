# Needed to sort a dataframe in julia becuase order can be fluent
function opm_sort!(x::DataFrame)
    sort!(x, cols=[order(:PSEUDO_ID), order(:FILE_DATE)])
end
# This will number each sequence of years in a grouping so this index can be used for a 2nd level
function opm_number_year_runs!(x) 
    #years <- as.integer(pull(x, "year"))
    #ids <- pull(x, `PSEUDO-ID`)
    #x %>% mutate(`group-id` = cumsum(ifelse(is.na(lag(year)) | (`PSEUDO-ID` == lag(`PSEUDO-ID`) & (as.integer(year) != lag(as.integer(year)) + 1)), TRUE, FALSE)))
    #Ensure years are present
    opm_add_years!(x)
    opm_sort!(x)
    # this was a one liner in R, sure it can be in julia but missings make it difficult
    # Turns out functions / loops are not bad in julia
    y = x[:year]
    lyear = lag(y)
    id = x[:PSEUDO_ID]
    lid = lag(id)

    x[:group_id] =  cumsum( [ 
            ifelse((ismissing(y[i]) || ismissing(lyear[i]) || ismissing(id[i]) || ismissing(lid[i]))
                || (id[i] != lid[i]) && (y[i] != lyear[i]+1), true, false
            )
            for i in 1:length(y)
        ])
end

# 8555569, 9170732, 9588934
# data[findin(data[:PSEUDO_ID], [8555569, 9170732, 9588934]), [:PSEUDO_ID, :group_by]]

# OPM Fill w/ interpolation 
# Don't use this in our final analysis.
# TIP! This should be run just after dataset is loaded or calcuated columns will be wrong.
# Duplicate years next to each other break this for some reason, make sure they are filtered.
# This will run through the dataset x, assuming it is our typcial tibble format.
# Any breaks in the year sequence of max_fill or less will be
# filled with iterpolated data.  We default to 1 becuase that is the most probable error value.
# Larger breaks will need to be resolved with other mechanisms.
# This may only work on a non-organied tibble so be wary!
#= Wasn't used not going to convert
opm_interpolation_generate_salary <- function(x, max_fill=1) {
    # Pre-calculate a lot of stuff
    years <- as.integer(pull(x, "year"))
    ids <- pull(x, `PSEUDO-ID`)
    row_def <- x[0,] %>% ungroup()

    gap_check <- which(ifelse(!is.na(lead(years)) & ids == lead(ids) & (years + 1 != lead(years)), TRUE, FALSE))
    print(paste("Gaps to check for filling:", length(gap_check)))
    rows <- bind_rows(row_def,lapply(gap_check, function(x2) {
        i <- match(x2, gap_check)
        if (i %% 10000 == 0)
            print(paste("At", i,",",Sys.time()))
            opm_create_interpolate_rows(idx = x2, x = x, year = years, max_fill = max_fill)
        }))
    print(paste("Number of gaps filled:", length(rows$`PSEUDO-ID`)))
    # We actually want to generate years for our data before returning.
    return(rows)
} =#

# Will generate rows of type x that need to be inserted to close the gap between idx and idx+1
# Don't use this in our final product
#=
Wasn't used in final product not converting.
opm_create_interpolate_rows <- function(idx, x, years, max_fill) {
    if(years[idx] + max_fill < years[idx + 1] - 1) return(NULL)
    fill_range <- seq(years[idx] + 1, years[idx + 1] - 1)
    len = length(fill_range)
    fill_values = as.integer(seq(x[[idx, "ADJUSTED BASIC PAY"]], x[[idx + 1, "ADJUSTED BASIC PAY"]], length.out = len + 2))
    return(bind_rows(lapply(fill_range, function(yr) {tibble(
                    `PSEUDO-ID` = x[[idx, "PSEUDO-ID"]],
                    `FILE DATE` = as.Date(paste(yr, "-12-13", sep = "")),
                    `ADJUSTED BASIC PAY` = fill_values[yr - years[idx] + 1],
                    year = as.character(yr)
                    )

    })))
}
=#

# This may create gaps in our data, we'll clean it up later.
function opm_filter_unusable_rows(x) 
    #x %>%
    #    filter(`WORK SCHEDULE` == "FULL-TIME") %>%
    ##We know all work schedules are full time so filter out the columns
    #   select(-`WORK SCHEDULE`) %>%
    #    # Ensure nothing exists outside of our target range.
    #   filter(`FILE DATE` > as.Date("1973-11-30") & `FILE DATE` < as.Date("2014-1-1"))
    @from r in x begin
    @where r.WORK_SCHEDULE == "FULL-TIME"  && r.FILE_DATE > Date(1973, 11, 30) && r.FILE_DATE < Date(2014,1,1)
    @orderby r.PSEUDO_ID, r.FILE_DATE
    @select r
    @collect DataFrame
    end
end


# This will filter out all of the rows we want to remove before analysis.
# Unfortunately this a long running process but we only run it once after all data is loaded.
# We also do this in weird way to keep R from creating 3 copies of our object.
# we are removing all PSEUDO-IDs that have more than one record in any year
# also we are removing people who have more records than years of service
function opm_filter_unusable_ids(x) 
    #print(paste("Calculating multiple year Filters...", Sys.time()))
    print("Calculating multiple year Filters...", now())
    #yos_filter <- eval.parent(x %>% ungroup() %>% group_by(`PSEUDO-ID`, `FILE DATE`) %>%
    #    summarize(count = n()) %>% filter(count > 1) %>% pull(`PSEUDO-ID`)
    # filter people who more than one row in a year
    yos_filter =by(x, [:PSEUDO_ID, :FILE_DATE], nrow)[: ,:PSEUDO_ID]
    #print(paste("Calculated multi-year objects:",length(yos_filter)))
    print("Calculated multi-year objects:", length(yos_filter))
    #print(paste("Calculating years of service Filters...", Sys.time()))
    print("Calculating years of service Filters...", now())
    #yos2_filter <- eval.parent(x %>% summarize(count = n(), years = (as.integer(last(year)) + 1 - as.integer(first(year)))) %>% filter(count > years) %>% pull(`PSEUDO-ID`))

    #ids <- eval.parent(x$`PSEUDO-ID`)
    #print(paste("Calculated yos objects: ",length(yos2_filter)))
    #x <- x %>% ungroup() %>% group_by(`PSEUDO-ID`)
    #gc()
    #id_filter <- !(ids %in% unique(c(yos_filter, yos2_filter)))
    #print(paste("Calculated Remaining Rows: ", sum(id_filter)))
    #rm(yos_filter, yos2_filter)
    #gc()
    #print(paste("Filtering...", Sys.time()))
    #eval.parent(return(x[id_filter,])) 
    return x   
end

# This will do the following
# Group the result set by PSEUDO-ID, group-id to analize based on career segments
# Add 2016 Base Year Salary
# Add % salary change
# Add % inflation change
function opm_add_calculations!(x) 
    #x %>%
    #    group_by(`PSEUDO-ID`, `group-id`) %>%
    #tmp = groupby(x, [:PSEUDO_ID, :group_id])
    ##mutate(`2016 adjusted pay` = as.integer(opm_inflation_adjust(`year`, "2016", `ADJUSTED BASIC PAY`))) %>%
    x[:adjusted_pay_2016] = opm_inflation_adjust(x[:year], 2016, x[:ADJUSTED_BASIC_PAY])
    x[:rowid] = [x for x in 1:size(x,1)]
    tmp = by(x, [:PSEUDO_ID, :group_id]) do df
        #mutate(`pay change` = opm_percent_change(`ADJUSTED BASIC PAY`),    
        DataFrame(pay_change = opm_percent_change(df[:ADJUSTED_BASIC_PAY]),
        #    `inflation` = opm_percent_change_inflation(`year`), idx = 1 + year - min(year, na.rm = TRUE),
                  inflation = opm_percent_change_inflation(df[:year]),
                  idx = 1:size(df,1),
                  sdfrowid=df[:rowid] # For back merging
        )
    end
 
    # Ensure both are sorted to match order then merge.
    sort!(x, cols=[order(:rowid)])
    sort!(tmp, cols=[order(:sdfrowid)])
    x[:pay_change] = tmp[:pay_change]
    x[:inflation] = tmp[:inflation]
    x[:idx] = tmp[:idx]
    opm_sort!(x) # Re-sort just to be sure
    #    `inflation` = opm_percent_change_inflation(`year`), idx = 1 + year - min(year, na.rm = TRUE),
    #    `2016 adjusted pay` = as.integer(opm_inflation_adjust(`year`, "2016", `ADJUSTED BASIC PAY`))) # %>%
    #    #mutate(`inflation` = opm_percent_change_inflation(`year`))
end

# Add years convience data to tibble, breaking out becuase we need it early.
function opm_add_years!(x) 
    #x %>%
    #    #group_by(`PSEUDO-ID`) %>%
    #    mutate(`year` = format(`FILE DATE`, "%Y"))
    x[:year] = Dates.year.(x[:FILE_DATE])
end

#Returns percent change in v2 if v1 is sequencial, otherwise NA for value

function opm_ifseq_percent_change(v1, v2)
    #ifelse(lag(v1) + 1 == v1, opm_percent_change(v2), NA)
    # No idea why I had to add these, fortunately thier scope is 
    # limited to this function
    ifelse(c::Missing, t, f) = (f)
    ifelse(c::Bool, t::Missing, f) = (c?t:f)
    ifelse(c::Bool, t, f::Missing) = (c?t:f)
    ifelse(c::Bool, t::Missing, f::Missing) = (c?t:f)
    lagv1 = lag(v1)
    ifelse.(lagv1+1 .== v1, opm_percent_change(v2), missing)
end

# This has to be a builtin somewhere right?
# Calculates the percentage change between a list item and the previous item
function opm_percent_change(x) 
    #old <- lag(x)
    #new <- x
    #((new - old) / old)
    o = lag(x)
    n = x
    ((n .- o) ./ o)
end


# WARNING: This code makes assumptions about filenames and works on fixed width files
# This will iterate over all of the files in dataset assuming December data is correct yearly values
# It will pull values out of March, June, and September that do not last a year then combine and unique
# To ensure one record per year.
# Lastly it will merge with the december values to produce one record per PSEUDO-ID per year.
# Data will be organized(factored & shrunk) becuase it saves a lot of memory
#= julia - not sure we will generate a dataset the same way.
opm_generate_dataset_from_fwfs <- function(files, sctdata, columns = NULL) {

    # Parse march, june, and september files keep anyhting less than a year
    result_march <- opm_load_filelist(files[endsWith(files, "_03.txt")], sctdata = sctdata, columns = columns) %>% group_by(`PSEUDO-ID`) %>% filter(n() == 1) %>% ungroup()
    result_june <- opm_load_filelist(files[endsWith(files, "_06.txt")], sctdata = sctdata, columns = columns) %>% group_by(`PSEUDO-ID`) %>% filter(n() == 1) %>% ungroup()
    result_sept <- opm_load_filelist(files[endsWith(files, "_09.txt")], sctdata = sctdata, columns = columns) %>% group_by(`PSEUDO-ID`) %>% filter(n() == 1) %>% ungroup()
    # We can now we combine these sets and use duplicated to remove all but the last
    # instance of a PSEUDO-ID
    combined <- list(result_march, result_june, result_sept) %>% bind_rows()
    combined <- combined[!duplicated(combined$`PSEUDO-ID`, fromLast = TRUE),]
    # Cleanup for upcoming big operation
    rm(result_march, result_june, result_sept)
    gc()
    # Load our dec based items only once
    results <- opm_load_filelist(files[endsWith(files, "_12.txt")], sctdata, columns = columns)
    # Merge dec dataset with items that only appear in one year so far
    # Then remove items that are in results & combined from combined
    combined <- combined[!(combined$`PSEUDO-ID` %in% results$`PSEUDO-ID`),]
    # Then merge the two datasets to get a final list of all employees over the span
    # Sort it and return
    results <- list(combined, results) %>% bind_rows() %>% arrange(`PSEUDO-ID`, `FILE DATE`)
    rm(combined)
    gc()
    return(results)
}
=#

# This will parse and organize all of the files in pathList.
# Turns out if we don't filter columns we run out of memory with just one set.
# So use parameter columns to specify a vector of columns to keep.
# Also have ids as a list of ids to filter by, so we can grep across a lot of files for an ID
function opm_load_filelist(pathList::Vector{String}, sctdata::DataFrame; columns::Vector{Symbol} = nothing,  ids=nothing, silent=false) 
    #lapply(pathList, opm_load_and_organize, sctdata = sctdata, columns = columns, ids = ids) %>% bind_rows()   
    vcat([opm_load_and_organize(x, sctdata, columns=columns, ids = ids, silent=silent) for x in pathList]...)
end

# Needs path to file
# Needs sctlookup data
# Optional list of columns to filter by
# Optional vector of PSEUDO-IDs to filter by
# silent doesn't print anything to console.
function opm_load_and_organize(path, sctdata;  columns=nothing,  ids=nothing, silent = false) 
    #result <- opm_parse_fwf(path) %>% opm_organize_tibble(sctdata)
    result = opm_parse_fwf(path)
    result = opm_organize_tibble(result, sctdata)
    #if (is.vector(columns)) {
    #    result <- result %>% select(one_of(columns))
    #}
    if(columns != nothing)
        result = result[columns]
    end
    #if (is.vector(ids)) {
    #    result <- result %>% filter(`PSEUDO-ID` %in% ids)
    #}
    if(ids != nothing)
        result = result[findin(result[:PSEUDO_ID], ids), :]
    end
    #if (!silent) {
    #    print(paste("Loaded:", path))
    #}
    if(!silent) 
        println(STDOUT, "Loaded: $path")
    end
    #return(result)
    return result
end

# This will generate a tibble format that we run a model off of.
# This assumes it is being passed our first stage parsing format.
function opm_generate_model_tibble(x) 
    #x %>% ungroup() %>% 
    ## Convert grade to a factor
    #mutate(GRADE = factor(GRADE), year = as.integer(year)) %>%
    ## Add our derived statistics to the final format.
    #opm_add_calculations()
    x[:GRADE] = factor(x[:GRADE])
    opm_add_calculations!(x) 
end
