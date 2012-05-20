export PROJECT_NAME = DEDCPU-16
export AUTHOR       = Luis Panadero Guardeño
export DESCRIPTION  = D Emulator for DCPU-16
export VERSION      = 0.4
export LICENSE      = BSD

ROOT_SOURCE_DIR     = ./src/
SRC_DIR             = $(ROOT_SOURCE_DIR)

# include some commands
include command.Make

all: ddis bconv

# .PHONY : doc
# .PHONY : ddoc
.PHONY : clean

############# Compiling ################

$(BUILD_PATH)$(PATH_SEP)microcode.o: $(SRC_DIR)dcpu/microcode.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)cpu.o: $(SRC_DIR)dcpu/cpu.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)hardware.o: $(SRC_DIR)dcpu/hardware.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)machine.o: $(SRC_DIR)dcpu/machine.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)clock.o: $(SRC_DIR)dcpu/clock.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)ram_io.o: $(SRC_DIR)dcpu/ram_io.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)disassembler.o: $(SRC_DIR)dcpu/disassembler.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

$(BUILD_PATH)$(PATH_SEP)dedcpu.o: $(SRC_DIR)dedcpu.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

dedcpu: $(BUILD_PATH)$(PATH_SEP)dedcpu.o $(BUILD_PATH)$(PATH_SEP)dedcpu.o $(BUILD_PATH)$(PATH_SEP)machine.o $(BUILD_PATH)$(PATH_SEP)cpu.o $(BUILD_PATH)$(PATH_SEP)microcode.o $(BUILD_PATH)$(PATH_SEP)hardware.o $(BUILD_PATH)$(PATH_SEP)clock.o $(BUILD_PATH)$(PATH_SEP)ram_io.o
	@echo "$(niceMsgBeg2)Linking $< $@$(niceMsgEnd)"
	$(DC) $^ $(OUTPUT)$@ $(DCFLAGS_LINK)
	@echo "------------------ $(niceMsgBeg1)Creating $@ executable done$(niceMsgEnd)"

$(BUILD_PATH)$(PATH_SEP)ddis.o: $(SRC_DIR)ddis.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

ddis: $(BUILD_PATH)$(PATH_SEP)ddis.o $(BUILD_PATH)$(PATH_SEP)disassembler.o $(BUILD_PATH)$(PATH_SEP)microcode.o $(BUILD_PATH)$(PATH_SEP)ram_io.o
	@echo "$(niceMsgBeg2)Linking $< $@$(niceMsgEnd)"
	$(DC) $^ $(OUTPUT)$@ $(DCFLAGS_LINK)
	@echo "------------------ $(niceMsgBeg1)Creating $@ executable done$(niceMsgEnd)"

$(BUILD_PATH)$(PATH_SEP)bconv.o: $(SRC_DIR)bconv.d
	@$(MKDIR) build
	@echo "$(niceMsgBeg2)Compiling $< $@$(niceMsgEnd)"
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) -c $< $(OUTPUT)$@

bconv: $(BUILD_PATH)$(PATH_SEP)bconv.o $(BUILD_PATH)$(PATH_SEP)ram_io.o
	@echo "$(niceMsgBeg2)Linking $< $@$(niceMsgEnd)"
	$(DC) $^ $(OUTPUT)$@ $(DCFLAGS_LINK)
	@echo "------------------ $(niceMsgBeg1)Creating $@ executable done$(niceMsgEnd)"

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
	@echo "------------------ $(niceMsgBeg1)cleaning $^ done$(niceMsgEnd)"

clean-objects:
	$(RM) $(BUILD_PATH)$(PATH_SEP)*.o

clean-executable:
	$(RM) ddis
	$(RM) bconv
	$(RM) dedcpu

clean-doc:
	$(RM) $(DOCUMENTATIONS)
	$(RM) $(DOC_PATH)

clean-ddoc:
	$(RM) $(DDOCFILES)
	$(RM) $(DOC_PATH)$(PATH_SEP)index.html
	$(RM) $(DDOC_PATH)$(PATH_SEP)*.html
