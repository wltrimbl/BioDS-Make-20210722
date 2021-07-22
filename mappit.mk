#!/bin/bash

# What else does it need?  ~/Phi-mut bowtie2 index..

KMER=25
LINES=4000000
THREADS=8
V=2
TYPE=-q
MINCONTIGLENGTH=400

# These variables expand to lists of input files (the first two lines)
# and lists of possible target files from find-and-replace on this list of inputs.
in
#LISTOFFA=$(wildcard L?_A?_B1?.fa)
ifeq ($(wildcard *_R1_001.fastq),)
SUFFIX=_R1.fastq
R2SUFFIX=_R2.fastq
else
SUFFIX=_R1_001.fastq
R2SUFFIX=_R2_001.fastq
endif

LISTOFR1=$(wildcard *$(SUFFIX))
#LISTOFR2=$(subst _R2.fastq,$(SUFFIX),$(LISTOFR1))
HTML=Summary.html
R1T=$(subst $(SUFFIX),_T.R1.fastq,$(LISTOFR1))
R2T=$(subst $(SUFFIX),_T.R2.fastq,$(LISTOFR1))
HIST=$(subst $(SUFFIX),.inw.hist,$(LISTOFR1)) $(subst $(SUFFIX),.out.hist,$(LISTOFR1))
PNGS=$(subst $(SUFFIX),.inw.png,$(LISTOFR1)) $(subst $(SUFFIX),.out.png,$(LISTOFR1))
OUTS=$(subst $(SUFFIX),.inw.out,$(LISTOFR1)) $(subst $(SUFFIX),.out.out,$(LISTOFR1)) $(subst $(SUFFIX),.all.out,$(LISTOFR1))
KMER15FILES=$(subst $(SUFFIX),$(SUFFIX).15,$(LISTOFR1)) 
KMER21FILES=$(subst $(SUFFIX),$(SUFFIX).21,$(LISTOFR1)) 
KMERPNG=$(subst $(SUFFIX),$(SUFFIX).21.5.png,$(LISTOFR1)) 
CONT=$(subst $(SUFFIX),.contigs.fa,$(LISTOFR1)) 
JOIN=$(subst $(SUFFIX),.join.fastq,$(LISTOFR1)) 
JOINLOG=$(subst $(SUFFIX),.join.log,$(LISTOFR1)) 
JOINLENS=$(subst $(SUFFIX),.join.lens,$(LISTOFR1)) 
JOINSCRUB=$(subst $(SUFFIX),.join.scrubbed.fastq,$(LISTOFR1)) 
BLIND=$(subst $(SUFFIX),.blind.R1.fastq,$(LISTOFR1)) 
BLINDLOG=$(subst $(SUFFIX),.blind.log,$(LISTOFR1)) 

#  -------------
# Default action: show available commands (marked with double '#').
all : commands
	@echo 
	@echo These are the potential inputs:
	@echo ===============================
	@echo $(LISTOFR1)

#  -------------
## commands:    show all commands (default)
commands :
	@echo These are the make targets:
	@echo ===========================
	@grep -E '^##' mappit.mk | sed -e 's/## //g'

#  -------------
## stuff:       make size report, join, and blind-scrub datafiles
stuff:  $(HTML) $(JOIN) 

#  -------------
## show:        Show a list of input files under consideration
show:  
	echo These are the potential inputs:
	echo $(LISTOFR1)

#  -------------
## size:        make size report
size: $(HTML)

#  -------------
# kmer15:       count 15mers on R1 files
kmer15: $(KMER15FILES)

#  -------------
## kmer21:      count 21mers on R1 files 
kmer21: $(KMER21FILES)
#.SECONDARY: $(HIST) $(OUTS) $(PNGS) $(CONT) $(OUTS) $(JOINLOG) $(BLINDLOG)

#  -------------
## join:        join all R1/R2 file pairs
join: $(JOIN) $(JOINLENS)

#  -------------
## joinlens:    get histograms of merged lengths
joinlens: $(JOINLENS)

#  -------------
## joinscrub:   
joinscrub: $(JOINSCRUB)

#  -------------
## blind:       run blindadapterscrub on all R1/R2 file pairs
blind: $(BLIND)

.SECONDARY: 
# ================================================================================================

%.fastq: %.fa
	cat $< | fa2fq  > $@
#	fa2fq.py $<  > $@

# This rule invokes fastq-join from ea-utils.
%.join.fastq : %$(SUFFIX) %$(R2SUFFIX)
	$(eval STEM=$(subst .join.fastq,,$@))
	$(eval JOINCMD=fastq-joinX -p 20 -x -m 12 $(STEM)$(SUFFIX) $(STEM)$(R2SUFFIX)  -o $(STEM). >> $(STEM).join.log)
	echo $(JOINCMD) > $(STEM).join.log
	$(JOINCMD)
	mv $(STEM).join $(STEM).join.fastq
	mv $(STEM).un1 $(STEM).un1.fastq
	mv $(STEM).un2 $(STEM).un2.fastq

%.interleaved.fastq:  %$(SUFFIX) %$(R2SUFFIX)
	$(eval STEM=$(subst .interleaved.fastq,,$@))
	$(eval R1=$(STEM)$(SUFFIX))
	$(eval R2=$(STEM)$(R2SUFFIX))
	shufflesequences.py $(R1) $(R2) > $@ 
	
# This rule invokes fq-blindadapterscrub.py, a needlessly slow, not exceptionally effective adapter scrubber
%.blind.R1.fastq: %$(SUFFIX) %$(R2SUFFIX)
	$(eval STEM=$(subst .blind.R1.fastq,,$@))
	fq-blindadapterscrub.py -1 $(STEM)$(SUFFIX) -2 $(STEM)$(R2SUFFIX)  -o $(STEM).blind > $(STEM).blind.log
	mv $(STEM).blind_R1.fastq $(STEM).blind.R1.fastq
	mv $(STEM).blind_R2.fastq $(STEM).blind.R2.fastq

# This is a crudely truncated, first-30-bp-only set of the fastq rule 
%_T.R1.fastq: %$(SUFFIX)
	head -n $(LINES) $< | cut -c 1-30 > $@

%_T.R2.fastq: %$(R2SUFFIX)
	head -n $(LINES) $< | cut -c 1-30 > $@

clean:
	rm *.seq *.out *.hist *.png *.html *.bow3
	rm -R *.quickassem/

# This produces a hasty, don't really care about the accuracy velvet assembly
%.contigs.fa: 
	$(eval STEM=$(subst .contigs.fa,,$@))
	$(eval SCRUB=$(subst .contigs.fa,.nophi,$@))
	$(eval ASSEMDIR=$(STEM).quickassem)
	$(eval R1=$(STEM)$(SUFFIX))
	echo R1 $(R1)
	head -n $(LINES) $(R1) | bowtie2 -x ~/Phi-mut --un $(SCRUB) -  > /dev/null 2> $(SCRUB).err
	velveth $(ASSEMDIR) $(KMER) -fastq $(SCRUB) 
	velvetg $(ASSEMDIR) -exp_cov 20 -cov_cutoff 10 -min_contig_lgth $(MINCONTIGLENGTH)
	cp $(ASSEMDIR)/contigs.fa $(ASSEMDIR)/$(STEM).contigs.fa
	cp $(ASSEMDIR)/contigs.fa $(STEM).contigs.fa
	rm $(ASSEMDIR)/Sequences
	rm $(ASSEMDIR)/Roadmaps
	rm $(ASSEMDIR)/Graph2
	rm $(ASSEMDIR)/LastGraph
	rm $(ASSEMDIR)/PreGraph

references/%.contigs.fa.ebwt.1: %.contigs.fa
	$(eval STEM=$(subst references/,,$(subst .contigs.fa.ebwt.1,,$@)))
	-mkdir references
#  Do not bail if contigs.fa is empty!
	-bowtie-build $(STEM).contigs.fa references/$(STEM).contigs.fa 
	

# This produces an overall assessment of how many reads align to the assembly by bowtie 
%.all.bow3: references/%.contigs.fa.ebwt.1  %_T.R1.fastq %_T.R2.fastq
	$(eval STEM=$(subst .all.bow3,,$@))
	$(eval ASSEMDIR=references)
	$(eval REF=$(ASSEMDIR)/$(STEM).contigs.fa)
	$(eval R1T=$(STEM)_T.R1.fastq)
	$(eval R2T=$(STEM)_T.R2.fastq)
	-cat $(R1T) $(R2T) | bowtie -p $(THREADS)  --best -M 1 -v $(V) $(TYPE) --suppress 1,2,3,6,7 $(REF)  - > $@ 2> $(STEM).all.out

# This produces a paired bowtie alignment
%.inw.bow3: references/%.contigs.fa.ebwt.1 %_T.R1.fastq %_T.R2.fastq
	$(eval STEM=$(subst .inw.bow3,,$@))
	$(eval ASSEMDIR=references)
	$(eval REF=$(ASSEMDIR)/$(STEM).contigs.fa)
	$(eval R1T=$(STEM)_T.R1.fastq)
	$(eval R2T=$(STEM)_T.R2.fastq)
	-bowtie -p $(THREADS) -X 10000 --best -M 1 -v $(V) $(TYPE) --suppress 1,2,3,6,7 $(REF) --fr -1 $(R1T) -2 $(R2T) > $@  2> $(STEM).inw.out  # this in IN

# This produces the other paired bowtie alignment
%.out.bow3:  references/%.contigs.fa.ebwt.1 %_T.R1.fastq %_T.R2.fastq
	$(eval STEM=$(subst .out.bow3,,$@))
	$(eval ASSEMDIR=references)
	$(eval REF=$(ASSEMDIR)/$(STEM).contigs.fa)
	$(eval R1T=$(STEM)_T.R1.fastq)
	$(eval R2T=$(STEM)_T.R2.fastq)
	-bowtie -p $(THREADS) -X 10000 --best -M 1 -v $(V) $(TYPE) --suppress 1,2,3,6,7 $(REF) --rf -1 $(R1T) -2 $(R2T) > $@ 2> $(STEM).out.out   # this is OUT

# This target invokes the dependencies, aborting with an error at the first one that fails
#  -------------
## check:       run dependences
check:
	bowtie -h 
	bowtie2 -h
	velveth
	plothist.py -h
	mappit-summarize.py

# This is a fake dependency 
%.out: %.bow3
	touch $@

# This generates insert size distribution from bowtie output using a perl one-line expression
%.inw.seq: %.inw.bow3
	cat $^ | perl -nle '$$i+=1; @fo = @f; @f=split;  if($$i%2 ==0) {print $$f[0] + length($$f[1]) -  $$fo[0];}'  > $@  # take differences between sucessive lines

%.out.seq: %.out.bow3
	cat $^ | perl -nle '$$i+=1; @fo = @f; @f=split;  if($$i%2 ==0) {print $$f[0] + length($$f[1]) -  $$fo[0];}'  > $@  # take differences between successive lines

%.hist: %.seq
	sort -n $^ | uniq -c | awk '{print $$2 "\t" $$1}' > $@  # awk cleans up histogram

# This plots insert size distribution
%.inw.png: %.inw.hist
	$(eval STEM=$(subst .inw.png,,$@))
	plothist.py --file $^  --x1 0 --x2 600   --out $@  --title "Inward-facing reads in $(STEM)"

%.out.png: %.out.hist
	$(eval STEM=$(subst .out.png,,$@))
	plothist.py --file $^  --x1 0 --x2 10000 --out $@  --title "Outward-facing reads in $(STEM)"

%.fastq.15 : %.fastq
	countkmer15.sh $^

%.fastq.21 : %.fastq
	countkmer21.sh $^

%.lens : %.fastq
	perl -nle 'print length($$_) if $$i % 4 == 1; $$i++;' $^ | sortme.pl > $@

%.15.5.png : %.15
	plotkmerspectrum.py -w png $^ -g 5 

%.21.5.png : %.21
	plotkmerspectrum.py -w png $^ -g 5 

%.scrubbed.fastq: %.fastq
	autoskewer.py $^

# This parses bowtie standard error and plots insert size distribution graphs
# Since mappit-summarize goes through all of the summary files in the directory,
# we don't need separate HTML files for each library.
Summary.html: $(OUTS) $(HISTS) $(PNGS) $(KMERPNG)
	mappit-summarize.py $> > Summary.html
