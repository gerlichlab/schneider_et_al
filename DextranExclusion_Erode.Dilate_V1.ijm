//The script measures an eroded ROI of the chromatin channel applied to the dextran channel and  dilated ring around the chromatin ROI to measure the dextran signal by mean fluorescence intensity inside and outside chromatin
//this script expects single Z-slice images with three channels: C1: YFP-H2B, C2: Transmission, C3: Dextran-TRITC

dir = getDirectory("_Choose the directory with the images to RGB");
	G_Ddir = getDirectory("Choose Destination Directory");
	list = getFileList(dir);
	
//manual background measurement for correction

waitForUser("Title", "Measure BG in TRITC (C3), then click OK.");
Background_C3= getNumber("Background C3", 1.480);


	for (j=0; j<list.length; j++) {
		run("Bio-Formats Importer", "open=["+dir + list[j]+"]  color_mode=Default view=Hyperstack stack_order=XYCZT");
		
//GET INFO
imagetitle = getTitle();

strA = split(imagetitle, ".");

// Make a duplicate, split and binary for the initial outline
run("Duplicate...", "title=duplicate duplicate range=1-&Z");
run("Split Channels");


//choose the channel 1 C1 and make binary (otsu threshold) after gausian blur


selectWindow("C1-duplicate");
run("Accurate Gaussian Blur", "sigma=2");
setAutoThreshold("Otsu dark");

//setThreshold(43, 255);
setOption("BlackBackground", false);
run("Convert to Mask");

run("Duplicate...", " ");
run("Duplicate...", " ");


selectWindow("C1-duplicate");
run("Create Selection");
roiManager("Add");

selectWindow("C1-duplicate-1");
run("Options...", "iterations=10 count=1 do=Erode");
run("Create Selection");
roiManager("Add");

selectWindow("C1-duplicate-2");
run("Options...", "iterations=6 count=1 do=Dilate");
run("Create Selection");
roiManager("Add");

selectWindow("C3-duplicate");
roiManager("Select", newArray(0,2));
roiManager("XOR");
roiManager("Add");


//Process Dextran channel including the backgroundcorrection for the measured ROIs individually
selectWindow("C3-duplicate");

selectWindow("C3-duplicate");
roiManager("Select", 1);
run("Subtract...", "value="+Background_C3+" stack");
run("Measure");
roiManager("Select", 3);
run("Subtract...", "value="+Background_C3+" stack");
run("Measure");
roiManager("Deselect");
roiManager("Delete");

//cleanup after every iteration

run("Close All");
selectWindow("ROI Manager");
run("Close");
	}

//save the results file as .txt and .xls
selectWindow("Results");
saveAs("Results", G_Ddir+ strA[0] +"_Dextran.xls");
saveAs("Results", G_Ddir+ strA[0] +"_Dextran.txt");
run("Close");