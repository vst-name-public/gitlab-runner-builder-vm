packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "gitlab-runner"
}

variable "ubuntu_version" {
  type        = string
  default     = "noble"
  description = "Ubuntu codename version (i.e. 20.04 is focal, 22.04 is for jammy, and 24.04 is noble)"
}

variable "qemu_accelerator" {
  type        = string
  default     = "kvm"
  description = "Qemu accelerator to use. On Linux use kvm and macOS use hvf."
}

source "qemu" "ubuntu" {
  iso_checksum              = "file:https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/SHA256SUMS"
  iso_url                   = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-amd64.img"
  vm_name                   = var.vm_name
  cd_files                  = ["./cloud-init/*"]
  cd_label                  = "cidata"
  output_directory          = "output"
  format                    = "qcow2"
  headless                  = false
  machine_type              = "q35"
  accelerator               = var.qemu_accelerator
  boot_wait                 = "30s"
  disk_compression          = true
  disk_image                = true
  cpus                      = 2
  memory                    = 4096
  disk_size                 = 10240
  shutdown_command          = "sync && sleep 15 && echo 'packer' | sudo -S shutdown -P now"
  ssh_clear_authorized_keys = true
  ssh_username              = "gitlab-runner"
  ssh_password              = "packer"
  ssh_port                  = 22
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "./scripts/install.sh",
      "./scripts/cleanup.sh"
    ]
  }
}
