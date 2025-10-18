# was from task 2

# output "backend_public_ip" { value = aws_instance.app.public_ip }
# output "ssh_user"          { value = "ubuntu" }


# task 6
output "ssh_user" { value = "ubuntu" }
output "frontend_public_ip" { value = aws_instance.frontend.public_ip }
output "backend_public_ip" { value = aws_instance.backend.public_ip }
output "db_private_ip" { value = aws_instance.db.private_ip }