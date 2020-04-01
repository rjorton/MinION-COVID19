options(scipen=999)

params <- commandArgs(trailingOnly = TRUE)

ampFile<-params[1]
sampleName<-params[2]

ampData <- read.table(ampFile, header = TRUE, sep="\t")
outName<-paste(sampleName,"_amplicons.png",sep="")

maxCov<-max(ampData$Average.Cov, na.rm = TRUE)

png(filename=outName, units="px", width=2500, height=1000, pointsize=12)
par(mar=c(13,8,5,2))
labels<-as.numeric(rownames(ampData))
barplot(ampData$Average.Cov, ylim=c(1,maxCov), main=sampleName, horiz=FALSE, log="y", names.arg=labels, las=2, col=c("grey"), cex.axis=1.3, cex.names=1.3, cex.main=3)

# x axis
mtext(text = "Amplicon Number",
      lwd = 3,
      side = 1, #side 1 = bottom
      line = 5, 
      cex=3)

# y axis
mtext(text = "Average Depth",
      lwd = 3,
      side = 2, #side 2 = left
      line = 5,
      cex=3)

dev.off()
