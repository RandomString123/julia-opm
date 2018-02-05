# Code I needed to add to make conversion from R easier, some cases are just function
# renaming.  Others are major functions.

function factor(v; ordered=false, levels=nothing) 
    r = CategoricalArray(v, ordered=ordered)
    levels != nothing && (levels!(r, levels))
    return(r)
end

# No duplicated method?  (add pull request to julialang for this)
# This vectorized method should work on anything that can
# * Fit in an array
# * Can be used as a key in a Dict
# fromLast = true will save last instance of a value
# fromlast is an annoying scenario as we need to flip twice
function duplicated(a::AbstractArray; fromLast = false)
    d = Dict()
    # So we only need one maping line
    @inline getA(x) = fromLast ? reverse(x) : (x)
    getA(map(x -> ((haskey(d, x)) ? true : (d[x] = true; false) ),  getA(a)))
end

#@inline factor=CategoricalArray
# A set of methods for transforming OPM Data for Analysis
# This is a port of R code, some functions are created to replace default R functions.
# Define the factors we will use, these are just pre-generated from the source data.
OPMAgeFactorLevels = vcat("15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75+")
OPMLOSFactorLevels = vcat("< 1", "1-2", "3-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35+")

# Changes a vector to a factor based on age ranges
function opm_factor_age(v) 
    factor(v, levels = OPMAgeFactorLevels, ordered = true)
end

# Changes a vector to a factor based on los ranges
function opm_factor_los(v) 
    factor(v, levels = OPMLOSFactorLevels, ordered = true)
end

# Converts nsftp vector to a logical
function opm_indicator_nsftp(v) 
    ifelse.(v .== "2", true, false)
end 

#Takes a tibble, assumed to have OPM fields in it, and cleans it up for data analysis
function opm_organize_tibble(filedata, sctdata) 
 #= Very long pipeline. Leving this for last since it is hardest  
    filedata %>%
    # Put in factors for Lenth of Serivce and Age
    mutate(AGE = opm_factor_age(AGE)) %>%
    mutate(`LOS LEVEL` = opm_factor_los(`LOS LEVEL`)) %>%
    # Change NSFTP to an an indicator
    mutate(NSFTP = opm_indicator_nsftp(`NSFTP IND`)) %>%
    # Hard work!  Change lookup fields into the sctfile into factors
    left_join(opm_sct_get_workschedules(sctdata), by = c("WORK SCHEDULE" = "DATA CODE")) %>%
    mutate(`WORK SCHEDULE` = factor(`WORK SCHEDULE.y`, opm_sct_get_workschedules_values(sctdata))) %>%
    select(-`WORK SCHEDULE.y`) %>%
    left_join(opm_sct_get_appointments(sctdata), by = c("TYPE OF APPOINTMENT" = "DATA CODE")) %>%
    mutate(`TYPE OF APPOINTMENT` = factor(`APPOINTMENT`, opm_sct_get_appointments_values(sctdata))) %>%
    select(-`APPOINTMENT`) %>%
    left_join(opm_sct_get_supervisorystatus(sctdata), by = c("SUPERVISORY STATUS" = "DATA CODE")) %>%
    mutate(`SUPERVISORY STATUS` = factor(`SUPERVISOR`, opm_sct_get_supervisorystatus_values(sctdata))) %>%
    select(-`SUPERVISOR`) %>%
    left_join(opm_sct_get_occupationalcategories(sctdata), by = c("OCCUPATIONAL CATEGORY" = "DATA CODE")) %>%
    mutate(`OCCUPATIONAL CATEGORY` = factor(`OCCUPATIONAL CATEGORY.y`, opm_sct_get_occupationalcategories_values(sctdata))) %>%
    select(-`OCCUPATIONAL CATEGORY.y`) %>%
    left_join(opm_sct_get_occupations(sctdata), by = c("OCCUPATION" = "DATA CODE")) %>%
    mutate(`OCCUPATION` = factor(`OCCUPATION.y`, opm_sct_get_occupations_values(sctdata))) %>%
    select(-`OCCUPATION.y`) %>%
    left_join(opm_sct_get_payplans(sctdata), by = c("PAY PLAN" = "DATA CODE")) %>%
    mutate(`PAY PLAN` = factor(`PAY PLAN.y`, opm_sct_get_payplans_values(sctdata))) %>%
    select(-`PAY PLAN.y`) %>%
    left_join(opm_sct_get_eductionlevels(sctdata), by = c("EDUCATION LEVEL" = "DATA CODE")) %>%
    mutate(`EDUCATION LEVEL` = factor(`EDUCATION LEVEL.y`, opm_sct_get_eductionlevels_values(sctdata))) %>%
    select(-`EDUCATION LEVEL.y`) %>%
    # Duty stations seems to break code parsing, guessing a bad character in one of the names.
    # TODO: try this again, think it was a code bug in another section overwriting a name.
    #left_join(opm_sct_get_dutystations(sctdata), by = c("DUTY STATION" = "DATA CODE")) %>%
    #mutate(`DUTY STATION` = factor(`DUTY STATION.y`, opm_sct_get_dutystations_values(sctdata))) #%>%
    #select(-`DUTY STATION.y`) %>%
    left_join(opm_sct_get_agencies(sctdata), by = c("AGENCY" = "DATA CODE")) %>%
    mutate(`AGENCY` = factor(`AGENCY.y`, opm_sct_get_agencies_values(sctdata))) %>%
    select(-`AGENCY.y`)
    =#
    # Put in factors for Lenth of Serivce and Age
    #mutate(AGE = opm_factor_age(AGE)) %>%
    filedata[:AGE] = opm_factor_age(filedata[:AGE])
    #mutate(`LOS LEVEL` = opm_factor_los(`LOS LEVEL`)) %>%
    filedata[:LOS_LEVEL] = opm_factor_los(filedata[:LOS_LEVEL])
    # Change NSFTP to an an indicator
    #mutate(NSFTP = opm_indicator_nsftp(`NSFTP IND`)) %>%
    filedata[:NSFTP_IND] = opm_indicator_nsftp(filedata[:NSFTP_IND])
    # Hard work!  Change lookup fields into the sctfile into factors
    #left_join(opm_sct_get_workschedules(sctdata), by = c("WORK SCHEDULE" = "DATA CODE")) %>%
    #mutate(`WORK SCHEDULE` = factor(`WORK SCHEDULE.y`, opm_sct_get_workschedules_values(sctdata))) %>%
    #select(-`WORK SCHEDULE.y`) %>%
    # 4julia - these 3 line groups basically performed an in-place left join / replace
    filedata[:WORK_SCHEDULE] =   
        factor(join(DataFrame(X1=filedata[:WORK_SCHEDULE]), 
            opm_sct_get_workschedules(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:WORK_SCHEDULE],
            levels=opm_sct_get_workschedules_values(sctdata))

    #left_join(opm_sct_get_appointments(sctdata), by = c("TYPE OF APPOINTMENT" = "DATA CODE")) %>%
    #mutate(`TYPE OF APPOINTMENT` = factor(`APPOINTMENT`, opm_sct_get_appointments_values(sctdata))) %>%
    #select(-`APPOINTMENT`) %>%
    filedata[:TYPE_OF_APPOINTMENT] =   
        factor(join(DataFrame(X1=filedata[:TYPE_OF_APPOINTMENT]), 
            opm_sct_get_appointments(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:APPOINTMENT],
            levels=opm_sct_get_appointments_values(sctdata))
    #left_join(opm_sct_get_supervisorystatus(sctdata), by = c("SUPERVISORY STATUS" = "DATA CODE")) %>%
    #mutate(`SUPERVISORY STATUS` = factor(`SUPERVISOR`, opm_sct_get_supervisorystatus_values(sctdata))) %>%
    #select(-`SUPERVISOR`) %>%
    filedata[:SUPERVISORY_STATUS] =   
        factor(join(DataFrame(X1=filedata[:SUPERVISORY_STATUS]), 
            opm_sct_get_supervisorystatus(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:SUPERVISOR],
            levels=opm_sct_get_supervisorystatus_values(sctdata))

    #left_join(opm_sct_get_occupationalcategories(sctdata), by = c("OCCUPATIONAL CATEGORY" = "DATA CODE")) %>%
    #mutate(`OCCUPATIONAL CATEGORY` = factor(`OCCUPATIONAL CATEGORY.y`, opm_sct_get_occupationalcategories_values(sctdata))) %>%
    #select(-`OCCUPATIONAL CATEGORY.y`) %>%
    filedata[:OCCUPATIONAL_CATEGORY] =   
        factor(join(DataFrame(X1=filedata[:OCCUPATIONAL_CATEGORY]), 
            opm_sct_get_occupationalcategories(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:OCCUPATIONAL_CATEGORY],
            levels=opm_sct_get_occupationalcategories_values(sctdata))
    
    #left_join(opm_sct_get_occupations(sctdata), by = c("OCCUPATION" = "DATA CODE")) %>%
    #mutate(`OCCUPATION` = factor(`OCCUPATION.y`, opm_sct_get_occupations_values(sctdata))) %>%
    #select(-`OCCUPATION.y`) %>%
    filedata[:OCCUPATION] =   
        factor(join(DataFrame(X1=filedata[:OCCUPATION]), 
            opm_sct_get_occupations(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:OCCUPATION],
            levels=opm_sct_get_occupations_values(sctdata))

    #left_join(opm_sct_get_payplans(sctdata), by = c("PAY PLAN" = "DATA CODE")) %>%
    #mutate(`PAY PLAN` = factor(`PAY PLAN.y`, opm_sct_get_payplans_values(sctdata))) %>%
    #select(-`PAY PLAN.y`) %>%
    filedata[:PAY_PLAN] =   
        factor(join(DataFrame(X1=filedata[:PAY_PLAN]), 
            opm_sct_get_payplans(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:PAY_PLAN],
            levels=opm_sct_get_payplans_values(sctdata))

    #left_join(opm_sct_get_eductionlevels(sctdata), by = c("EDUCATION LEVEL" = "DATA CODE")) %>%
    #mutate(`EDUCATION LEVEL` = factor(`EDUCATION LEVEL.y`, opm_sct_get_eductionlevels_values(sctdata))) %>%
    #select(-`EDUCATION LEVEL.y`) %>%
    filedata[:EDUCATION_LEVEL] =   
        factor(join(DataFrame(X1=filedata[:EDUCATION_LEVEL]), 
            opm_sct_get_eductionlevels(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:EDUCATION_LEVEL],
            levels=opm_sct_get_eductionlevels_values(sctdata))

    # Duty stations seems to break code parsing, guessing a bad character in one of the names.
    # TODO: try this again, think it was a code bug in another section overwriting a name.
    #left_join(opm_sct_get_dutystations(sctdata), by = c("DUTY STATION" = "DATA CODE")) %>%
    #mutate(`DUTY STATION` = factor(`DUTY STATION.y`, opm_sct_get_dutystations_values(sctdata))) #%>%
    #select(-`DUTY STATION.y`) %>%
    
    #left_join(opm_sct_get_agencies(sctdata), by = c("AGENCY" = "DATA CODE")) %>%
    #mutate(`AGENCY` = factor(`AGENCY.y`, opm_sct_get_agencies_values(sctdata))) %>%
    #select(-`AGENCY.y`)
    filedata[:AGENCY] =   
        factor(join(DataFrame(X1=filedata[:AGENCY]), 
            opm_sct_get_agencies(sctdata), on=(:X1, :DATA_CODE), kind=:left)[:AGENCY],
            levels=opm_sct_get_agencies_values(sctdata))

    return filedata
end

# Will pull all values for a table ID out of tibble parameter sctfile and return them
# sctfile tibble of data to pull from
# tblanme two character code of table to pull
function opm_sct_get_table(sctfile, tblname)
    #sctfile %>%
    #    filter(`SCT TABLE ID` == tblname) %>%
    #    select(c("DATA CODE", "TRANSLATION 1"))
    @from i in sctfile begin
    @where i.SCT_TABLE_ID == tblname
    @select {i.DATA_CODE, i.TRANSLATION_1}
    @collect DataFrame
    end
end

#Pulls appointments "VM" out of the SCT DATA, assums SCT structure of tibble
function opm_sct_get_appointments(sctfile) 
    #opm_sct_get_table(sctfile, "VM") %>% rename("APPOINTMENT" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "VM"), :TRANSLATION_1 => :APPOINTMENT)
end

function opm_sct_get_appointments_values(sctfile) 
    #opm_sct_get_appointments(sctfile) %>% pull("APPOINTMENT")
    opm_sct_get_appointments(sctfile)[:APPOINTMENT]
end

function opm_sct_get_eductionlevels(sctfile) 
    #opm_sct_get_table(sctfile, "EV") %>% rename("EDUCATION LEVEL" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "EV"), :TRANSLATION_1 => :EDUCATION_LEVEL)
end

function opm_sct_get_eductionlevels_values(sctfile) 
    #opm_sct_get_eductionlevels(sctfile) %>% pull("EDUCATION LEVEL")
    opm_sct_get_eductionlevels(sctfile)[:EDUCATION_LEVEL]
end

function opm_sct_get_occupationalcategories(sctfile) 
    #opm_sct_get_table(sctfile, "GF") %>% rename("OCCUPATIONAL CATEGORY" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "GF"), :TRANSLATION_1 => :OCCUPATIONAL_CATEGORY)
end

function opm_sct_get_occupationalcategories_values(sctfile) 
    #opm_sct_get_occupationalcategories(sctfile) %>% pull("OCCUPATIONAL CATEGORY")
    opm_sct_get_occupationalcategories(sctfile)[:OCCUPATIONAL_CATEGORY]
end

function opm_sct_get_payplans(sctfile) 
    #opm_sct_get_table(sctfile, "LA") %>% rename("PAY PLAN" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "LA"), :TRANSLATION_1 => :PAY_PLAN)
end

# There are duplicate pay plan names for codes, executive decision: just remove duplicates
function opm_sct_get_payplans_values(sctfile) 
    #opm_sct_get_payplans(sctfile) %>% pull("PAY PLAN") %>% unique()
    unique(opm_sct_get_payplans(sctfile)[:PAY_PLAN])
end

function opm_sct_get_supervisorystatus(sctfile) 
    #opm_sct_get_table(sctfile, "SU") %>% rename("SUPERVISOR" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "SU"), :TRANSLATION_1 => :SUPERVISOR)
end

function opm_sct_get_supervisorystatus_values(sctfile) 
    #opm_sct_get_supervisorystatus(sctfile) %>% pull("SUPERVISOR")
    opm_sct_get_supervisorystatus(sctfile)[:SUPERVISOR]
end

function opm_sct_get_workschedules(sctfile) 
    #opm_sct_get_table(sctfile, "WS") %>% rename("WORK SCHEDULE" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "WS"), :TRANSLATION_1 => :WORK_SCHEDULE)
end

function opm_sct_get_workschedules_values(sctfile) 
    #opm_sct_get_workschedules(sctfile) %>% pull("WORK SCHEDULE")
    opm_sct_get_workschedules(sctfile)[:WORK_SCHEDULE]
end

function opm_sct_get_occupations(sctfile) 
    #opm_sct_get_table(sctfile, "XB") %>% rename("OCCUPATION" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "XB"), :TRANSLATION_1 => :OCCUPATION)
end

# There are duplicate occupation names for codes, executive decision: just remove duplicates
function opm_sct_get_occupations_values(sctfile) 
    #opm_sct_get_occupations(sctfile) %>% pull("OCCUPATION") %>% unique()
    unique(opm_sct_get_occupations(sctfile)[:OCCUPATION])
end

function opm_sct_get_dutystations(sctfile) 
    #opm_sct_get_table(sctfile, "VX") %>% rename("DUTY STATION" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "VX"), :TRANSLATION_1 => :DUTY_STATION)
end

function opm_sct_get_dutystations_values(sctfile) 
    #opm_sct_get_dutystations(sctfile) %>% pull("DUTY STATION")
    opm_sct_get_dutystations(sctfile)[:DUTY_STATION]
end

# Agencies is a bit tricker than others, it has duplicates so we need to de,dupe it in a most likely not correct manner
function opm_sct_get_agencies(sctfile) 
    #tmp <- opm_sct_get_table(sctfile, "AH") %>% rename("AGENCY" = `TRANSLATION 1`)
    #tmp[!duplicated(tmp$`DATA CODE`, fromLast=TRUE),]
    tmp = opm_sct_get_table(sctfile, "AH")
    rename!(tmp, :TRANSLATION_1 => :AGENCY)
    tmp[.!duplicated(tmp[:DATA_CODE], fromLast=true), :]
end

function opm_sct_get_agencies_values(sctfile) 
    #opm_sct_get_agencies(sctfile) %>% pull("AGENCY") %>% unique()
    unique(opm_sct_get_agencies(sctfile)[:AGENCY])
end

# THESE ARE NOT SALARY GRADES, NOT SURE WHAT THEY ARE
# Figured it out...they are combo codes for combined plan+grade lookup
function opm_sct_get_grades(sctfile) 
    #opm_sct_get_table(sctfile, "VK") %>% rename("GRADE" = `TRANSLATION 1`)
    rename!(opm_sct_get_table(sctfile, "VK"), :TRANSLATION_1 => :GRADE)
end

function opm_sct_get_dutystations_values(sctfile) 
    #opm_sct_get_grades(sctfile) %>% pull("GRADE")
    opm_sct_get_grades(sctfile)[:GRADE]
end
