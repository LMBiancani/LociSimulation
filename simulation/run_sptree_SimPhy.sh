simphyPath="/home/alex/tools/SimPhy_1.0.2/bin/simphy_lnx64"
#10 species
#low ILS, low deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.000001 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 12345 -o sptree_10_b_10k
#low ILS, high deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.000005 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 14325 -o sptree_10_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.000001 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 54321 -o sptree_10_b_10m
#high ILS, high deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.000005 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 52341 -o sptree_10_bd_10m

#50 species
#low ILS, low deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.000001 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 12345 -o sptree_50_b_10k
#low ILS, high deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.000005 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 14325 -o sptree_50_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.000001 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 54321 -o sptree_50_b_10m
#high ILS, high deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.000005 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 52341 -o sptree_50_bd_10m

#100 species
#low ILS, low deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.000001 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 12345 -o sptree_100_b_10k
#low ILS, high deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.000005 -sp f:10000 -rl f:1 -su ln:-21.9,0.1 -cs 14325 -o sptree_100_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.000001 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 54321 -o sptree_100_b_10m
#high ILS, high deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.000005 -sp f:10000000 -rl f:1 -su ln:-21.9,0.1 -cs 52341 -o sptree_100_bd_10m