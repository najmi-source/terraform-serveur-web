provider "aws" {
  region  = "us-east-1"
  profile = "terraform-1"
}

# 1. Astuce de Pro : Trouver automatiquement le système d'exploitation le plus récent
data "aws_ssm_parameter" "linux_latest" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# 2. Le Pare-feu (Security Group)
resource "aws_security_group" "pare_feu_web" {
  name        = "serveur-web-sg"
  description = "Autoriser le trafic HTTP entrant pour le site web"

  # Règle d'entrée : Autoriser le monde entier (0.0.0.0/0) à voir notre site web (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Règle de sortie : Autoriser le serveur à se connecter à internet pour télécharger ses logiciels
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 signifie "tous les protocoles"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Le Serveur (EC2) avec l'automatisation
resource "aws_instance" "serveur_app" {
  ami           = data.aws_ssm_parameter.linux_latest.value
  instance_type = "t3.micro"
  
  # On attache le pare-feu au serveur
  vpc_security_group_ids = [aws_security_group.pare_feu_web.id]

  # La magie opère ici : Script bash lancé au premier démarrage (user_data)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Bienvenue sur l'application Full Stack de Mounir !</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Serveur-Web-Automatique"
  }
}

# 4. Afficher l'adresse IP publique à la fin du déploiement
output "adresse_du_site_web" {
  value       = "http://${aws_instance.serveur_app.public_ip}"
  description = "Cliquez sur ce lien pour voir le site web de Mounir"
}