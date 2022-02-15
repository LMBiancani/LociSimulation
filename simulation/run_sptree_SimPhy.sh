simphyPath="/home/alex/tools/SimPhy_1.0.2/bin/simphy_lnx64"
#10 species
#low ILS, low deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.0000075 -sp f:10000 -st f:1000000 -rl f:1 -cs 12345 -o sptree_10_b_10k
#low ILS, high deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.00001 -sp f:10000 -st f:1000000 -rl f:1 -cs 14325 -o sptree_10_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.0000075 -sp f:100000 -st f:1000000 -rl f:1 -cs 54321 -o sptree_10_b_100k
#high ILS, high deathrate
${simphyPath} -sl f:10 -sb f:0.00001 -sd f:0.00001 -sp f:100000 -st f:1000000 -rl f:1 -cs 52341 -o sptree_10_bd_100k

#50 species
#low ILS, low deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.0000075 -sp f:10000 -st f:1000000 -rl f:1 -cs 12345 -o sptree_50_b_10k
#low ILS, high deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.00001 -sp f:10000 -st f:1000000 -rl f:1 -cs 14325 -o sptree_50_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.0000075 -sp f:100000 -st f:1000000 -rl f:1 -cs 54321 -o sptree_50_b_100k
#high ILS, high deathrate
${simphyPath} -sl f:50 -sb f:0.00001 -sd f:0.00001 -sp f:100000 -st f:1000000 -rl f:1 -cs 52341 -o sptree_50_bd_100k

#100 species
#low ILS, low deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.0000075 -sp f:10000 -st f:1000000 -rl f:1 -cs 12345 -o sptree_100_b_10k

#low ILS, high deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.00001 -sp f:10000 -st f:1000000 -rl f:1 -cs 14325 -o sptree_100_bd_10k
#high ILS, low deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.0000075 -sp f:100000 -st f:1000000 -rl f:1 -cs 54321 -o sptree_100_b_100k
#high ILS, high deathrate
${simphyPath} -sl f:100 -sb f:0.00001 -sd f:0.00001 -sp f:100000 -st f:1000000 -rl f:1 -cs 52341 -o sptree_100_bd_100k
