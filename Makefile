export PROJECT_NAME = DEDCPU-16
export AUTHOR       = Luis Panadero Guardeño
export DESCRIPTION  = D Emulator for DCPU-16
export VERSION      = 0.4
export LICENSE      = BSD

################## Source Files and other stuff #######################
# # Executable files
# EXE_NAME     =ddis
# # Commun source code files
# SOURCES      =dcpu/ram_loader.d
# # Target source code files
# SOURCES_MAIN =ddis.d
# DDoc definition files
#DDOCFILES    =cutedoc.ddoc

# include some command
include command.Make

# EXE_NAME := $(addprefix $(BIN_PATH)$(PATH_SEP), $(EXE_NAME))
# 
# OBJECTS       =$(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o, $(SOURCES))
# OBJECTS_MAIN  =$(patsubst %.d,$(BUILD_PATH)$(PATH_SEP)%.o, $(SOURCES_MAIN))
# 
# DOCUMENTATIONS      = $(patsubst %.d,$(DOC_PATH)$(PATH_SEP)%.html,   $(SOURCES))
# DDOCUMENTATIONS     = $(patsubst %.d,$(DDOC_PATH)$(PATH_SEP)%.html,  $(SOURCES))
# DDOC_FLAGS          = $(foreach macro,$(DDOCFILES), $(DDOC_MACRO)$(macro))

all: ddis

# .PHONY : doc
# .PHONY : ddoc
.PHONY : clean

############# Compiling ################

dcpu/microcode.o: dcpu/microcode.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/cpu.o: dcpu/cpu.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/hardware.o: dcpu/hardware.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/machine.o: dcpu/machine.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/clock.o: dcpu/clock.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/ram_loader.o: dcpu/ram_loader.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

dcpu/disassembler.o: dcpu/disassembler.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

ddis.o: ddis.d
	@echo Compiling $< $@
	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.

ddis: ddis.o dcpu/disassembler.o dcpu/microcode.o dcpu/ram_loader.o
	$(DC) $^ $(OUTPUT)$@
	@echo ------------------ creating $@ executable done

# Do executable files
# $(EXE_NAME): $(OBJECTS_MAIN) $(OBJECTS) dcpu/disassembler.o dcpu/cpu.o
# 	$(DC) $< $(OBJECTS) dcpu/disassembler.o dcpu/cpu.o $(OUTPUT)$@
# 	@echo ------------------ creating $@ executable done
# 
# # Do object files
# $(OBJECTS): $(SOURCES)
# 	@echo Compiling $< $@
# 	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.
# 
# dcpu/cpu.o: dcpu/cpu.d
# 	@echo Compiling $< $@
# 	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.
# 	
# dcpu/disassembler.o: dcpu/disassembler.d
# 	@echo Compiling $< $@
# 	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.
# 	
# # Do main objects files
# $(OBJECTS_MAIN): $(SOURCES_MAIN)
# 	@echo Compiling $< $@
# 	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@ -J.
# 
# 
# ############# Documentation ################
# doc: $(DOCUMENTATIONS)
# 
# #ddoc:
# #	$(DC) $(DDOC_FLAGS) index.d $(DF)$(DOC_PATH)$(PATH_SEP)index.html
# 
# # Generate Documentation
# $(DOC_PATH)$(PATH_SEP)%.html : %.d
# 	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ)  $< $(DF)$@
# 
# # Generate ddoc Documentation
# #$(DDOC_PATH)$(PATH_SEP)%.html : %.d
# #	$(DC) $(DCFLAGS) $(DCFLAGS_LINK) $(DCFLAGS_IMPORT) -c $(NO_OBJ) $(DDOC_FLAGS) $< $(DF)$@

############# CLEAN #############
#  clean-doc clean-ddoc
clean: clean-objects clean-executable
	@echo ------------------ cleaning $^ done

clean-objects:
	$(RM) *.o
	$(RM) dcpu/*.o

clean-executable:
	$(RM) ddis

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)

clean-ddoc:
	$(RM) $(DDOCFILES)
	$(RM) $(DOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOC_PATH)$(PATH_SEP)*.html
