provider "google" {
    credentials = "${file("account.json")}"
    project = "primordial-mile-134402"
    region = "us-central1"
}

variable "instance_names" {
    default = {
        "0" = "venus"
        "1" = "mercury"
        "2" = "earth"
        "3" = "jupiter"
        "4" = "mars"
    }
}

variable "instance_count" {
    default = 4
}

variable "instance_user" {
    default = "vivia"
}

resource "google_compute_instance" "gce" {
    count = "${var.instance_count}"
    name = "${lookup(var.instance_names, count.index)}"
    machine_type = "n1-standard-1"
    zone = "us-central1-a"

    tags = ["http-server", "https-server"]

    disk {
        image = "debian-8-jessie-v20160606"
    }

    disk {
        type = "local-ssd"
        scratch = true
    }

    network_interface {
        network = "default"
        access_config {
        }
    }

    // ssh keys
    metadata {
        ssh-keys = "vivia:${file("~/.ssh/id_rsa.pub")}"
    }

    // set up docker
    // metadata_startup_script = "curl -fsSL https://test.docker.com/ | sh"

    provisioner "remote-exec" {
        inline = [
        // install docker(beta release)
        "curl -fsSL https://test.docker.com/ | sh",
        // add current user to docker group
        "sudo usermod -aG docker `whoami`",
        // install zsh
        "sudo apt-get install -y zsh",
        // configure behavior hangs, comment for now
        // configure zsh with oh-my-zsh
        //"sudo sh -c \"$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)\"",
        // change to zsh
        //"sudo chsh -s /bin/zsh `whoami`",
        ]
        connection {
            user = "${var.instance_user}"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
    }
    provisioner "local-exec" {
        // remove ssh fingerprint(valid for os x)
        command = "ssh-keygen -R ${var.dnspod_domain}.vivia.me"
    }
    // 更新dnspod记录
    provisioner "local-exec" {
        command = "curl -X POST https://dnsapi.cn/Record.Ddns -d 'login_token=${var.dnspod_login_token}&format=json&domain_id=${var.dnspod_domain_id}&record_id=${lookup(var.dnspod_record_id, self.name)}&record_line=默认&sub_domain=${self.name}&value=${self.network_interface.0.access_config.0.assigned_nat_ip}'"
    }
}

resource "google_compute_firewall" "default" {
    name = "terraform-rule"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["8000-8100", "8500"]
    }

}

output "ip" {
    //value = "${join(", ", google_compute_instance.gce.*.name)}"
    // terrorform bug cause outputs unnormal for the bellow line
    value = "${formatlist("%v:%v,", google_compute_instance.gce.*.name, google_compute_instance.gce.*.network_interface.0.access_config.0.assigned_nat_ip)}"
}
