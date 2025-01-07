prepare:
	echo "***Running prepare***"
	sudo bash prepare.sh
	packer init .
clean:
	echo "***Running cleanup***"
	rm -rf output
build:
	echo "***Running packer build***"
	packer build --force ubuntu.qemu.pkr.hcl
fmt:
	echo "***Running packer fmt***"
	packer fmt ubuntu.qemu.pkr.hcl
validate:
	echo "***Running packer validation***"
	packer validate ubuntu.qemu.pkr.hcl
docker:
	echo "**** Building Docker image **"
	docker buildx --no-cache -f Dockerfile-kubevirt -t vst-name/vm-images/gitlab-runner:latest
full:
	make prepare
	make build
	make docker
	make clean