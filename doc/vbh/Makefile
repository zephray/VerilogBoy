TARGET := vbhrm
#PDFLATEX ?= xelatex -shell-escape

DRAFT := 1

REVDEPS += config.tex

include Makefile.include

config.tex:
	@echo '\\newcount\\draft\\draft='"${DRAFT}" > config.tex
