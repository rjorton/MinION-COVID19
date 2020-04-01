options(scipen=999)

params <- commandArgs(trailingOnly = TRUE)

covFile<-params[1]
sampleName<-params[2]

covData <- read.table(covFile, header = FALSE, sep="\t")

maxCov<-max(covData$V3, na.rm = TRUE)
minCov<-min(covData$V3, na.rm = TRUE)
meanCov<-mean(covData$V3, na.rm = TRUE)

medianCov<-median(covData$V3, na.rm = TRUE)
quants<-quantile(covData$V3)

genomeName<-covData$V1[1]
genomeLength<-max(covData$V2, na.rm = TRUE)
zeroCov<-sum(covData$V3 == 0)
breadth<-(genomeLength-zeroCov)/genomeLength*100

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

mtext(text = paste("Mean coverage = ",as.integer(meanCov), " [min=", minCov, " : max=", maxCov, "], breadth = ", breadth, "%", ", positions with zero coverage = ", zeroCov, sep=""),
      lwd = 3,
      side = 1,
      line = 7,
      cex=1.5)

mtext(text = paste("Median coverage = ", as.integer(medianCov), " inter-quartile range = [", as.integer(quants[2]), "-", as.integer(quants[4]),"]",sep=""),
      lwd = 3,
      side = 1,
      line = 9,
      cex=1.5)

mtext(text = paste("Reference genome = ",genomeName, ", length = ", genomeLength, ", input file = ",covFile,sep=""),
      lwd = 3,
      side = 1,
      line = 11,
      cex=1.5)

dev.off()
