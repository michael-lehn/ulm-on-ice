# Build the tutorial with a single `make`.
#
# LaTeX writes the table of contents, cross-references and PDF bookmarks to
# auxiliary files and reads them back on the next run. The recipe therefore
# reruns LuaLaTeX until those files stop changing, which is when every link
# and page number in the PDF is correct.

MAIN     := ulm-on-ice-tutorial
LATEX    := lualatex
FLAGS    := -interaction=nonstopmode -halt-on-error -file-line-error
MAXRUNS  := 6
CHAPTERS := $(wildcard chapters/*.tex)
LISTINGS := $(wildcard output/*.txt figures/*.pdf ../0*/*.sv ../0*/*.cpp ../0*/Makefile)
SOURCES  := $(MAIN).tex preamble.tex $(CHAPTERS) $(LISTINGS)
STATE    := $(MAIN).aux $(MAIN).toc $(MAIN).out

.PHONY: all clean distclean
.DELETE_ON_ERROR:

all: $(MAIN).pdf

$(MAIN).pdf: $(SOURCES) Makefile
	@run=1; before=none; \
	while :; do \
	    echo "$(LATEX): run $$run"; \
	    if ! $(LATEX) $(FLAGS) $(MAIN).tex </dev/null >/dev/null; then \
	        echo "$(LATEX) failed; errors from $(MAIN).log:" >&2; \
	        grep -E -A4 '^(! |[^ ]+:[0-9]+: )' $(MAIN).log >&2; \
	        exit 1; \
	    fi; \
	    after=$$(cat $(STATE) | cksum); \
	    if [ "$$after" = "$$before" ]; then break; fi; \
	    if [ $$run -ge $(MAXRUNS) ]; then \
	        echo "cross-references did not settle after $(MAXRUNS) runs" >&2; \
	        exit 1; \
	    fi; \
	    before=$$after; run=$$((run + 1)); \
	done; \
	grep -E 'LaTeX Warning|Package .* Warning|Overfull' $(MAIN).log || true

clean:
	rm -f $(MAIN).aux $(MAIN).log $(MAIN).out $(MAIN).toc

distclean: clean
	rm -f $(MAIN).pdf
