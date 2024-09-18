VERSION=$(shell git describe --abbrev=0 --tags)

all: clean
	@mkdir build
	@go build -o build/shikigrid cmd/shikigrid/*.go
	@ls -la build/shikigrid

install:
	@cp build/shikigrid /usr/local/bin/
	@mkdir -p /etc/systemd/system/
	@cp shikigrid.service /etc/systemd/system/
	@mkdir -p /etc/shikigrid/
	@cp env.example /etc/shikigrid/shikigrid.conf
	@chmod 644 /etc/systemd/system/shikigrid.service
	@systemctl daemon-reload
	@systemctl enable shikigrid.service

clean:
	@rm -rf build

restart:
	@service shikigrid restart

release_files: clean
	@mkdir build
	@echo building for linux/amd64 ...
	@GOARM=6 GOARCH=amd64 GOOS=linux go build -o build/shikigrid cmd/shikigrid/*.go
	@zip -j "build/shikigrid_linux_amd64_$(VERSION).zip" build/shikigrid > /dev/null
	@rm -rf build/shikigrid
	@echo building for linux/armv6l ...
	@GOARM=6 GOARCH=arm GOOS=linux go build -o build/shikigrid cmd/shikigrid/*.go
	@zip -j "build/shikigrid_linux_armv6l_$(VERSION).zip" build/shikigrid > /dev/null
	@rm -rf build/shikigrid
	@openssl dgst -sha256 "build/shikigrid_linux_amd64_$(VERSION).zip" > "build/shikigrid-hashes.sha256"
	@openssl dgst -sha256 "build/shikigrid_linux_armv6l_$(VERSION).zip" >> "build/shikigrid-hashes.sha256"
	@ls -la build
