options(scipen=999)

params <- commandArgs(trailingOnly = TRUE)

covFile<-params[1]
covFile2<-params[2]
sampleName<-params[3]

covData <- read.table(covFile, header = FALSE, sep="\t")
covData2 <- read.table(covFile2, header = FALSE, sep="\t")

maxCov<-max(covData$V3, na.rm = TRUE)
minCov<-min(covData$V3, na.rm = TRUE)

maxCov2<-max(covData$V3, na.rm = TRUE)
minCov2<-min(covData$V3, na.rm = TRUE)

if (maxCov2>maxCov) {
  maxCov=maxCov2
}
if (minCov2>minCov) {
  minCov=minCov2
}

genomeName<-covData$V1[1]
genomeLength<-max(covData$V2, na.rm = TRUE)

yaxisMax<-maxCov
if (maxCov > 1000000) {
	yaxisMax=10000000
	labs<-c(1,10,100,1000,10000,100000,1000000,10000000)
} else if (maxCov > 100000) {
	yaxisMax<-1000000
	labs<-c(1,10,100,1000,10000,100000,1000000)
} else if (maxCov > 10000) {
	yaxisMax<-100000
	labs<-c(1,10,100,1000,10000,100000)
} else if (maxCov > 1000) {
	yaxisMax<-10000
	labs<-c(1,10,100,1000,10000)
} else if (maxCov > 100) {
	yaxisMax<-1000
	labs<-c(1,10,100,1000)
} else if (maxCov > 10) {
	yaxisMax<-100
	labs<-c(1,10,100)
} else {
	yaxisMax<-10
	labs<-c(1,10)
}

outName<-paste(sampleName,"_coverage.png",sep="")

png(filename=outName, units="px", width=2500, height=1000, pointsize=12)
par(mar=c(13,8,5,2))
#plot(covData$V2, covData$V3, bty="n", lwd=3, xlab="", ylab="", main=covFile, type="l", col="black", cex.axis=2, cex.main=3)
plot(covData$V2, covData$V3, bty="n", lwd=3, xlab="", ylab="", ylim=c(1,yaxisMax), log="y", main=sampleName, type="l", col="black", cex.axis=2, cex.main=3)
lines(covData2$V2, covData2$V3, lwd=3, col="grey")
axis(side=1,lwd=4, labels=FALSE)
axis(side=2,lwd=4, at=labs, cex.axis=2, labels=labs)

# x axis
mtext(text = "Genome Position",
      lwd = 3,
      side = 1, #side 1 = bottom
      line = 5, 
      cex=3)

# y axis
mtext(text = "Depth",
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
