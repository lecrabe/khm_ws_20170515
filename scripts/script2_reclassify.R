####################################################################################
#######    object: RECLASSIFY SHAPEFILES                        ####################
#######    Update : 2017/05/15                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################


#################### READ STATISTICS AND RESEPARATE EACH DATE COMPONENT
df <- read.table("stats_change.txt")[,1:2]
names(df) <- c("chg_code","pix_count")

df$code14 <- as.numeric(substr(as.character(10000 + df$chg_code),2,3))
df$code16 <- as.numeric(substr(as.character(10000 + df$chg_code),4,5))

#################### READ CODE/CLASS CONVERSION TABLE
code_class <- read.csv("code_class_agg.csv")

df1 <- merge(df,code_class[,c("code","class","ipcc_code","ipcc_class")],by.x="code14",by.y="code",all.x=T)
names(df1) <- c("code14","chg_code" ,"pix_count","code16","class14","ipcc_code_14","ipcc_class_14")

df1 <- merge(df1,code_class[,c("code","class","ipcc_code","ipcc_class")],by.x="code16",by.y="code",all.x=T)
names(df1) <- c("code16","code14","chg_code" ,"pix_count","class14","ipcc_code_14","ipcc_class_14","class16","ipcc_code_16","ipcc_class_16")

df1$ipcc_chge <- df1$ipcc_code_14 *10 + df1$ipcc_code_16

df1$final <- 0
table(df1$ipcc_class_14,df1$ipcc_class_16,useNA = "always")

################## FOREST STABLE
df1[df1$ipcc_class_14 == "F" & df1$ipcc_class_16 == "F",]$final <- 1

################## NON FOREST STABLE
df1[df1$ipcc_class_14 != "F" & df1$ipcc_class_16 != "F",]$final <- 2

################## FOREST LOSS
df1[df1$ipcc_class_14 == "F" & df1$ipcc_class_16 != "F",]$final <- 3

################## FORET GAINS
df1[df1$ipcc_class_14 != "F" & df1$ipcc_class_16 == "F",]$final <- 4

################## EVERGREEN LOSS TOWARDS AGRICULTURE
df1[df1$class14 == "E" & df1$class16 == "Hc",]$final <- 5

################## PLANTATIONS
df1[df1$class14 == "Tp" & df1$class16 == "Tp",]$final <- 6



table(df1$final)

write.table(df1[,c("chg_code","final")],"reclass.txt",sep = " ",row.names = F,col.names = F)
write.csv(df1,"all_transitions.csv",row.names = F)


#################### RECLASSIFY THE CHANGE RASTER
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s  %s",
               "reclass.txt",
               "tmp_ipcc_1416.tif",
               "change_1416.tif"
))

#################### COMPRESS RESULTS
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               "tmp_ipcc_1416.tif",
               "ipcc_1416_Tp_EHc.tif"))

#################### DELETE TEMP FILES
system(sprintf(paste0("rm tmp*.tif")))

