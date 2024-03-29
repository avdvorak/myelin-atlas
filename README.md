# Myelin Atlas
Example code for atlas creation methods used in: 

*An atlas for human brain myelin content throughout the adult life span*. 
https://www.nature.com/articles/s41598-020-79540-3


<img width="1280" alt="GitHug_Image2" src="https://user-images.githubusercontent.com/24612184/119878439-f6595980-bede-11eb-82cd-3935c21a191d.png">


DOI for this example code:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4067132.svg)](https://doi.org/10.5281/zenodo.4067132)



The structural template, quantitative myelin water imaging atlases, tissue segmentations, and regions of interest generated and analyzed in the study are available here: 

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4067119.svg)](https://doi.org/10.5281/zenodo.4067119)



The structural template and myelin atlas will soon be available to be viewed interactively at: https://www.msmri.com/brain-atlases/


## ANTs Installation
The pipeline used the Advanced Normalization Tools software (https://github.com/ANTsX/ANTs). Instructions for compiling and setting up ANTs can be found here:

https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS


## FSL Installation
The script also uses some generic functions from FSL, which can be called after installation of FSL, as detailed here:

https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation

or can be replaced with an ANTs equivalent (usually via the *ImageMath* command).


## Myelin Water Imaging Analysis
Access to the myelin water imaging analysis software used can be requested from the following page:

https://mriresearch.med.ubc.ca/news-projects/myelin-water-fraction/

