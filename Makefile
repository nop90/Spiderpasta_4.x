#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
TARGET 		:=  code.bin
BUILD		:=	build
ARMIPS    	:=  armips

all: clean 
	mkdir $(BUILD)
	armips source/arm9_code.s
	armips source/arm9hax.s
	armips source/arm11hax.s
	cp $(BUILD)/arm11hax.bin $(TARGET)

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD)
