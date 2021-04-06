OZC = ozc
OZENGINE = ozengine

DBPATH= database.txt
NOGUI= "" # set this variable to --nogui if you don't want the GUI

SRC=$(wildcard *.oz)
OBJ=$(SRC:.oz=.ozf)

OZFLAGS = --nowarnunused

all: $(OBJ)

run: all
	@echo RUN Main.ozf
	@$(OZENGINE) Main.ozf --db $(DBPATH) $(NOGUI)

%.ozf: %.oz
	@echo OZC $@
	@$(OZC) $(OZFLAGS) -c $< -o $@

.PHONY: clean

clean:
	@echo rm $(OBJ)
	@rm -rf $(OBJ)
