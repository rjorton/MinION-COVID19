options(scipen=999)

params <- commandArgs(trailingOnly = TRUE)

ampFile<-params[1]
sampleName<-params[2]

ampData <- read.table(ampFile, header = TRUE, sep="\t")
outName<-paste(sampleName,"_amplicon_comparison.png",sep="")


maxCov<-max(ampData$ArticV3, na.rm = TRUE)
maxCov2<-min(ampData$CL, na.rm = TRUE)

if (maxCov2>maxCov) {
  maxCov=maxCov2
}

png(filename=outName, units="px", width=2500, height=1000, pointsize=12)
par(mar=c(13,8,5,2))
labels<-as.numeric(rownames(ampData))
barplot(t(as.matrix(ampData)), ylim=c(1,maxCov), beside=TRUE, main=sampleName, horiz=FALSE, log="y", names.arg=labels, las=2, col=c("black","grey"), cex.axis=1, cex.names=1, cex.main=3)

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

mtext(text = paste("Black = ARTIC-V3 ... and ... Grey = CL", sep=""),
      lwd = 3,
      side = 1,
      line = 7,
      cex=1.5)

dev.off()
