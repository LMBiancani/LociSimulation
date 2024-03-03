# A script to generate folders with different
# species tree datasets.
#
# Each folder will have a simulated species tree
# and parameters needed to simulate loci
#
# Folders are generated in the working dir
# Be sure to adjust path to SimPhy
#
set.seed(12345)
#adjust the path to SimPhy. Installation instructions for SimPhy can be found at https://github.com/adamallo/SimPhy/wiki/Manual
exec_path <- "/data/schwartzlab/awalling/tools/SimPhy_1.0.2/bin/simphy_lnx64"
ndatasets <- 46 #script simulated 46, but only 16 were used
dsdf <- data.frame(dsname=paste0("ds_",as.character(1:ndatasets)))
dsdf$taxnum <- sample(80:120, ndatasets, replace=T)
dsdf$treeage <- sample(75:435, ndatasets, replace=T)*1000000 #in My
dsdf$gentime <- sample(5:20, ndatasets, replace=T) #in years
lineageRateCoef <- round(runif(ndatasets,min=1.0,max=2.5),1)
dsdf$birthRate <- lineageRateCoef/(dsdf$treeage/dsdf$gentime)
dsdf$deathRate <- dsdf$birthRate
dsdf$Ne <- sample(c(1000,10000,100000), ndatasets, replace=T)
dsdf$seed1 <- 10005:(10005-1+ndatasets)
dsdf$seed2 <- 20005:(20005-1+ndatasets)
write.csv(dsdf,"dsdf.csv")
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
	system(cmdSimphy)
	write(c(dsdf$seed2[f],dsdf$Ne[f]),paste0(dsdf$dsname[f],"/generate_params.txt"))
}
