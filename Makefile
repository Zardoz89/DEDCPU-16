export PROJECT_NAME = DEDCPU-16
export AUTHOR       = Luis Panadero Guardeño
export DESCRIPTION  = D Emulator for DCPU-16
export VERSION      = 0.2
export LICENSE      = BSD

################## Source Files and other stuff #######################
# Executable files
EXE_NAME     =ddis dedcpu
# Commun source code files
SOURCES      =disassembler.d
# Target source code files
SOURCES_MAIN =ddis.d dedcpu.d
# DDoc definition files
#DDOCFILES    =cutedoc.ddoc

# include some command
include command.Make

OBJECTS       =$(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o, $(SOURCES))
OBJECTS_MAIN  =$(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o, $(SOURCES_MAIN))

DOCUMENTATIONS      = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
DDOCUMENTATIONS     = $(patsubst %.d,$(DDOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))

all: $(EXE_NAME)

.PHONY : doc
.PHONY : ddoc
.PHONY : clean

############# Compiling ################

# Do executable files
# TODO FIX HERE
$(EXE_NAME): $(OBJECTS_MAIN) $(OBJECTS)
	$(DC) $< $(OBJECTS) $(OUTPUT)$@
	@echo ------------------ creating $@ executable done

# Do object files
$(OBJECTS): $(SOURCES)
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

# Do main objects files
$(OBJECTS_MAIN): $(SOURCES_MAIN)
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.


############# Documentation ################
doc: $(DOCUMENTATIONS)

#ddoc:
#	$(DC) $(DDOC_FLAGS) index.d $(DF)$(DOC_PATH)$(PATH_SEP)index.html

# Generate Documentation
$(DOC_PATH)$(PATH_SEP)%.html : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ)  $< $(DF)$@

# Generate ddoc Documentation
#$(DDOC_PATH)$(PATH_SEP)%.html : %.d
#	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@

############# CLEAN #############
clean: clean-objects clean-executable clean-doc clean-ddoc
	@echo ------------------ cleaning $^ done

clean-objects:
	$(RM) $(OBJECTS)
	$(RM) $(OBJECTS_MAIN)

clean-executable:
	$(RM) $(EXE_NAME)

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)

clean-ddoc:
	$(RM) $(DDOCFILES)
	$(RM) $(DOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOC_PATH)$(PATH_SEP)*.html