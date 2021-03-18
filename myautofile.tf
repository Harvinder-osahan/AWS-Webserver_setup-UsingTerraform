provider "aws" {
  region = "ap-south-1"
  profile = "Harry"
}

resource "aws_instance" "tfin" {
  ami    = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name = "MyNewKey"
  security_groups = [ "launch-wizard-2" ]
  
  connection {
    type   = "ssh"
    user   = "ec2-user"
    private_key = file("MyNewKey.pem")
    host      = aws_instance.tfin.public_ip   
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
     ]
  }
 
  tags = {
    Name = "AUTOMATED"
  }
}

resource "aws_ebs_volume" "pd" {
depends_on = [
    aws_instance.tfin,
  ]


  availability_zone = aws_instance.tfin.availability_zone
  size              = 1
  tags =  {
    Name = "myebspd"
  }
}


resource "aws_volume_attachment" "pd_att" {
depends_on = [
    aws_ebs_volume.pd,
  ]


  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.pd.id}"
  instance_id = "${aws_instance.tfin.id}"
  force_detach = true
}


 

resource "null_resource" "NL"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.tfin.public_ip} > publicip.txt"
  	}
} 


resource "null_resource" "setremote"  {

depends_on = [
    aws_volume_attachment.pd_att,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("MyNewKey.pem")
    host     = aws_instance.tfin.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh   /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Harvinder-osahan/TestingTeraform.git   /var/www/html/"
    ]
  }
}



resource "null_resource" "baseosi"  {

depends_on = [
    null_resource.setremote,
  ]

	provisioner "local-exec" {
	    command = "start chrome  192.168.0.109:777/"
  	}
}


output "myos_ip" {
  value = aws_instance.tfin.public_ip
}