# swc: libswc/local.mk

dir := libswc

LIBSWC_LINK := libswc.so
LIBSWC_SO   := $(LIBSWC_LINK).$(VERSION_MAJOR)
LIBSWC_LIB  := $(LIBSWC_SO).$(VERSION_MINOR)

ifneq ($(ENABLE_STATIC), 0)
$(dir)_TARGETS += $(dir)/libswc.a
endif

ifneq ($(ENABLE_SHARED), 0)
$(dir)_TARGETS +=                   \
    $(dir)/$(LIBSWC_LIB)            \
    $(dir)/$(LIBSWC_SO)             \
    $(dir)/$(LIBSWC_LINK)
endif

$(dir)_PACKAGES := libdrm libevdev pixman-1 wayland-server wld xkbcommon
$(dir)_CFLAGS += -Iprotocol

SWC_SOURCES =                       \
    launch/protocol.c               \
    libswc/bindings.c               \
    libswc/compositor.c             \
    libswc/cursor_plane.c           \
    libswc/data.c                   \
    libswc/data_device.c            \
    libswc/data_device_manager.c    \
    libswc/drm.c                    \
    libswc/input.c                  \
    libswc/keyboard.c               \
    libswc/launch.c                 \
    libswc/mode.c                   \
    libswc/output.c                 \
    libswc/panel.c                  \
    libswc/panel_manager.c          \
    libswc/pointer.c                \
    libswc/primary_plane.c          \
    libswc/region.c                 \
    libswc/screen.c                 \
    libswc/seat.c                   \
    libswc/shell.c                  \
    libswc/shell_surface.c          \
    libswc/shm.c                    \
    libswc/subcompositor.c          \
    libswc/subsurface.c             \
    libswc/surface.c                \
    libswc/swc.c                    \
    libswc/util.c                   \
    libswc/view.c                   \
    libswc/wayland_buffer.c         \
    libswc/window.c                 \
    libswc/xdg_popup.c              \
    libswc/xdg_shell.c              \
    libswc/xdg_surface.c            \
    protocol/swc-protocol.c         \
    protocol/wayland-drm-protocol.c \
    protocol/xdg-shell-unstable-v5-protocol.c

ifeq ($(ENABLE_LIBINPUT),1)
$(dir)_CFLAGS += -DENABLE_LIBINPUT
$(dir)_PACKAGES += libinput libudev
else
SWC_SOURCES += libswc/evdev_device.c
endif

ifeq ($(ENABLE_XWAYLAND),1)
$(dir)_CFLAGS += -DENABLE_XWAYLAND
$(dir)_PACKAGES += xcb xcb-composite xcb-ewmh xcb-icccm

SWC_SOURCES +=                      \
    libswc/xserver.c                \
    libswc/xwm.c
endif

SWC_STATIC_OBJECTS = $(SWC_SOURCES:%.c=%.o)
SWC_SHARED_OBJECTS = $(SWC_SOURCES:%.c=%.lo)

# Explicitly state dependencies on generated files
objects = $(foreach obj,$(1),$(dir)/$(obj).o $(dir)/$(obj).lo)
$(call objects,compositor panel_manager panel screen): protocol/swc-server-protocol.h
$(call objects,drm drm_buffer): protocol/wayland-drm-server-protocol.h
$(call objects,xdg_shell xdg_surface xdg_popup): protocol/xdg-shell-unstable-v5-server-protocol.h
$(call objects,pointer): cursor/cursor_data.h

$(dir)/libswc-internal.o: $(SWC_STATIC_OBJECTS)
	$(link) -nostdlib -r

$(dir)/libswc.o: $(dir)/libswc-internal.o
	$(Q_OBJCOPY)$(OBJCOPY) --localize-hidden $< $@

$(dir)/libswc.a: $(dir)/libswc.o
	$(Q_AR)$(AR) cru $@ $^

$(dir)/$(LIBSWC_LIB): $(SWC_SHARED_OBJECTS)
	$(link) -shared -Wl,-soname,$(LIBSWC_SO) -Wl,-no-undefined $(libswc_PACKAGE_LIBS)

$(dir)/$(LIBSWC_SO): $(dir)/$(LIBSWC_LIB)
	$(Q_SYM)ln -sf $(notdir $<) $@

$(dir)/$(LIBSWC_LINK): $(dir)/$(LIBSWC_SO)
	$(Q_SYM)ln -sf $(notdir $<) $@

.PHONY: install-libswc.a
install-libswc.a: $(dir)/libswc.a | $(DESTDIR)$(LIBDIR)
	install -m 644 $< $(DESTDIR)$(LIBDIR)

.PHONY: install-$(LIBSWC_LIB)
install-$(LIBSWC_LIB): $(dir)/$(LIBSWC_LIB) | $(DESTDIR)$(LIBDIR)
	install -m 755 $< $(DESTDIR)$(LIBDIR)

.PHONY: install-$(LIBSWC_SO) install-$(LIBSWC_LINK)
install-$(LIBSWC_SO) install-$(LIBSWC_LINK): install-$(LIBSWC_LIB)
	ln -sf $(LIBSWC_LIB) $(DESTDIR)$(LIBDIR)/${@:install-%=%}

install-$(dir): $($(dir)_TARGETS:$(dir)/%=install-%) | $(DESTDIR)$(INCLUDEDIR)
	install -m 644 libswc/swc.h $(DESTDIR)$(INCLUDEDIR)

CLEAN_FILES += $(SWC_SHARED_OBJECTS) $(SWC_STATIC_OBJECTS)

include common.mk

