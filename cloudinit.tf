terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = ""
  cloud_id  = ""
  folder_id = ""
}

#VPC
resource "yandex_vpc_network" "web-net" {
  name = "web-net"
}

resource "yandex_vpc_subnet" "web-net-a" {
  name           = "web-net-a"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.web-net.id}"
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_vpc_subnet" "web-net-b" {
  name           = "web-net-b"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.web-net.id}"
  v4_cidr_blocks = ["10.2.0.0/24"]
}


#VM`s
resource "yandex_compute_instance" "web1" {
  name        = "web1"
  platform_id = "standard-v3"
  hostname    = "web1.company.prof"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    core_fraction = 50
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = "fd8i8fljrbbcclckhlm9"
      size = 15
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web-net-a.id
    nat       = true
  }

  metadata = {
    ssh-keys = "altlinux:${file("~/.ssh/web1.pub")}"
  }
}

resource "yandex_compute_instance" "web2" {
  name        = "web2"
  platform_id = "standard-v3"
  hostname    = "web2.company.prof"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    core_fraction = 50
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = "fd8i8fljrbbcclckhlm9"
      size = 15
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.web-net-b.id
    nat       = true
  }

  metadata = {
    ssh-keys = "altlinux:${file("~/.ssh/web2.pub")}"
  }
} 


#LB
resource "yandex_lb_network_load_balancer" "my-nlb" {
  name = "my-nlb"

  listener {
    name = "my-listener80"
    port = 80
    protocol = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "my-listener443"
    port = 443
    protocol = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.my-target.id}"

    #tcp instead of http due to 301 redirect code to https (nlb healtcheck only accepts 200)
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 80
      }
    }
  }
}

#Target group
resource "yandex_lb_target_group" "my-target" {
  name = "my-target"

  target {
    subnet_id = "${yandex_vpc_subnet.web-net-a.id}"
    address = "${yandex_compute_instance.web1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.web-net-b.id}"
    address = "${yandex_compute_instance.web2.network_interface.0.ip_address}"
  }
}
