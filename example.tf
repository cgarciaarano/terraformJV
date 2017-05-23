data "aws_availability_zones" "available" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}
resource "aws_vpc" "example" {
    cidr_block = "10.8.0.0/20"
    enable_dns_hostnames = true
    tags {
        Name = "exampleJuanvi"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.example.id}"
}

resource "aws_subnet" "test01" {
    vpc_id            = "${aws_vpc.example.id}"
    availability_zone = "${var.region}b"
    cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, 0)}"
    map_public_ip_on_launch = true
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "test02" {
    vpc_id            = "${aws_vpc.example.id}"
    availability_zone = "${var.region}b"
    cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, 1)}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "test01-rds" {
    vpc_id            = "${aws_vpc.example.id}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, 2)}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "test02-rds" {
    vpc_id            = "${aws_vpc.example.id}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, 3)}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "test03-rds" {
    vpc_id            = "${aws_vpc.example.id}"
    availability_zone = "${data.aws_availability_zones.available.names[2]}"
    cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, 4)}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = "${aws_instance.example01.id}"
  allocation_id = "${aws_eip.ip.id}"

}

resource "aws_instance" "example01" {
    ami           = "ami-ed82e39e"
    instance_type = "t2.micro"
    subnet_id     = "${aws_subnet.test01.id}"
    tags {
        Name = "TerraformTestProvision01Juanvi"
    }
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_instance" "example02" {
    ami           = "ami-ed82e39e"
    instance_type = "t2.micro"
    subnet_id     = "${aws_subnet.test02.id}"
    tags {
        Name = "TerraformTestProvision02Juanvi"
    }
}

resource "aws_eip" "ip" {
    instance = "${aws_instance.example01.id}"
    vpc = true
}

resource "aws_security_group" "internal_inbound" {
    name = "internal_inbound"
    description = "Allow access to apps on internal subnets"
    vpc_id = "${aws_vpc.example.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${cidrsubnet(aws_vpc.example.cidr_block, 4, 0)}", "${cidrsubnet(aws_vpc.example.cidr_block, 4, 1)}"]
    }
    tags {
        Name = "internal_inbound"
    }
}

resource "aws_security_group" "internal_inbound_mysql" {
    name = "internal_inbound_mysql"
    description = "Allow access to apps on internal subnets"
    vpc_id = "${aws_vpc.example.id}"

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["${cidrsubnet(aws_vpc.example.cidr_block, 4, 1)}", "${cidrsubnet(aws_vpc.example.cidr_block, 4, 2)}"]
    }
    tags {
        Name = "internal_inbound_mysql"
    }
}

resource "aws_db_instance" "default" {
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6"
    instance_class = "db.t1.micro"
    name = "example_db01"
    username = "example"
    password = "logtrustisforporn!"
    vpc_security_group_ids = ["${aws_security_group.internal_inbound_mysql.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.example.id}"
}

resource "aws_db_subnet_group" "example" {
    name = "mainjuanvi"
    description = "Our subnets"
    subnet_ids = ["${aws_subnet.test01-rds.id}", "${aws_subnet.test02-rds.id}", "${aws_subnet.test03-rds.id}"]
}
output "ip" {
  value = "${ip}"
}
