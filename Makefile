OZC = ozc
OZENGINE = ozengine

DBPATH = databaseTest.txt
NOGUI = "" # set this variable to --nogui if you don't want the GUI

SRC=$(wildcard *.oz)
OBJ=$(SRC:.oz=.ozf)

OZFLAGS = --nowarnunused

all: $(OBJ)

run: all
	@echo RUN Main.ozf
	@$(OZENGINE) Main.ozf --db $(DBPATH) $(NOGUI)

ext: all
	@echo RUN Extensions.ozf
	@$(OZENGINE) Extensions.ozf --db $(DBPATH) $(NOGUI)

%.ozf: %.oz
	@echo OZC $@
	@$(OZC) $(OZFLAGS) -c $< -o $@

ingi: Main.oz Rapport.pdf
	@zip Projet Main.oz Extensions.oz Rapport.pdf

%.pdf:
	@echo "Pas encore fait..." > $@

.PHONY: clean sclean

clean:
	@echo rm $(OBJ)
	@rm -rf $(OBJ)

sclean: clean
	@rm *.zip
