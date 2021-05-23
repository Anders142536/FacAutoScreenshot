
This image stitcher is written in Java 12, so you will need to install Java 12 or higher.

Until a UI is added, do this to stitch your fragmented screenshots back together:
0. Download the .jar file from the Releases on the right.

1. Open up some command line. If using linux you should know how to do this. If using windows, press WINDOWS and type "cmd", then press enter. If using mac then good luck, bro, I never touched a mac ¯\\\_(ツ)\_/¯. Duck Duck Go is your friend.

2. Navigate to the folder where the downloaded imagestitcher.jar file is.

3. Enter "java -jar imagestitcher.jar" and press enter. Do not panic, on the first run this will throw an error, due to no config file being found. It will be created for you, so just open the file that is described in the response, then run the program again.

4. Config:
    * Please keep in mind that under windows a path has to be given with / instead of \, due to some stupid java limitation when reading text from a file.
    * The output folder of your screenshots should be found in your factorio folder:
    When using linux that is the same .factorio folder from before/script-output/screenshots/GAMESEEDOFYOURSAVE/split. Under Windows thats the same Factorio folder from before with the same sub path. Under Mac, well, I *really, really* hope you know what you are doing :D

5. The programm will create a folder in the directory it is in, called "stitched screenshots" with all stitched screenshots in it.


Last, but not least, I would recommend you to stitch them back together often and clean up the fragmented files, as especially when screenshotting with 8k resolution, your hard drive will quickly fill up with data. When stitching the images your hard drive will require as much space as the input folder has in size. I do not delete those files automatically for you as I dont even trust myself enough to do automated deletion of *anything*. 

If you need further instructions I politely refer you to google, which will probably the quickest source of answers. I am glad to help you anytime in the Discussions tab of the Mod Portal.