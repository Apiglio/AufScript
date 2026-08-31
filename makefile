
LRS_OUTPUT = icons.lrs
RESOURCES = resource/icon/button_start.bmp \
            resource/icon/button_stop.bmp \
            resource/icon/button_pause.bmp \
            resource/icon/button_resume.bmp \
            resource/icon/button_load.bmp \
            resource/icon/button_save.bmp

-include makefile.local
# for windows user, add lazres path to %PATH%
# for linux / mac user, create makefile.local to assign custom LAZRES
LAZRES ?= lazres.exe

all: $(LRS_OUTPUT)

$(LRS_OUTPUT): $(RESOURCES)
	$(LAZRES) $(LRS_OUTPUT) $(RESOURCES)
	@echo "Resource file $(LRS_OUTPUT) has generated"

clean:
	-rm -f $(LRS_OUTPUT) 2>/dev/null || del /f /q $(LRS_OUTPUT) 2>nul
