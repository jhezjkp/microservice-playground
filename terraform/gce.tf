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
        ssh-keys = "root:${file("~/.ssh/id_rsa.pub")}"
    }

    // set up docker
    metadata_startup_script = "curl -fsSL https://test.docker.com/ | sh"

    // 输出ip等到本地
    provisioner "local-exec" {
        command = "echo ${self.network_interface.0.access_config.0.assigned_nat_ip} ======"
    }
    provisioner "local-exec" {
        // below command valid for os x
        command = "sed -i '' '/^${self.network_interface.0.access_config.0.assigned_nat_ip}/d' ~/.ssh/known_hosts"
    }
    // 更新dnspod记录
    provisioner "local-exec" {
        command = "curl -X POST https://dnsapi.cn/Record.Create -d 'login_token=${var.dnspod_login_token}&format=json&domain_id=${var.dnspod_domain_id}&sub_domain=${lookup(var.instance_names, count.index)}&record_type=A&record_line=默认&value=${self.network_interface.0.access_config.0.assigned_nat_ip}'"
    }
}

resource "google_compute_firewall" "default" {
    name = "terraform-rule"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["8000", "8500"]
    }

}

output "ip" {
    //value = "${join(", ", google_compute_instance.gce.*.name)}"
    // terrorform bug cause outputs unnormal for the bellow line
    value = "${formatlist("%v:%v,", google_compute_instance.gce.*.name, google_compute_instance.gce.*.network_interface.0.access_config.0.assigned_nat_ip)}"
}
