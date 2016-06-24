provider "google" {
    credentials = "${file("account.json")}"
    project = "primordial-mile-134402"
    region = "us-central1"
}

resource "google_compute_instance" "venus" {
    name = "venus"
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
        command = "echo ${google_compute_instance.venus.network_interface.0.access_config.0.assigned_nat_ip} ======"
    }
    provisioner "local-exec" {
        command = "echo ${google_compute_instance.venus.network_interface.0.access_config.0.assigned_nat_ip} > ip.txt"
    }
    provisioner "local-exec" {
        // below command valid for os x
        command = "sed -i '' '/^${google_compute_instance.venus.network_interface.0.access_config.0.assigned_nat_ip}/d' ~/.ssh/known_hosts"
    }
    // 更新dnspod记录
    provisioner "local-exec" {
        command = "curl -X POST https://dnsapi.cn/Record.Create -d 'login_token=${var.dnspod_login_token}&format=json&domain_id=${var.dnspod_domain_id}&sub_domain=${google_compute_instance.venus.name}&record_type=A&record_line=默认&value=${google_compute_instance.venus.network_interface.0.access_config.0.assigned_nat_ip}'"
    }
}

// 输出ip
output "ip" {
    value = "${google_compute_instance.venus.network_interface.0.access_config.0.assigned_nat_ip}"
}
