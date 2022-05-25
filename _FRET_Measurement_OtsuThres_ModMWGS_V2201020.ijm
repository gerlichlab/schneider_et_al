 // this script is based on the measure from binary mask script, the FRET Script from Daniel and Sara
// Aim is to measure the FRET ratio and the convex hull at the same time

// It requires a single Z section and a 4 channel image as in experiment 002575  with C1 = FRET signal (YFP), C2 = Donor = CFP, C3  = Transmission 
// and C4 = YFP again in better resolution?
//// IMPORT DATA
dir = getDirectory("Choose the directory with the images to RGB");
	G_Ddir = getDirectory("Choose Destination Directory");
	list = getFileList(dir);

//reorder the C1:CFP, C2:FRET, C3:DIC, C4:YFP from 1234 to 2134
//run("Arrange Channels...", "new=2134");
//selectWindow("TRIAL.tif");
// User measure BG

waitForUser("Title", "Measure BG in YFP (FRET/C1) and CFP (C2), then click OK.");
Background_C1 = getNumber("Background C1", 0);
Background_C2= getNumber("Background C2", 0);
	
	for (j=0; j<list.length; j++) {
	run("Bio-Formats Importer", "open=["+dir + list[j]+"]  color_mode=Default view=Hyperstack stack_order=XYCZT");

//GET INFO
imagetitle = getTitle();

strA = split(imagetitle, ".");


// Make a duplicate, split and binary for the initial outline
run("Duplicate...", "title=duplicate duplicate range=1-&Z");
run("Split Channels");

Z=nSlices;
print(Z);

GaussianSigma=3;

//**************************************************

run("Clear Results");

/////*****************************************************************
/// Calculate YFP:CFP ratio based on area mean

/// Calculations based on  mask in C4 channel 
// Prepare channels

//Process C1 channel
selectWindow("C1-duplicate");
run("Accurate Gaussian Blur", "sigma="+GaussianSigma+" stack");
run("Subtract...", "value="+Background_C1+" stack");

//Process C2 channel
selectWindow("C2-duplicate");
run("Accurate Gaussian Blur", "sigma="+GaussianSigma+" stack");
run("Subtract...", "value="+Background_C2+" stack");

// generate binary mask with values 0 and 1
selectWindow("C4-duplicate");

// Make a duplicate and binary for the initial outline
run("Duplicate...", "title=Mask duplicate range=1-&Z");
run("Accurate Gaussian Blur", "sigma=2 stack");

//setAutoThreshold("Otsu" or "Huang");
setAutoThreshold("Otsu");
run("Convert to Mask", "method=Default background=Dark");
run("Make Binary", "method=Default background=Dark");

selectWindow("Mask");
run("Convert to Mask", "method=Default background=Default");   //8-bit image, black = value 255, white = value 0
run("Divide...", "value=255 stack"); //8-bit image, black = value 1, white = value 0
setMinAndMax(0, 1);

// FRET channel masked
imageCalculator("Multiply create 32-bit stack", "Mask","C1-duplicate");
rename("C1-masked");

// CFP Channel masked
imageCalculator("Multiply create 32-bit stack", "Mask","C2-duplicate");
rename("C2-masked");


//measure mean of FRET for all timepoints
selectWindow("C1-masked");
setThreshold(1, 255);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
run("Set Measurements...", "area mean standard min limit redirect=None decimal=3");
run("ROI Manager...");
run("Select All");
roiManager("Add");
roiManager("Multi Measure");
roiManager("Delete");
//save the result file
selectWindow("Results");
saveAs("Results", G_Ddir+ strA[0] +"_FRET.xls");
run("Close");

//measure mean of CFP for all timepoints
selectWindow("C2-masked");
setThreshold(1, 255);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
run("Set Measurements...", "area mean standard min limit redirect=None decimal=3");
run("ROI Manager...");
run("Select All");
roiManager("Add");
roiManager("Multi Measure");
roiManager("Delete");
//save the result file
selectWindow("Results");
saveAs("Results", G_Ddir+ strA[0] +"_CFP.xls");
run("Close");


// generate RG ratio image

imageCalculator("Divide create 32-bit stack", "C1-masked","C2-masked");

setMinAndMax(0.8, 2.6);
call("ij.ImagePlus.setDefault16bitRange", 0);
// save image
dest_filename_1 = strA[0] + "_FRET.tif";
fullpath1 = G_Ddir + dest_filename_1;
saveAs("Tiff", fullpath1);

//run("Lookup Tables", "resource=Lookup_Tables/ lut=[Blue Green Red]");
//run("Rainbow RGB");
//run("mpl-inferno");
run("Fire");
//run("Thresholded Blur", "radius=1 threshold=10 softness=0.50 strength=2 stack");
//save FRET as individual channel after threshold blur

dest_filename_1 = strA[0] + "_FRET.tif" ;
fullpath1 = G_Ddir + dest_filename_1 ;
saveAs("Tiff", fullpath1) ;

rename("RG_ratio");
run("RGB Color");

selectWindow(imagetitle);
Stack.setChannel(4);
run("Grays");
Stack.setChannel(3);
run("Grays");
Stack.setChannel(2);
run("Green");
Stack.setChannel(1);
run("Red");
run("Make Composite");
run("RGB Color", "frames");
rename("input");
run("Combine...", "stack1=[input] stack2=[RG_ratio]");

// save image
dest_filename_1 = strA[0] + "_FRET_merged.tif";
fullpath1 = G_Ddir + dest_filename_1;
saveAs("Tiff", fullpath1);

//creates a log file with entered data and saves it
print(imagetitle);

print("Background_C1:"+Background_C1);
print("Background_C2:"+Background_C2);
print("Sigma:"+GaussianSigma);
selectWindow("Log");
dest_filename_2 = strA[0] + "_Log.txt";
fullpath2 = G_Ddir + dest_filename_2;
saveAs("Text", fullpath2);
run("Close");

//clean up
run("Clear Results");
run("Close All");
selectWindow("ROI Manager");
run("Close");
}