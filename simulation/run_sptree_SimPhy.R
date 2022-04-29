set.seed(12345)
exec_path <- "~/tools/SimPhy_1.0.2/bin/simphy_lnx64"
ndatasets <- 46
dsdf <- data.frame(dsname=paste0("ds_",as.character(1:ndatasets)))
dsdf$taxnum <- sample(80:120, ndatasets, replace=T)
dsdf$treeage <- sample(75:435, ndatasets, replace=T)*1000000
dsdf$gentime <- sample(5:20, ndatasets, replace=T)
lineageRateCoef <- round(runif(ndatasets,min=1.0,max=2.5),1)
dsdf$birthRate <- lineageRateCoef/(dsdf$treeage/dsdf$gentime)
dsdf$deathRate <- dsdf$birthRate
dsdf$Ne <- sample(c(1000,10000,100000), ndatasets, replace=T)
dsdf$seed1 <- 10005:(10005-1+ndatasets)
dsdf$seed2 <- 20005:(20005-1+ndatasets)
write.csv(dsdf,"dsdf.csv")
#need to replace random trees with the actual trees?
for (f in 1:ndatasets){
	cmdSimphy <- paste0(exec_path,
						" -sl f:",dsdf$taxnum[f],
						" -sb f:",dsdf$birthRate[f],
						" -sd f:",dsdf$deathRate[f],
						" -sp f:",dsdf$Ne[f],
						" -st f:",dsdf$treeage[f],
						" -sg f:",dsdf$gentime[f],
						" -cs ",dsdf$seed1[f],
						" -o ",dsdf$dsname[f],
						" -rl f:1 -rs 1")
	# print (cmdSimphy)
	system(cmdSimphy)
	write(c(dsdf$seed2[f],dsdf$Ne[f]),paste0(dsdf$dsname[f],"/generate_params.txt"))
}
