rm(list=ls())

library(dplyr)
library(plyr)
library(sqldf)
library(lazyeval)

# for raw data qc
path_rawDt <- "../../fromJiajing/output/"

dataDetail <- read.csv(file=paste0(path_rawDt, 'Detailing.csv')
                       , header = T
                       , stringsAsFactors = F
                       )

dataMeet <- read.csv(file=paste0(path_rawDt, 'Meeting.csv')
                       , header = T
                       , stringsAsFactors = F
)

dataMail <- read.csv(file=paste0(path_rawDt, 'Mailing.csv')
                       , header = T
                       , stringsAsFactors = F
)

dataOneKey <- read.csv(file=paste0(path_rawDt, 'onekey_hosp.csv')
                     , header = T
                     , stringsAsFactors = F
)

spec_ref <- read.csv(file=paste0(path_rawDt, "spec_ref.csv")
                     , header = T
                     , stringsAsFactors = F
                     )




dim(dataDetail) #[1] 1321075      19

dim(dataMeet) #[1] 54479    19

dim(dataMail) #[1] 9333   18

dim(dataOneKey) #[1] 8230    5

length(unique(dataOneKey$usrtvf)) #[1] 7607

names(dataDetail) <- gsub("\\.", "_", names(dataDetail))
names(dataMail) <- gsub("\\.", "_", names(dataMail))
names(dataMeet) <- gsub("\\.", "_", names(dataMeet))

dataDetail$Related_date <- as.Date(dataDetail$Related_date, "%Y/%m/%d")
dataMail$Related_date <- as.Date(dataMail$Related_date, "%m/%d/%Y")
dataMeet$Related_date <- as.Date(dataMeet$Related_date, "%m/%d/%Y")

# sort the promo data as onekey & date
dataDetailSort <- plyr::arrange(dataDetail, OneKey_ID, Related_date)
dataMailSort <- plyr::arrange(dataMail, OneKey_ID, Related_date)
dataMeetSort <- plyr::arrange(dataMeet, OneKey_ID, Related_date)

names(dataDetailSort) <- tolower(names(dataDetailSort))
names(dataMailSort) <- tolower(names(dataMailSort))
names(dataMeetSort) <- tolower(names(dataMeetSort))

# missing check
is.missing <- function(x)x=="" | is.na(x)
misingCheckDetail <- apply(apply(dataDetailSort, 2, is.missing), 2, sum) %>% .[.>0]
misingCheckMail <- apply(apply(dataMailSort, 2, is.missing), 2, sum) %>% .[.>0]
misingCheckMeet <- apply(apply(dataMeetSort, 2, is.missing), 2, sum) %>% .[.>0]

features <- union(names(misingCheckDetail), names(misingCheckMail)) %>%
  union(., names(misingCheckMeet))

missingDf <- cbind.data.frame(misingCheckDetail=misingCheckDetail[match(features, names(misingCheckDetail))]
                   , misingCheckMail=misingCheckMail[match(features, names(misingCheckMail))]
                   , misingCheckMeet=misingCheckMeet[match(features, names(misingCheckMeet))])

row.names(missingDf) <- features

timeStamp <- as.character(Sys.time())
timeStamp <- gsub(":", ".", timeStamp)  # replace ":" by "."
resultDir <- paste("../../03 Results/", timeStamp, "/", sep = '')
dir.create(resultDir, showWarnings = TRUE, recursive = TRUE, mode = "0777")

write.csv(missingDf
          , file=paste0(resultDir, 'missingCheck.csv')
          , row.names = T)


# for jiajing the list of missing onekey_id
dataDetailSort_missingOnekey <- dataDetailSort %>% filter(onekey_id == "")
checkPhyWithMissingOnekey <- function(data){
  dataSort_missingOnekey_phy <- data %>% 
    mutate(bMissing=(onekey_id=="")) %>%
    group_by(user) %>%
    dplyr::summarise(n.missingOnekey=sum(bMissing)) %>%
    filter(n.missingOnekey>0)
  return(dataSort_missingOnekey_phy)  
}

PhyListWithMissingOnekey_detail <- checkPhyWithMissingOnekey(dataDetailSort)
PhyListWithMissingOnekey_Mail <- checkPhyWithMissingOnekey(dataMailSort)
PhyListWithMissingOnekey_Meet <- checkPhyWithMissingOnekey(dataMeetSort)

write.csv(PhyListWithMissingOnekey_detail
          , file=paste0(resultDir, 'PhyListWithMissingOnekey_detail.csv')
          , row.names = F)
write.csv(PhyListWithMissingOnekey_Mail
          , file=paste0(resultDir, 'PhyListWithMissingOnekey_Mail.csv')
          , row.names = F)
write.csv(PhyListWithMissingOnekey_Meet
          , file=paste0(resultDir, 'PhyListWithMissingOnekey_Meet.csv')
          , row.names = F)




# check the units in hosptital & year &  month level
dataDetailSortByHspDt <- dataDetailSort %>%
  group_by(onekey_id, related_date) %>%
  dplyr::summarise(cnt=n())

monthNumCheckByHsp <- dataDetailSortByHspDt%>%
  group_by(onekey_id) %>%
  dplyr::summarise(n.month=n())

hist(monthNumCheckByHsp$n.month)


# check the units in specialty & year & month level
# detail
# varVal1 <- lazyeval::interp(~g_var, g_var=as.name(spec_var))

checkMonthNumBySpecDt <- function(data, seg_var, date_var){
  group_levels <- c(seg_var, date_var)
  dataSortBySegDt <- data %>%
    group_by_(.dots=group_levels) %>%
    dplyr::summarise(cnt=n())
  
  monthNumCheckBySeg <- dataSortBySegDt %>%
    group_by(.dots=seg_var) %>%
    dplyr::summarise(n.month=n())
  
  return(monthNumCheckBySeg)
}

monthNumCheckBySeg_detail_spec <- checkMonthNumBySpecDt(dataDetailSort, 'promo_specialty', 'related_date')
monthNumCheckBySeg_Mail_spec <- checkMonthNumBySpecDt(dataMailSort, 'speciality', 'related_date')
monthNumCheckBySeg_Meet_spec <- checkMonthNumBySpecDt(dataMeetSort, 'speciality', 'related_date')
monthNumCheckBySeg_detail_hosp <- checkMonthNumBySpecDt(dataDetailSort, 'onekey_id', 'related_date')
monthNumCheckBySeg_Mail_hosp <- checkMonthNumBySpecDt(dataMailSort, 'onekey_id', 'related_date')
monthNumCheckBySeg_Meet_hosp <- checkMonthNumBySpecDt(dataMeetSort, 'onekey_id', 'related_date')

# check the department_id in three promo file
lapply(list(dataDetailSort, dataMailSort, dataMeetSort), function(X)table(X[, 'department_code']))


# check the specialty level
spec_b=unique(dataDetailSort$promo_specialty)
spec_a=spec_ref$Specialty

matchSpec <- function(a, b, n_heads){
  heads <- substr(a, 1, n_heads)
  b_matched <- grep(paste0("^", heads), b, value = T, ignore.case = T, perl=T)
  b_matched <- ifelse(length(b_matched)==0, NA, b_matched)
  return(b_matched)
}

matched = unlist(lapply(spec_a, function(X)matchSpec(X, spec_b, 3)))

matched_res <- data.frame(spec_reference=spec_a, spec_details=spec_b, spec_matched_withRef=matched)

write.csv(matched_res
          , file = paste0(resultDir, 'spec_matched.csv')
          , row.names = F)

matched_withManualChange <- read.csv(file=paste0(resultDir, 'spec_matched_withManualChange.csv')
                                     , header = T
                                     , stringsAsFactors = F
                                     )
spec_a <- matched_withManualChange$spec_reference.manual_change.
spec_b <- matched_withManualChange$spec_details
matched_2 = unlist(lapply(spec_a, function(X)matchSpec(X, spec_b, 3)))
matched_res_2 <- data.frame(spec_reference=spec_a
                            , spec_details=spec_b
                            , spec_matched_withRef=matched_2
                            )

