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

    //metadata_startup_script = "echo hello > /abc.txt"
}
