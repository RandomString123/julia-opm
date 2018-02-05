strrep(s::String, r::UnitRange) = [repeat(s, n) for n in r]
naValues = vcat(strrep("*", 1:23), strrep("#", 1:23), "NAME WITHHELD BY AGENCY", "NAME WITHHELD BY OPM", "NAME UNKNOWN", "UNSP", "<NA>", "000000", "999999", "")

#    ~FieldName,~Length, ~Type,
CPDFStandardFormat = DataFrame(["SCT_TABLE_ID"  2  String;
    "DATA_CODE" 9  String;
    "CODE_USE_FROM 1"  6  DateFormat("yyyymm");
    "CODE_USE_UNTIL 1"  6 DateFormat("yyyymm");
    "CODE_USE_FROM 2"  6  DateFormat("yyyymm");
    "CODE_USE_UNTIL 2"  6  DateFormat("yyyymm");
    "TRANSLATION_1"  40  String;
    "TRANSLATION_IN_USE_FROM 1"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 1"  6  DateFormat("yyyymm");
    "TRANSLATION_2"  40  String;
    "TRANSLATION_IN_USE_FROM 2"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 2"  6  DateFormat("yyyymm");
    "TRANSLATION_3"  40  String;
    "TRANSLATION_IN_USE_FROM 3"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 3"  6  DateFormat("yyyymm");
    "TRANSLATION_4"  40  String;
    "TRANSLATION_IN_USE_FROM 4"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 4"  6  DateFormat("yyyymm");
    "TRANSLATION_5"  40  String;
    "TRANSLATION_IN_USE_FROM 5"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 5"  6  DateFormat("yyyymm");
    "TRANSLATION_6"  40  String;
    "TRANSLATION_IN_USE_FROM 6"  6  DateFormat("yyyymm");
    "TRANSLATION_IN_USE_UNTIL 6"  6 DateFormat("yyyymm")])

# Used to use a tibble, now use julia vectors...
#    ~FieldName,~Length,~Type,
file_format = DataFrame(["PSEUDO_ID" 9 Int;
    "EMPLOYEE_NAME" 23 String;
    "FILE_DATE" 8  DateFormat("yyyymmdd");
    "AGENCY" 2 String;
    "SUB_AGENCY" 2 String;
    "DUTY_STATION" 9 String;
    "AGE" 6 String;
    "EDUCATION_LEVEL" 2 String;
    "PAY_PLAN" 2 String;
    "GRADE" 2 String;
    "LOS_LEVEL" 6 String;
    "OCCUPATION" 4 String;
    "OCCUPATIONAL_CATEGORY" 1 String;
    "ADJUSTED_BASIC_PAY" 6 Int;
    "SUPERVISORY_STATUS" 1 String;
    "TYPE_OF_APPOINTMENT" 2 String;
    "WORK_SCHEDULE" 1 String;
    "NSFTP_IND"  1 String])

#file = raw"C:\Users\matth\OneDrive\Documents\julia\FWF\test\testfiles\Status_Non_DoD_1981_03.txt"
#FWF.read(file, convert(Array{Int},OPMFedFormat[:x2]), 
#        header=convert(Array{String}, OPMFedFormat[:x1]), types=convert(Array{Union{Type, DateFormat}},OPMFedFormat[:x3]), 
#        missings=naValues)

#FWF.read(IOBuffer("abc12310102017\ndef45610112017\n"), [3,3,8], types=[String,Int,DateFormat("mmddyyyy")])

# This function will parse and return a tibble of a file with the assumption it is a FedScope fixed width 
# file.  Results will be unknown if the file is not a FedScope fixed width file.
# This function also has the ability to expand collapsed fields using helper functions.
# Parameters:
# path: The path to the file that will be read.
# post2014: boolean flag that signals the file is after 2014 and thus contains "Years Since Degree"
# incYearsSinceDegree: Will include the years since degree column as NA if not present.
function opm_parse_fwf(path, incYearsSinceDegree = true) 
    # removed post 2014, files we deal with were always pre-2014
    data = file_format

    #colsObj = mapply(function(x, y) { y }, pull(data, FieldName), pull(data, Type), SIMPLIFY = FALSE, USE.NAMES = TRUE)
    result = FWF.read(path, convert(Array{Int},data[:x2]),
        header=convert(Array{String}, data[:x1]), types=convert(Array{Union{Type, DateFormat}},data[:x3]), missings=naValues)
    #if (incYearsSinceDegree)
    #    result = result %>% add_column(`YEARS SINCE DEGREE` = NA, .after = "AGE") %>% mutate(`YEARS SINCE DEGREE` = as.integer(`YEARS SINCE DEGREE`))
    #    end
    return result 
end

# This function will read in the cpdf format file named sctdata.  This is a static data table of 
# normalized values from the main dataset.  
function opm_parse_sctfile_fwf(path)
    data = CPDFStandardFormat
    # Ugly line of code to convert a tbl to parameter list
    #colsObj <- mapply(function(x, y) { y }, pull(data, FieldName), pull(data, Type), SIMPLIFY = FALSE, USE.NAMES = TRUE)
    result = FWF.read(path, convert(Array{Int},data[:x2]),
        header=convert(Array{String}, data[:x1]), types=convert(Array{Union{Type, DateFormat}},data[:x3]), missings=naValues)
    return result
end
# sct = opm_parse_sctfile_fwf(raw"C:\Users\matth\Desktop\data\1973-09-to-2014-06\SCTFILE.TXT")