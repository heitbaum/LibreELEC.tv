all: release

system:
	./scripts/image

release:
	./scripts/image release

image:
	./scripts/image mkimage

noobs:
	./scripts/image noobs

clean:
	./scripts/makefile_helper --clean

cleanx86:
	rm -rf build.LibreELEC-Generic.x86_64-10.0-devel/* build.LibreELEC-Generic.x86_64-10.0-devel/.stamps
	rm -rf build.LibreELEC-AMLG12.aarch64-10.0-devel/* build.LibreELEC-AMLG12.aarch64-10.0-devel/.stamps

distclean:
	./scripts/makefile_helper --distclean

src-pkg:
	tar cvJf sources.tar.xz sources
