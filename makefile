
LRS_OUTPUT = icons.lrs
RESOURCES = resource/icon/button_start.bmp \
            resource/icon/button_stop.bmp \
            resource/icon/button_pause.bmp \
            resource/icon/button_resume.bmp \
            resource/icon/button_load.bmp \
            resource/icon/button_save.bmp

ifdef OS
	LAZRES ?= C:\lazarus\tools\lazres.exe
else
	LAZRES ?= /Users/apiglio/fpcupdeluxe/lazarus/tools/lazres
endif

all: $(LRS_OUTPUT)

$(LRS_OUTPUT): $(RESOURCES)
	$(LAZRES) $(LRS_OUTPUT) $(RESOURCES)
	@echo "编译成功！已生成 $(LRS_OUTPUT)"

clean:
	-rm -f $(LRS_OUTPUT) 2>/dev/null || del /f /q $(LRS_OUTPUT) 2>nul
