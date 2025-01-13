#H-statistic plots - RF
#Christoph Molnar discusses in his interpretable ML book
#blog.macuyiko.com/

library(ape)
library(ggtree)
library(phangorn)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(grid)
library(phytools)
library(cowplot)
library(plyr)
library(dplyr)
library(ggplotify)
library(ggstance)
library(rsvg)

hstat1stdf <- read.csv("../4_model_training/RF_model/first_order_H_vals.csv")
colnames(hstat1stdf)[2] <- "hvals"
hstat2nddf <- read.csv("../4_model_training/RF_model/second_order_H_vals.csv")
colnames(hstat2nddf) <- c("combinations", "hvals")
p4_1 <- ggplot(hstat1stdf) +
  geom_barh(aes(x=hvals, y=features), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11)) +
  xlab("First-order H-statistic")

p4_2 <- ggplot(hstat2nddf[1:10,]) +
  geom_barh(aes(x=hvals, y=reorder(combinations, hvals)), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11),
        axis.title.x = element_text(size=10)) +
  xlab("Second-order H-statistic for top 10 combinations") +
  ylab("combinations")

#### INTERACTION PLOTS from the python - adjust paths and names accordingly
library(rsvg)
library(grImport2)

#RF int1
rsvg_svg("../4_model_training/RF_model/average_support x base_composition_variance.svg", "p4_3pre.svg")
p4_3pre <- readPicture("p4_3pre.svg")
p4_3 <- grobify(p4_3pre)
#RF int2
rsvg_svg("../4_model_training/RF_model/average_support x saturation_slope.svg", "p4_4pre.svg")
p4_4pre <- readPicture("p4_4pre.svg")
p4_4 <- grobify(p4_4pre)
#RF int3
rsvg_svg("../4_model_training/RF_model/tree_rate x tree_rate_var.svg", "p4_5pre.svg")
p4_5pre <- readPicture("p4_5pre.svg")
p4_5 <- grobify(p4_5pre)
#RF int4
rsvg_svg("../4_model_training/RF_model/tree_rate_var x percent_missing.svg", "p4_6pre.svg")
p4_6pre <- readPicture("p4_6pre.svg")
p4_6 <- grImport2::grobify(p4_6pre)

grob <- grid.arrange(p4_1, p4_2, p4_3, p4_4, p4_5, p4_6,
            ncol=2, nrow =3, layout_matrix=rbind(c(1,1,2,2),
                                                 c(3,4,5,6)))

ggsave(grob, "figure_4.png")

#1200x500


hstat1stdf <- read.csv("../4_model_training/wRF_model/first_order_H_vals.csv")
colnames(hstat1stdf)[2] <- "hvals"

hstat2nddf <- read.csv("../4_model_training/wRF_model/second_order_H_vals.csv")
colnames(hstat2nddf) <- c("combinations", "hvals")
p5_1 <- ggplot(hstat1stdf) +
  geom_barh(aes(x=hvals, y=features), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11)) +
  xlab("First-order H-statistic")

p5_2 <- ggplot(hstat2nddf[1:10,]) +
  geom_barh(aes(x=hvals, y=reorder(combinations, hvals)), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11),
        axis.title.x = element_text(size=10)) +
  xlab("Second-order H-statistic for top 10 combinations") +
  ylab("combinations")


#### INTERACTION PLOTS from the python - adjust paths and names accordingly
#wRF int1
rsvg_svg("../4_model_training/wRF_model/average_support x occupancy.svg", "p5_3pre.svg")
p5_3pre <- readPicture("p5_3pre.svg")
p5_3 <- grobify(p5_3pre)
#wRF int2
rsvg_svg("../4_model_training/wRF_model/average_support x percent_variable.svg", "p5_4pre.svg")
p5_4pre <- readPicture("p5_4pre.svg")
p5_4 <- grobify(p5_4pre)
#wRF int3
rsvg_svg("../4_model_training/wRF_model/tree_rate x tree_rate_var.svg", "p5_5pre.svg")
p5_5pre <- readPicture("p5_5pre.svg")
p5_5 <- grobify(p5_5pre)
#wRF int4
rsvg_svg("../4_model_training/wRF_model/tree_rate_var x saturation_rsq.svg", "p5_6pre.svg")
p5_6pre <- readPicture("p5_6pre.svg")
p5_6 <- grImport2::grobify(p5_6pre)

grob <- grid.arrange(p5_1, p5_2, p5_3, p5_4, p5_5, p5_6,
             ncol=2, nrow =3, layout_matrix=rbind(c(1,1,2,2),
                                                  c(3,4,5,6)))

ggsave (grob, "figure_5.png")
#1200x500

