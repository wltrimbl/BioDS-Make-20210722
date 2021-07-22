
# Make for getting things done

BioDS workshop, 2021-07-22, Drexel / Rowan / University of Chicago

If you've spent time in linux/unix you have seen make function as a glorified shell script, performing the functions of building, possibly downloading additional data, and installing.

A typical invokation of make is
Download SoftwarePackage.zip
unzip SoftwarePackage.zip
cd SoftwarePackage
./configure.sh
make build
sudo make install

I don't care about Make because it installs things. I care because Make can get things done.

The task Make was designed for was compiling hundreds of source files when only one or two of them had changed, and building from scratch would take a long time.  You can imagine a simple rule, check to see if any of the source files have changed since the last build, and if they have, recompile them.

I can confess to once having written a 500-line shell script that mostly consisted of 

    if [[ ! -e outputfile304.dat ]]   
    then
    runprogramtogenerate outputfile304.dat
    fi

There is a better way.  Make was designed to save the computer work by checking what has been done already and skipping it.  If I am willing to use presence/absence of files and their timestamps to keep track of work that has been done or not done, Make can do wonderful things.

Among the drawbacks--Make is hard to debug, it uses difficult-to-remember variables, and it is so ugly that the programmer types don't like to use it anymore (so they use one of a dozen replacements for make that address some if its flaws).  Among the advantages--it manages what do to based on whether the files are there (or are recent) and it is present on really almost every system you can expect to find.

# Installing

Linux and OSX users will have make built in to their operating system.  Open "Terminal" and confirm that make works with

    make -v

Most Windows users who use make use ssh (PuTTY) to run commands on linux/unix servers elsewhere.

If you are running Windows, don't use ssh,  and want to follow along, you can run make (and an editor) in a docker container under windows. 
Install Docker Desktop https://www.docker.com/products/docker-desktop, open a Command Prompt

    docker run --rm -it ubuntu                                   # downloads and starts a blank ubuntu docker image
    apt update && apt-get install -y make nano curl unzip && cd  # installs the minimum -- make, curl, nano and unzip 
    curl -OLJ https://swcarpentry.github.io/make-novice/files/make-lesson.zip  # gets the test data

# Download lesson materials
https://swcarpentry.github.io/make-novice/files/make-lesson.zip

# Lessons
The lessons are here:
[Software Carpentry Make lesson](https://swcarpentry.github.io/make-novice/)

# Some of the ways Make can be useful:
* The "textbook" example:  you have a directory which contains the text of your dissertation, another directory which contains the figures of your dissertation, and another directory which contains the data and scripts that generate the figures.  Make builds your thesis when the text changes, the scripts that draw the figures change, or when you replace the data.  You have a make target to update your thesis, and another make target to back it up remotely.

* Use a wildcard pattern in a certain directory to detect "input" files and run a potentially many-step pipeline to generate the output files.
* Use a file containing "targets" (Acession nubmers or URIS) and use Make to download the things that are still needed.
* You can make a Makefile with instructions on how to do boring format conversions (particularly easily if you can encode the format in the filename).

# Examples in the wild
* An example of tedious format conversion work done by a makefile (converting 400,000 black and white files into 100,000 color ones:
[thumbnailpolish makefile](https://github.com/wltrimbl/thumbnailpolish/blob/master/src/Makefile)

* [Khmer's makefile](https://github.com/dib-lab/khmer/blob/master/Makefile), for building a piece of scientific sofware

* [A utilitarian data-munging makefile for NGS data](https://github.com/wltrimbl/BioDS-Make-20210722/blob/master/mappit.mk)

