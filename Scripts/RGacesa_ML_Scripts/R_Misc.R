# =========================================================
# by R.Gacesa (UMCG, 2019)
#
# MISC FUNCTIONS for plotting, microbiome stuff ...
# =========================================================
library(pheatmap)

# summary of one dataframe feature VS response
#TODO: extend to categorical variables
# ========================================================
makeOneSummaryByResponse <- function(inDF,ftr,response,doTestVsControl=T,controlClass="HC",formatSci=F,formatDig=2,formatRoundDig=3) {
  ret = data.frame()
  for (rv in unique(inDF[[response]])) {
    if (class(inDF[[ftr]]) == "numeric") {
      mn <-  mean(inDF[inDF[[response]]==rv,][[ftr]])
      sd <-  sd(inDF[inDF[[response]]==rv,][[ftr]])
      md <-  median(inDF[inDF[[response]]==rv,][[ftr]])
      min <- min(inDF[inDF[[response]]==rv,][[ftr]])
      q1  <- quantile(inDF[inDF[[response]]==rv,][[ftr]])[[2]]
      q3  <- quantile(inDF[inDF[[response]]==rv,][[ftr]])[[4]]
      max <- max(inDF[inDF[[response]]==rv,][[ftr]])
      nr <- sum(inDF[[response]]==rv)
      nonzero <- sum(inDF[inDF[[response]]==rv,][[ftr]]!=0)
      prev <- nonzero/nr
      if (is.na(prev)) {prev = 0.0}
      oneRow <- data.frame(Var=ftr,Group=rv,Mean=mn,SD=sd,Min=min,Q1=q1,Median=md,Q3=q3,Max=max,
                           NR=nr,nonzero=nonzero,prevalence=prev,
                           niceOut=paste0(format(round(md,formatRoundDig),digits = formatDig,scientific = formatSci),
                                          ' [',format(round(q1,formatRoundDig),digits = formatDig,scientific = formatSci), '; ',
                                          format(round(q3,formatRoundDig),digits = formatDig,scientific = formatSci) ,']')  )
      if (!doTestVsControl) {
        print(paste0(' > ',response,' = ',rv,'; mean(',ftr,') = ',mn,'; sd = ',sd,'| median = ',md,' Q1 = ',q1,' Q3 = ',q3))
        ret <- rbind.data.frame(ret,oneRow)
      } else {
        if (rv != controlClass) {
          tst <- wilcox.test(inDF[inDF[[response]] == controlClass,][[ftr]],
                             inDF[inDF[[response]] == rv,][[ftr]])
          print(paste0(" TESTING variable ",ftr,", Response variable(",response,") class " ,rv,' VS ',controlClass))
          sigStr = ""
          pV <- tst$p.value
          print(paste0(' > P-value = ',pV))
        } else {
          pV = NA; sig = ""; FDR = NA
        } 
        oneRow$pV <- pV
        ret <- rbind.data.frame(ret,oneRow)
      }
    } else if (class(inDF[[ftr]]) == "factor") {
      
    }
  }
  ret
}

# summary of one dataframe feature VS response
# > wraps makeOneSummaryByResponse, does testing for multiple features
# and does FDR and "nice" output
# > input is same as for
# makeOneSummaryByResponse, but ftrs is vector of variable names
# =====================================================================
makeMultiSummaryByResponse <- function(inDF,ftrs,response,doTestVsControl=T,controlClass="HC",formatSci=F,formatDig=2,formatRoundDig=3,doFDR=T)
{
  ret <- data.frame()
  # debug / reality check
  if (sum(ftrs %in% colnames(inDF)) < length(ftrs)) {
    print(" WARNING: 1 or more feature variables missing from input dataframe (inDF): ")
    for (f in ftrs) {
      if (!(f %in% colnames(inDF))) {
        print(paste0(' > ',f,' is missing!'))
      }
    }
    print('  >> Continuing with remaining features ...')
  }
  for (f in ftrs) {
    ret <- rbind.data.frame(ret,makeOneSummaryByResponse(inDF,f,response,doTestVsControl,
                                                         controlClass,formatSci,
                                                         formatDig,formatRoundDig))
  }
  if (doFDR) {ret$FDR <- p.adjust(ret$pV)}
  else {ret$FDR <- ret$pV}
  ret$FDRfor <- format(ret$FDR,digits = formatDig,scientific = T)
  ret$FDRsig <- as.character(ret$FDR <= 0.05)
  ret$FDRsig[ret$FDR <= 0.05] <- "*"
  ret$FDRsig[ret$FDR <= 1.0e-5] <- "**"
  #ret$FDRsig[ret$FDR <= 1.0e-10] <- "***"
  ret$FDRsig[ret$FDRsig=="FALSE"] <- ""
  ret$FDRsig[is.na(ret$FDRsig)] <- ""
  ret$niceOut <- paste0(ret$niceOut," ",ret$FDRsig)
  ret
}


# ============= makes summary of one vector ==============
# ========================================================
# NOTES:
# > fixer: if T, tries to fix some 'common' problems, such as spaces-only input being counted as valid data
#
#
makeOneSummary <- function(ftr,varName='',fixer=T,infnullIsNA=T,nothingIsNA=T,nrClassesToList=5) {
  ret = data.frame()
  if (fixer) {
    backToFac <- F
    if (class(ftr) == "factor") {
      ftr <- as.character(ftr)
      backToFac <- T
      ftr <- trimws(ftr)
      ftr[ftr == " "] <- ""
      ftr[ftr == "  "] <- ""
      ftr[ftr == "   "] <- ""
      ftr[ftr == "    "] <- ""
      ftr[ftr == "     "] <- ""
      ftr[ftr == "na"] <- NA
      ftr[ftr == "n/a"] <- NA
      ftr[ftr == "NA"] <- NA
      ftr[ftr == "N/A"] <- NA
      if (infnullIsNA) {
        ftr[ftr == "null"] <- NA
        ftr[ftr == "inf"] <- NA
        ftr[ftr == "NULL"] <- NA
        ftr[ftr == "INF"] <- NA
        ftr[is.infinite(ftr)] <- NA
        ftr[is.null(ftr)] <- NA
      }
      if (nothingIsNA) {
        ftr[ftr == ""] <- NA
      }
      ftr <- as.factor(ftr)
    }
    if (class(ftr) == "integer") {
      ftr <- as.numeric(ftr)
    }
    if (class(ftr) == "numeric") {
      if (infnullIsNA) {
        ftr[is.infinite(ftr)] <- NA
        ftr[is.null(ftr)] <- NA
      }
    }
  }
  if (class(ftr) == "numeric") {
      mn <-  mean(ftr,na.rm = T)
      sd <-  sd(ftr,na.rm = T)
      md <-  median(ftr,na.rm = T)
      min <- min(ftr,na.rm = T)
      q1  <- quantile(ftr,na.rm = T)[[2]]
      q3  <- quantile(ftr,na.rm = T)[[4]]
      max <- max(ftr,na.rm = T)
      nr <- length(ftr)
      nonzero <- sum(ftr!=0,na.rm = T)
      prev <- nonzero/nr
      nas <- sum(is.na(ftr))
      naprev <- nas/nr
      if (is.na(prev)) {prev = 0.0}
      if (is.na(naprev)) {naprev = 0.0}
      ret <- data.frame(Var=varName,dataType=class(ftr),NR=nr,Mean=mn,SD=sd,Min=min,Q1=q1,Median=md,Q3=q3,Max=max,
                        NrNonZero=nonzero,propNonZero=prev,NrNAs=nas,propNAs=naprev)
      
  } else if (class(ftr) == "factor") {
    nr <- length(ftr)
    nas <- sum(is.na(ftr))
    naprev <- nas/nr
    something <- sum(!is.na(ftr))
    somethingPrev <- something/nr
    nrClasses <- length(levels(ftr))
    if (is.na(somethingPrev)) {somethingPrev = 0.0}
    if (is.na(naprev)) {naprev = 0.0}
    ret <- data.frame(Var=varName,dataType=class(ftr),NR=nr,NrClasses=nrClasses,  
                      NrNonNA=something,propNonNA=somethingPrev,
                      NrNAs=nas,propNAs=naprev)
    if (nrClassesToList > 0) {
      ftrNRs <- as.data.frame(table(ftr))
      ftrNRs <- ftrNRs[order(ftrNRs$Freq,decreasing = T),]
      for (nrC in c(1:nrClassesToList)) {
        if (nrC <= nrow(ftrNRs)) {
          toAddDF <- data.frame(A=ftrNRs$ftr[nrC],
                               B=ftrNRs$Freq[nrC],
                               C=ftrNRs$Freq[nrC]/nr)
          
        } else {
          toAddDF <- data.frame(A=NA,B=NA,C=NA)
        }
        colnames(toAddDF) <- c(paste0('C_',nrC,'_VALUE'),paste0('C_',nrC,'_NR'),paste0('C_',nrC,'_Prop'))
        ret <- cbind.data.frame(ret,toAddDF)
      }
    }
  }
  ret
}

# count taxa & pwys
# ===================================
countMicrobiomeFeatures <- function(inDF) {
  res <- data.frame()
  taxa <- purgeMGNames(subsetMicrobiomeDF(inDF = inDF,verbose = F,getTaxa = T,getPWYs = F,getVFs = F,getCARDs = F,getPhenos = F,getDivs = F))
  sumTaxa <- 0
  print ('---- TAXA -----------------------')
  for (tn in c("t__","s__","g__","f__","c__","o__","p__")) {
    nrTaxa <- sum(grepl(paste0("^",tn),colnames(taxa)))
    print(paste0(tn,' NR = ', nrTaxa))
    sumTaxa <- sumTaxa + nrTaxa
  }
  print (paste0(' TOTAL TAXA: ',sumTaxa))
  print ('---------------------------------')
  
  print ('---- PWYs -----------------------')
  pwys <- subsetMicrobiomeDF(inDF = inDF,verbose = F,getTaxa = F,getPWYs = T,getVFs = F,getCARDs = F,getPhenos = F,getDivs = F)
  print (paste0(' TOTAL PWYs: ',length(colnames(pwys))))
  
  taxa <- subsetMicrobiomeDF(inDF = inDF,verbose = F,getTaxa = T,getPWYs = F,getVFs = F,getCARDs = F,getPhenos = F,getDivs = F)
  taxa <- subsetMicrobiomeDF(inDF = inDF,verbose = F,getTaxa = T,getPWYs = F,getVFs = F,getCARDs = F,getPhenos = F,getDivs = F)
  taxa <- subsetMicrobiomeDF(inDF = inDF,verbose = F,getTaxa = T,getPWYs = F,getVFs = F,getCARDs = F,getPhenos = F,getDivs = F)
  
}


# make ordination plot
plotOrdination <- function(inDF,responseVar,doCentroids=F) {
  # ordinate on the distance matrix
  e.sir.pcoa <- cmdscale( data, eig = T )
  
  # variance explained 
  variance <- head(eigenvals(e.sir.pcoa)/sum(eigenvals(e.sir.pcoa)))
  x_variance <- as.integer(variance[1]*100)
  y_variance <- as.integer(variance[2]*100)
  
  # get scores for plotting
  e.sir.scores <- as.data.frame( e.sir.pcoa$points )
  
  # read in metadata file
  e.sir.meta <- read.delim( args_list$args[2], header = T, sep = "\t", row.names = 1 )
  # append to e.sir.scores
  e.sir.scores.meta <- merge( e.sir.scores, e.sir.meta, by = 'row.names' )
  # set first column as rownames and remove it
  rownames( e.sir.scores.meta ) <- e.sir.scores.meta[,1]
  e.sir.scores.meta[,1] <- NULL
  # change colnames
  colnames(e.sir.scores.meta) <- c( "PCo1", "PCo2", "SubjectID" )
  
  # plot ordination
  png( args_list$args[3], width = 750, height = 600, res = 150 )
  
  ggplot( e.sir.scores.meta, aes(PCo1, PCo2, color=SubjectID) ) + 
    geom_point(size = 4, alpha = 0.75) + theme_classic() + 
    theme(axis.line.x = element_line(colour = 'black', size=0.75, linetype='solid'),
          axis.line.y = element_line(colour = 'black', size=0.75, linetype='solid'),
          axis.ticks = element_blank(), axis.text = element_blank()) + 
    xlab(paste("PCo1 (",x_variance,"% variance explained)")) + ylab(paste("PCo2 (",y_variance,"% variance explained)"))
  
  temp <- dev.off()
}


# cute cute function for PCA plotting regression plotting
# takes pcas table and responsevar (has to be in pcas dataset)
# ===========================================
plotPCAs <- function(pcas,nrPCs=3,responseVar,doCentroids=T) {
  c = 1
  res = list()
  # PC 1-2
  g <- ggplot(pcas ,aes_string(x = "PC1",y="PC2",col=responseVar )) + geom_point(size=2.25,alpha=0.8) 
  pcas$rV <- pcas[[responseVar]]
  if (doCentroids) {
    centroids <- aggregate(cbind(PC1,PC2)~rV,pcas,mean)
    colnames(centroids)[[1]] <- responseVar
    g <- g + geom_point(data=centroids,shape=4,stroke=3,size=5,aes(x=centroids$PC1,y=centroids$PC2),alpha=1)
  }
  res[[c]] <- g
  if (nrPCs >= 3) {
    # PC 2-3
    g <- ggplot(pcas ,aes_string(x = "PC2",y="PC3",col=responseVar )) + geom_point(size=2.25,alpha=0.8) 
    if (doCentroids) {
      centroids <- aggregate(cbind(PC2,PC3)~rV,pcas,mean)
      colnames(centroids)[[1]] <- responseVar
      g <- g + geom_point(data=centroids,shape=4,stroke=3,size=5,aes(x=centroids$PC2,y=centroids$PC3))
    }
    res[[c]] <- g
  }
  if (nrPCs >= 4) {
    # PC 3-4
    g <- ggplot(pcas ,aes_string(x = "PC3",y="PC4",col=responseVar )) + geom_point(size=2.25,alpha=0.4) 
    if (doCentroids) {
      centroids <- aggregate(cbind(PC3,PC4)~rV,pcas,mean)
      colnames(centroids)[[1]] <- responseVar
      g <- g + geom_point(data=centroids,shape=4,stroke=3,size=5,aes(x=centroids$PC3,y=centroids$PC4))
    }
    res[[c]] <- g
  }
  if (nrPCs >= 5) {
    # PC 4-5
    g <- ggplot(pcas ,aes_string(x = "PC4",y="PC5",col=responseVar )) + geom_point(size=2.25,alpha=0.4) 
    if (doCentroids) {
      centroids <- aggregate(cbind(PC4,PC5)~rV,pcas,mean)
      colnames(centroids)[[1]] <- responseVar    
      g <- g + geom_point(data=centroids,shape=4,stroke=3,size=5,aes(x=centroids$PC4,y=centroids$PC5))
    }
    res[[c]] <- g
  }
  # return list of plots
  res
}

# ===========================================
# TSNE plotter
# ===========================================
ggplotTsne <- function(tSNEdf,feature) {
  g <- ggplot(tSNEdf, aes_string(x = "V1",y= "V2",col=feature )) + geom_point(size=2.5,alpha=0.9)
  ref <- reformulate(feature,"cbind(V1,V2)")
  centroids <- aggregate(ref,tSNEdf,mean)
  g <- g + geom_point(data=centroids,shape=4,stroke=3,size=5,aes_string(x="V1",y="V2",col=feature),alpha=1)
  g
}

# ================================================
# function for linear regression plotting
# takes linear model fit as argument
# ===========================================
ggplotRegression <- function (fit) {
  require(ggplot2)
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_point() +
    stat_smooth(method = "lm", col = "blue") +
    labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 2),
                       #"Intercept =",signif(fit$coef[[1]],2 ),
                       " Coef =",signif(fit$coef[[2]], 2),
                       " P =",signif(summary(fit)$coef[2,4], 2)))
}

# tester for linear fit
testsLinearFit <- function(inDF,responseVar,varsToTest,correctors=c(),nonZero=F) {
  tests <- data.frame()
  for (f in varsToTest) {
    inDFt <- inDF
    if (nonZero) {
      inDFt <- inDF[inDF[[f]] > 0,]
    }
    print(paste(' >> testing',f))
    frm <- reformulate(termlabels = c(responseVar,correctors), response = f)
    mdl <- lm(data = inDFt, formula =  frm)
    rs <- summary(mdl)$r.squared
    pv <- summary(mdl)$coefficients[responseVar,4]
    coeff <- summary(mdl)$coefficients[responseVar,1]
    tests <- rbind.data.frame(tests,data.frame(feature=f,rsquared=rs,coef=coeff,pvalue=pv,zeros=sum(inDFt[[f]] == 0),nonzeros=sum(inDFt[[f]] > 0)) )
  }
  tests <- tests[order(tests$pvalue),]
  tests$FDR <- p.adjust(tests$pvalue)
  tests$NonZero <- nonZero
  tests
}

# plotter
plotTestsLM <- function(inDF,tests,responseVarLM,responseVarX,FDRcutoff=0.2,pVcutoff=0.05,pointColVar=NA) {
  testor <- tests$feature[tests$FDR < FDRcutoff & tests$pvalue < pVcutoff]
  testor <- na.omit(testor)
  for (f in testor) {
    print(f)
    xannot = min(inDF[[responseVarLM]])
    yannot = max(inDF[[f]])
    tcoef <- format(tests$coef[tests$feature==f],digits=2)
    tpv <- format(tests$pvalue[tests$feature==f],digits = 2)
    trsq <- format(tests$rsquared[tests$feature==f],digits = 2)
    if (tests$NonZero[[1]]) {
      inDFt <- inDF[inDF[[f]] > 0,]
    } else {
      inDFt <- inDF
    }
    if (class(inDFt[[responseVarX]]) == "factor") {
      g <- ggplot(inDFt) +
        geom_boxplot(aes_string(x=responseVarX,y=f,col=responseVarX),outlier.alpha = 0) +
        geom_jitter(aes_string(x=responseVarX,y=f,col=responseVarX),width=0.2,alpha=0.25) +
        stat_smooth(aes_string(x=responseVarLM,y=f),method="lm",fullrange=F)
    } else if (is.na(pointColVar)) {
      g <- ggplot(inDFt) + geom_point(aes_string(x=responseVarX,y=f,col=responseVarX)) +
        stat_smooth(aes_string(x=responseVarLM,y=f),method="lm",fullrange=F) 
    } else {
      g <- ggplot(inDFt) + geom_point(aes_string(x=responseVarX,y=f,col=pointColVar)) +
        stat_smooth(aes_string(x=responseVarLM,y=f),method="lm",fullrange=F) 
      
    }
    g <- g + annotate(geom="text", y=yannot, hjust = 0, x = -Inf,
                      label=paste0("  LM fit: coef=",tcoef,"; R^2=",trsq,"; P=",tpv) )
    print(g)
  }
}

# color pallete maker
# ================================================
makeColorRampPalette <- function(colors, cutoff.fraction, num.colors.in.palette)
{
  stopifnot(length(colors) == 4)
  ramp1 <- colorRampPalette(colors[1:2])(num.colors.in.palette * cutoff.fraction)
  ramp2 <- colorRampPalette(colors[3:4])(num.colors.in.palette * (1 - cutoff.fraction))
  return(c(ramp1, ramp2))
}

# save pheatmap
# ================================================
save_pheatmap_png <- function(x, filename, width=1200, height=1200, res = 150) {
  png(filename, width = width, height = height, res = res)
  grid::grid.newpage()
  grid::grid.draw(x$gtable)
  dev.off()
}

# AGGREGATOR & PLOTTER for phenotype tests in DAG3
# =======================================================
# - agregates multiple tables and plots nice heatmap

# doFeatures can be: 
# - Abundances : abundances of taxa
# - Prevalences : prevalences of taxa
# - div :    diversity metrics
# - pwyAb :  abundances of PWYs

# NOTE:
# - currently works only on binary features (0 vs 1 OR n vs y)
# - metric should be : statsig, 

aggregatePlotHeatmap <- function(tblFolder,doFeatures=c("Abundances"),nrToPlot=20,outFile="plot.png",pVcutoff=0.05,multiTest=F,
                                 clusterFeatures=T,clusterPhenos=F,subsetFeatures="",subsetPhenos="",
                                 metric="statSig",enrichmentCutoff = 1.005,addXextra=0,addYextra=0,maxMax = 5,
                                 shortenTaxNames=T,invertYN=F) {
  if (!metric %in% c("statSig","meanEffectRatio","medEffectRatio"))  {
    print (" >> metric MUST be one of [statSig, meanEffectRatio, medEffectRatio]")
    break()
  }
  
  print ('>>> AGGREGATING RESULTS:')
  if (multiTest) {
    print (paste0(' doing multiple-testing correction (BH), using FDR = ',pVcutoff))
  } else {
    print (paste0(' using nominal p-value cutoff of ',pVcutoff))
  }

  hmDFsig <- NULL
  hmDFenrich <- NULL
  hmDFdirection <- NULL
  mSS <- 0
  #maxMax <- 5
  # calculate NR of tests
  nrTests <- 0
  if (multiTest) {
    for (f in dir(tblFolder, pattern =".csv")) {
      doParse = F
      for (g in doFeatures) {if (grepl(g,f)) {doParse = T}}
      if (doParse) {
        #print(f)
        iT <- read.table(paste0(tblFolder,'/',f),sep=',',header = T,stringsAsFactors = F)
        #print(nrow(iT))
        if (subsetFeatures != "") {
          iT <- iT[grep(subsetFeatures,iT$feature),]
        }
        if (subsetPhenos != "")  {
          iT <- iT[iT$PHENOTYPE %in% subsetPhenos,]
        }
        nrTests <- nrTests+nrow(iT)
        #print (nrTests)
      }
    }
    print (paste0('  >> doing multiple-testing correction for ',nrTests,' tests!'))
  }
  
  print ('  >>> parsing tables ...')
  for (f in dir(tblFolder, pattern =".csv")) {
    doParse = F
    for (g in doFeatures) {if (grepl(g,f)) {doParse = T}}
    if (doParse) {
      print(f)
      iT <- read.table(paste0(tblFolder,'/',f),sep=',',header = T,stringsAsFactors = F)
      if (shortenTaxNames) {for (r in c(1:nrow(iT))) {iT$feature[r] <- purgeMGNameOne(iT$feature[r])}}
      iT$V1 <- tolower(iT$V1)
      iT$V2 <- tolower(iT$V2)
      if (subsetFeatures != "") {
        iT <- iT[grep(subsetFeatures,iT$feature),]
      }
      if (subsetPhenos != "")  {
        iT <- iT[iT$PHENOTYPE %in% subsetPhenos,]
      }
      if (multiTest) {
        iT$FDR <- p.adjust(iT$pValue,n = nrTests)
      } else {
        iT$FDR <- iT$pValue
      }
      if (!(iT$V2[1] %in% c("y","1","n","0"))) {
        print(paste0('WARNING: table ',f, ' / responseVar ',iT$V2[1],' : responseVar is not categorical 0/1 or n/y, skipping it ...'))
      } else {
        # add row(s) to dataframe
        # > pick what to plot
        if (metric == "statSig") {
          # > statistical significance 
          if (grepl("Prevalences", f)) {
            oneCol <- data.frame(feature=iT$feature,toplot=log(iT$FDR,base = 10)*-1*sign(1/iT$V1toV2-1)); colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          } else {
            oneCol <- data.frame(feature=iT$feature,toplot=log(iT$FDR,base = 10)*sign(iT$V1minusV2)); colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          }
        } else if (metric == "meanEffectRatio") {
          # > mean enrichment / depletion
          if (grepl("Prevalences", f)) {
            # > prevalences
            mS <- iT$V2prop/iT$V1prop
            mS <- mS[!is.na(mS)]; mS <- mS[!is.infinite(mS)]; mSS <- max(mS,mSS)
            eSize <- iT$V2prop/iT$V1prop
            eSize[is.na(eSize)] <- 0
            eSize[eSize == 1] <- 0
            eSize[eSize < 1] <- -1*log(1/eSize[eSize < 1])
            #print (eSize)
            eSize[eSize > 1] <- log(eSize[eSize > 1])
            eSize[is.infinite(eSize)] <- mSS*1.05
            oneCol <- data.frame(feature=iT$feature,toplot=(eSize)); 
            oneCol$toplot[iT$FDR > pVcutoff] <- 0.0
            colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          } else {
            # > abundances
            mS <- iT$V2mean/iT$V1mean
            mS <- mS[!is.na(mS)]; mS <- mS[!is.infinite(mS)]; mSS <- max(mS,mSS)
            eSize <- iT$V2mean/iT$V1mean
            eSize[is.na(eSize)] <- 0
            eSize[eSize == 1] <- 0
            
            #eSize[eSize <= 0] <- abs(eSize[eSize <= 0])
            eSize[eSize <= 0] <- 0.0
            
            eSize[eSize < 1] <- -1*log(1/eSize[eSize < 1])
            eSize[eSize > 1] <- log(eSize[eSize > 1])
            eSize[is.infinite(eSize)] <- mSS*1.05
            oneCol <- data.frame(feature=iT$feature,toplot=(eSize))
            oneCol$toplot[iT$FDR > pVcutoff] <- 0.0
            colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          }
        } else if (metric == "medEffectRatio") {
          # > median enrichment / depletion
          if (grepl("Prevalences", f)) {
            # > prevalences
            mS <- iT$V2prop/iT$V1prop
            mS <- mS[!is.na(mS)]; mS <- mS[!is.infinite(mS)]; mSS <- max(mS,mSS)
            eSize <- iT$V2prop/iT$V1prop
            eSize[is.na(eSize)] <- 0
            eSize[eSize == 1] <- 0
            eSize[eSize < 1] <- -1*log(1/eSize[eSize < 1])
            eSize[eSize > 1] <- log(eSize[eSize > 1])
            eSize[is.infinite(eSize)] <- mSS*1.05
            oneCol <- data.frame(feature=iT$feature,toplot=(eSize)); 
            oneCol$toplot[iT$FDR > pVcutoff] <- 0.0
            colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          } else {
            # > abundances
            mS <- iT$V2median/iT$V1median
            mS <- mS[!is.na(mS)]; mS <- mS[!is.infinite(mS)]; mSS <- max(mS,mSS)
            eSize <- iT$V2median/iT$V1median
            eSize[eSize == 1] <- 0
            eSize[is.na(eSize)] <- 0
            #eSize[eSize <= 0] <- abs(eSize[eSize <= 0])
            eSize[eSize <= 0] <- 0.0
            eSize[eSize < 1] <- -1*log(1/eSize[eSize < 1])
            eSize[eSize > 1] <- log(eSize[eSize > 1])
            eSize[is.infinite(eSize)] <- mSS*1.05
            oneCol <- data.frame(feature=iT$feature,toplot=(eSize))
            oneCol$toplot[iT$FDR > pVcutoff] <- 0.0
            colnames(oneCol) <- c("Feature",iT$PHENOTYPE[1])
          }
        }
        if (is.null(hmDFsig)) {
          hmDFsig <- oneCol
        } else {
          hmDFsig <- merge.data.frame(hmDFsig,oneCol,by = "Feature")
        }
      }
    }
  }
  hmDFsig <- hmDFsig[!duplicated(hmDFsig$Feature),]
  rownames(hmDFsig) <- hmDFsig$Feature
  hmDFsig$Feature <- NULL
  noSig = FALSE
  hmPlotDF <- hmDFsig
  if (metric == "statSig") {
    hmPlotDF[abs(hmPlotDF) < abs(log(pVcutoff,base=10)) ] <- 0.0
  } else if (metric == "meanEffectRatio") {
    hmPlotDF[abs(hmPlotDF) < log(enrichmentCutoff)] <- 0.0
  }
  hmPlotDF[is.na(hmPlotDF)] <- 0.0
  if (sum(hmPlotDF != 0) == 0) {
    hmPlotDF <- hmDFsig
    noSig = TRUE
    hmPlotDF <- hmPlotDF+rnorm(ncol(hmPlotDF)*nrow(hmPlotDF))/1000
    print(hmPlotDF)
  }
  hmPlotDF$sorter <- apply(hmPlotDF,MARGIN = 1,function(x) sum(abs(x)))
  
  hmPlotDF <- hmPlotDF[order(hmPlotDF$sorter,decreasing = T),]
  hmPlotDF$sorter <- NULL
  hmPlotDF <- hmPlotDF[1:min(nrToPlot,nrow(hmPlotDF)),]
  
  if (invertYN) {hmPlotDF = hmPlotDF * -1}
  hmDFdirection <- hmPlotDF 
  hmDFdirection[hmDFdirection > 0] <- 1
  hmDFdirection[hmDFdirection < 0] <- -1
  hmDFdirection[hmDFdirection == 0] <- 0
  hmDFdirection[hmDFdirection == 1] <- "+"
  hmDFdirection[hmDFdirection == -1] <- "-"
  hmDFdirection[hmDFdirection == 0] <- ""
  
  # set limits
  hmPlotDF[hmPlotDF >= maxMax] <- maxMax
  hmPlotDF[hmPlotDF <= -1*maxMax] <- -1*maxMax
  
  # set colors
  breaksList = seq(-max(abs(hmPlotDF)), +max(abs(hmPlotDF)),by=2 * max(abs(hmPlotDF))/55)
  cols <- colorRampPalette(c("Darkblue","White","Darkred"))(length(breaksList))
  cols[seq(length(cols)/2-1,length(cols)/2+1)] <- "White"

  if (noSig) {cols <- "white"; hmDFdirection[!is.na(hmDFdirection)] <- ""}
  # plot it!
  print ('  >>> Plotting')
  p <- pheatmap(hmPlotDF,annotation_row = NULL,annotation_names_row = T,labels_row = rownames(hmPlotDF),legend = T,
                show_rownames = T, cluster_rows = clusterFeatures,cluster_cols = clusterPhenos,angle_col = 90,display_numbers = hmDFdirection,
                fontsize_number = 20,border_color = "#EEEEEE",na_col = "white",
                color = cols,treeheight_row = 0, treeheight_col = 0,legend_labels = "log(p-value)",
                fontsize_col = 14,fontsize_row = 12,breaks = breaksList)
  
  
  
  xAdd = 0
  if ("pwyAbundance" %in% doFeatures) {xAdd=400+nrow(hmPlotDF)*4}
  print(addXextra)
  wtX = addXextra+xAdd+800+ncol(hmPlotDF)*35+nrow(hmPlotDF)*4
  print(wtX)
  save_pheatmap_png(p,outFile,width = wtX,
                    height = 800+nrow(hmPlotDF)*45+addYextra
                    ,res = 200)
  print (' >>> DONE')
  return(p)
}

aggregatePlotHeatmapLM <- function(tblFolder,doFeatures=c("taxAbundances"),nrToPlot=20,outFile="plot.png",pVcutoff=0.05,multiTest=F,
                                 clusterFeatures=T,clusterPhenos=F,subsetFeatures="",subsetPhenos="",
                                 metric="statSig",enrichmentCutoff = 1.005,addXextra=0,addYextra=0,maxMax = 5,
                                 shortenTaxNames=F) {
  print ('>>> AGGREGATING RESULTS:')
  if (multiTest) {
    print (paste0(' doing multiple-testing correction (BH), using FDR = ',pVcutoff))
  } else {
    print (paste0(' using nominal p-value cutoff of ',pVcutoff))
  }
  if (!metric %in% c("statSig","beta","rsquared"))  {
    print (" >> metric MUST be one of [statSig, beta, rsquared]")
    break()
  }
  hmDFsig <- NULL
  hmDFenrich <- NULL
  hmDFdirection <- NULL
  mSS <- 0
  #maxMax <- 5
  nrTests <- 0
  if (multiTest) {
    for (f in dir(tblFolder, pattern =".csv")) {
      doParse = F
      for (g in doFeatures) {if (grepl(g,f)) {doParse = T}}
      if (doParse) {
        #print(f)
        iT <- read.table(paste0(tblFolder,'/',f),sep=',',header = T,stringsAsFactors = F)
        if (subsetFeatures != "") {
          iT <- iT[grep(subsetFeatures,iT$responseVar),]
        }
        if (subsetPhenos != "")  {
          iT <- iT[iT$Phenotype %in% subsetPhenos,]
        }
        nrTests <- nrTests+nrow(iT)
      }
    }
    print (paste0('  >> doing multiple-testing correction for ',nrTests,' tests!'))
  }
  print ('  >>> parsing tables ...')
  nrP <- 0
  for (f in dir(tblFolder, pattern =".csv")) {
    doParse = F
    for (g in doFeatures) {if (grepl(g,f)) {doParse = T}}
    if (doParse) {
      nrP <- nrP + 1
      #print(f)
      iT <- read.table(paste0(tblFolder,'/',f),sep=',',header = T,stringsAsFactors = F)
      if (subsetFeatures != "") {
        iT <- iT[grep(subsetFeatures,iT$responseVar),]
      }
      if (subsetPhenos != "")  {
        iT <- iT[iT$Phenotype %in% subsetPhenos,]
      }
      if (multiTest) {
        iT$FDR <- p.adjust(iT$pValue,n = nrTests)
      } else {
        iT$FDR <- iT$pValue
      }

      # add row(s) to dataframe
      # > pick what to plot
      if (metric == "statSig") {
        # > statistical significance 
        oneCol <- data.frame(feature=iT$responseVar,toplot=log(iT$FDR,base = 10)*-1*sign(iT$beta)); colnames(oneCol) <- c("Feature",iT$Phenotype[1])
      } else if (metric == "beta") {
        # > beta
        oneCol <- data.frame(feature=iT$responseVar,toplot=iT$beta ); colnames(oneCol) <- c("Feature",iT$Phenotype[1])
        # > test for significance
        oneCol[[2]][iT$FDR > pVcutoff] <- 0.0
      } else if (metric == "rsquared") {
        # > median enrichment / depletion
        iT$adjRsq[iT$adjRsq < 0] <- 0
        oneCol <- data.frame(feature=iT$responseVar,toplot=iT$adjRsq*1*sign(iT$beta) ); colnames(oneCol) <- c("Feature",iT$Phenotype[1])
        # > test for significance
        oneCol[[2]][iT$FDR > pVcutoff] <- 0.0
      }
      if (is.null(hmDFsig)) {
        hmDFsig <- oneCol
      } else {
        hmDFsig <- merge.data.frame(hmDFsig,oneCol,by = "Feature")
      }
    }
  }
  print (paste0('   >>> DONE, parsed, ',nrP,' tables'))
  
  hmDFsig <- hmDFsig[!duplicated(hmDFsig$Feature),]
  rownames(hmDFsig) <- hmDFsig$Feature
  hmDFsig$Feature <- NULL
  noSig = FALSE
  hmPlotDF <- hmDFsig
  if (metric == "statSig") {
    hmPlotDF[abs(hmPlotDF) < abs(log(pVcutoff,base=10)) ] <- 0.0
  } 
  if (sum(hmPlotDF != 0) == 0) {
    hmPlotDF <- hmDFsig
    noSig = TRUE
    hmPlotDF <- hmPlotDF+rnorm(ncol(hmPlotDF)*nrow(hmPlotDF))/1000
    #print(hmPlotDF)
  }
  hmPlotDF$sorter <- apply(hmPlotDF,MARGIN = 1,function(x) sum(abs(x)))
  
  hmPlotDF <- hmPlotDF[order(hmPlotDF$sorter,decreasing = T),]
  hmPlotDF$sorter <- NULL
  hmPlotDF <- hmPlotDF[1:min(nrToPlot,nrow(hmPlotDF)),]
  
  hmDFdirection <- hmPlotDF 
  hmDFdirection[hmDFdirection > 0] <- 1
  hmDFdirection[hmDFdirection < 0] <- -1
  hmDFdirection[hmDFdirection == 0] <- 0
  hmDFdirection[hmDFdirection == 1] <- "+"
  hmDFdirection[hmDFdirection == -1] <- "-"
  hmDFdirection[hmDFdirection == 0] <- ""
  
  # set limits
  hmPlotDF[hmPlotDF >= maxMax] <- maxMax
  hmPlotDF[hmPlotDF <= -1*maxMax] <- -1*maxMax
  
  # set colors
  breaksList = seq(-max(abs(hmPlotDF)), +max(abs(hmPlotDF)),by=2 * max(abs(hmPlotDF))/55)
  cols <- colorRampPalette(c("Darkblue","White","Darkred"))(length(breaksList))
  cols[seq(length(cols)/2-1,length(cols)/2+1)] <- "White"
  
  if (noSig) {cols <- "white"; hmDFdirection[!is.na(hmDFdirection)] <- ""}
  # plot it!
  print ('  >>> Plotting')
  p <- pheatmap(hmPlotDF,annotation_row = NULL,annotation_names_row = T,labels_row = rownames(hmPlotDF),legend = T,
                show_rownames = T, cluster_rows = clusterFeatures,cluster_cols = clusterPhenos,angle_col = 90,display_numbers = hmDFdirection,
                fontsize_number = 20,border_color = "#EEEEEE",na_col = "white",
                color = cols,treeheight_row = 0, treeheight_col = 0,legend_labels = "log(p-value)",
                fontsize_col = 14,fontsize_row = 12,breaks = breaksList)
  
  xAdd = 0
  if ("pwyAbundance" %in% doFeatures) {xAdd=400+nrow(hmPlotDF)*4}
  save_pheatmap_png(p,outFile,width = addXextra+xAdd+800+ncol(hmPlotDF)*35+nrow(hmPlotDF)*4,
                    height = 800+nrow(hmPlotDF)*45+addYextra, res = 200)
  
  print (' >>> DONE')
  return(p)
}

testFeatures <- function(inDFf,featureType='taxa',response='Diagnosis',plotsFolder='',dispPlot = 'Pn',xLab='Diagnosis',FDRcut=F,cutoff=0.05) {
  # find features with abundance changed [enriched or depleted]
  # ========================================================
  toTest <- colnames(inDFf[colnames(inDFf)!=response])
  resAbZ <- data.frame()
  # > run pair-wise mann-u-whitney tests for relative abundance
  for (t in toTest) {
    resAbZ <- rbind.data.frame(resAbZ,testOneFeature(inDFf,saveFolder = F,feature = t,responseVar = response,doPlots = F,discardZeros = F))
  }
  resAbZ <- na.omit(resAbZ)
  # correct for multiple testing
  resAbZ$FDR <- p.adjust(resAbZ$pValue)
  resAbZ <- resAbZ[order(resAbZ$pValue),]
  resAbZ$V1med_minus_V2med <- resAbZ$V1median - resAbZ$V2median
  # mark enrichment vs depletion
  resAbZ$Change <- "Depletion"
  resAbZ$Change[resAbZ$V1minusV2 < 0] <- "Enrichment"
  
  # > make pretty plots for depleted features only
  c = 0
  if (FDRcut) {
    for (t in resAbZ$feature[resAbZ$Change == "Depletion" & resAbZ$FDR < cutoff]) {
      c = c + 1
      testOneFeature(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_depleted_",c,"_",t),feature = t,
                     responseVar = response,doPlots = T,discardZeros = F,display = dispPlot,xLab = xLab)
    }
    c = 0
    # > make pretty plots for enriched features only
    for (t in resAbZ$feature[resAbZ$Change == "Enrichment" &  resAbZ$FDR < cutoff]) {
      c = c + 1
      testOneFeature(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_enriched_",c,"_",t),feature = t,
                     responseVar = response,doPlots = T,discardZeros = F,display = dispPlot,xLab = xLab)
    }
  } else {
    for (t in resAbZ$feature[resAbZ$Change == "Depletion" & resAbZ$pValue < cutoff]) {
      c = c + 1
      testOneFeature(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_depleted_",c,"_",t),feature = t,
                     responseVar = response,doPlots = T,discardZeros = F,display = dispPlot,xLab = xLab)
    }
    c = 0
    # > make pretty plots for enriched features only
    for (t in resAbZ$feature[resAbZ$Change == "Enrichment" &  resAbZ$pValue < cutoff]) {
      c = c + 1
      testOneFeature(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_enriched_",c,"_",t),feature = t,
                     responseVar = response,doPlots = T,discardZeros = F,display = dispPlot,xLab = xLab)
    }
  }
  resAbZ
}

testFeaturesPrev <- function(inDFf,featureType='taxa',response='Diagnosis',plotsFolder='',dispPlot = 'Pn',xLab='Diagnosis',FDRcut=F,cutoff=0.05) {
  # find features with abundance changed [enriched or depleted]
  # ========================================================
  toTest <- colnames(inDFf[colnames(inDFf)!=response])
  resAbZ <- data.frame()
  # > run pair-wise mann-u-whitney tests for relative abundance
  for (t in toTest) {
    print(paste0('   >>> testing ',t))
    resAbZ <- rbind.data.frame(resAbZ,testOneFeaturePrevalence(inDFf,saveFolder = F,feature = t,responseVar = response,doPlots = F))
  }
  resAbZ <- na.omit(resAbZ)
  # correct for multiple testing
  resAbZ$FDR <- p.adjust(resAbZ$pValue)
  resAbZ <- resAbZ[order(resAbZ$pValue),]
  #resAbZ$V1med_minus_V2med <- resAbZ$V1median - resAbZ$V2median
  # mark enrichment vs depletion
  resAbZ$Change <- "Depletion"
  resAbZ$Change[resAbZ$V1toV2 < 1] <- "Enrichment"
  
  # > make pretty plots for depleted features only
  c = 0
  if (FDRcut) {
    for (t in resAbZ$feature[resAbZ$Change == "Depletion" & resAbZ$FDR < cutoff]) {
      c = c + 1
      testOneFeaturePrevalence(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_depleted_",c,"_",t),feature = t,
                               responseVar = response,doPlots = T,display = dispPlot,xLab = xLab)
    }
    c = 0
    # > make pretty plots for enriched features only
    for (t in resAbZ$feature[resAbZ$Change == "Enrichment" &  resAbZ$FDR < cutoff]) {
      c = c + 1
      testOneFeaturePrevalence(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_enriched_",c,"_",t),feature = t,
                               responseVar = response,doPlots = T,display = dispPlot,xLab = xLab)
    }
  } else {
    for (t in resAbZ$feature[resAbZ$Change == "Depletion" & resAbZ$pValue < cutoff]) {
      c = c + 1
      testOneFeaturePrevalence(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_depleted_",c,"_",t),feature = t,
                               responseVar = response,doPlots = T,display = dispPlot,xLab = xLab)
    }
    c = 0
    # > make pretty plots for enriched features only
    for (t in resAbZ$feature[resAbZ$Change == "Enrichment" &  resAbZ$pValue < cutoff]) {
      c = c + 1
      testOneFeaturePrevalence(inDFf,saveFolder = paste0(plotsFolder,"/",featureType,"_enriched_",c,"_",t),feature = t,
                               responseVar = response,doPlots = T,display = dispPlot,xLab = xLab)
    }
  }
  resAbZ
}